import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:provider/provider.dart';
import 'dart:async' show StreamSubscription, Zone, runZonedGuarded;
import 'package:franchise_mobile_app/core/widgets/global_error_boundary.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';
import 'package:app_links/app_links.dart'; // P2 deep linking foundations

// Shared Core
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;

// Local Providers & Config
import 'package:franchise_mobile_app/features/language/language_provider.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as app_user;
// Note: FranchiseProvider now comes exclusively from shared_core (single source of truth)
import 'package:franchise_mobile_app/core/services/franchise_bind_service.dart';

// Screens
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/complete_profile_dialog.dart';
import 'firebase_options.dart';
import 'package:franchise_mobile_app/features/franchise/franchise_directory_screen.dart';

/// Global navigator key for deep link / QR navigation from anywhere (foundations)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Ingredient Metadata Provider (global for now)
class IngredientMetadataProvider extends ChangeNotifier {
  final Map<String, shared.IngredientMetadata> _ingredients = {};
  bool _isLoaded = false;
  String? _loadedForFranchiseId;

  bool get isLoaded => _isLoaded;
  Map<String, shared.IngredientMetadata> get ingredients => _ingredients;
  String? get loadedForFranchiseId => _loadedForFranchiseId;

  IngredientMetadataProvider() {
    _loadIngredients();
  }

  /// Reload for a bound franchise (call after FranchiseBindService / setFranchiseId).
  Future<void> reloadForFranchise(String franchiseId) async {
    final id = franchiseId.trim();
    if (id.isEmpty || id == 'unknown') {
      _ingredients.clear();
      _loadedForFranchiseId = null;
      _isLoaded = true;
      notifyListeners();
      return;
    }
    await _loadIngredients(franchiseId: id);
  }

  Future<void> _loadIngredients({String? franchiseId}) async {
    try {
      String? fid = franchiseId;
      if (fid == null || fid.isEmpty || fid == 'unknown') {
        try {
          final stored =
              await AppLocalStorage().getString('selectedFranchiseId');
          if (stored != null && stored.isNotEmpty && stored != 'unknown') {
            fid = stored;
          }
        } catch (_) {}
      }
      if (fid == null || fid.isEmpty || fid == 'unknown') {
        _ingredients.clear();
        _loadedForFranchiseId = null;
        _isLoaded = true;
        notifyListeners();
        return;
      }

      final snapshot = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(fid)
          .collection('ingredient_metadata')
          .get();

      _ingredients.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] ?? doc.id;
        _ingredients[id] =
            shared.IngredientMetadata.fromMap({...data, 'id': id});
      }
      _loadedForFranchiseId = fid;
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoaded = true;
      notifyListeners();
    }
  }
}

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    FlutterError.onError = (FlutterErrorDetails details) {
      shared.ErrorLogger.log(
        message: 'FlutterError: ${details.exception}',
        source: 'FlutterError',
        severity: 'fatal',
        stack: details.stack?.toString(),
        contextData: {
          'library': details.library,
          'context': details.context?.toString(),
        },
      );
      FlutterError.presentError(details);
    };

    shared.ErrorLogger.setCustomLogger(({
      required String message,
      String? source,
      String? severity,
      String? stack,
      Map<String, dynamic>? contextData,
    }) {
      // Optional: Crashlytics in release
    });

    _initDeepLinks();

    runApp(
      GlobalErrorBoundary(
        screenName: 'root',
        child: const MyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    shared.ErrorLogger.log(
      message: 'Uncaught async error: $error',
      source: 'Zone',
      severity: 'fatal',
      stack: stack.toString(),
      contextData: {'phase': 'runApp'},
    );
  });
}

/// P2: Initialize app_links for franchise deep links (fhq://f/{id} and https://franchisehq.io/f/{id})
void _initDeepLinks() {
  final appLinks = AppLinks();

  // Cold start (app_links v3+ API)
  appLinks.getInitialLink().then((uri) {
    if (uri != null) _handleDeepLink(uri);
  });

  // Stream (app already running)
  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  }, onError: (e) {
    // ignore for foundations
  });
}

void _handleDeepLink(Uri uri) {
  try {
    final parsed = shared.parseFranchiseQR(uri.toString());
    final franchiseId = parsed['franchiseId'];
    if (franchiseId == null || franchiseId.isEmpty) return;

    _bindFranchiseFromDeepLink(franchiseId);
  } catch (_) {
    // invalid / unknown link - silently ignore
  }
}

/// Retries until navigator is ready (cold start) then binds once.
void _bindFranchiseFromDeepLink(String franchiseId, {int attempt = 0}) {
  final context = navigatorKey.currentContext;
  if (context != null) {
    FranchiseBindService.bind(context, franchiseId).catchError((_) {});
    return;
  }
  if (attempt >= 40) return; // ~2s at 50ms
  Future<void>.delayed(const Duration(milliseconds: 50), () {
    _bindFranchiseFromDeepLink(franchiseId, attempt: attempt + 1);
  });
}

/// T1: Derive semantic ColorScheme from franchise primary/secondary seeds.
/// Surfaces/content/feedback come from DesignTokens defaults via UiConfig;
/// only primary/secondary (and on*) are brand-driven. HQ seeds only.
ColorScheme buildFranchiseColorScheme({
  required Color primary,
  required Color secondary,
}) {
  Color onFor(Color c) =>
      c.computeLuminance() > 0.55 ? const Color(0xFF212121) : Colors.white;

  final background = shared.UiConfig.backgroundColor;
  final surface = shared.UiConfig.surfaceColor;
  final onSurface = shared.UiConfig.textColor;
  final onSurfaceVariant = shared.UiConfig.secondaryTextColor;
  final outline = shared.UiConfig.cardBorderColor;
  final error = shared.UiConfig.errorColor;
  final surfaceContainer = Color.alphaBlend(
    onSurface.withValues(alpha: 0.06),
    surface,
  );

  return ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onFor(primary),
    secondary: secondary,
    onSecondary: onFor(secondary),
    error: error,
    onError: onFor(error),
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    outline: outline,
    surfaceContainerHighest: surfaceContainer,
    surfaceContainerHigh: surfaceContainer,
    surfaceContainer: surfaceContainer,
    surfaceContainerLow: surface,
    surfaceContainerLowest: surface,
    // ignore: deprecated_member_use — still used by some Material widgets
    background: background,
    // ignore: deprecated_member_use
    onBackground: onSurface,
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),

        /// FranchiseProvider from shared_core ONLY (P1 cleanup: dual wrapper removed).
        /// All franchise state + logic lives in shared_core.
        /// The plain Provider is sufficient: Consumers use it for hasValidFranchise guards + currentFranchiseId reads.
        // AFTER
        /// FranchiseProvider from shared_core ONLY (single source of truth).
        /// Must be ChangeNotifierProvider — FranchiseProvider extends ChangeNotifier
        /// and Selector / listen:true dependents need notifyListeners.
        ChangeNotifierProvider<shared.FranchiseProvider>(
          create: (_) => shared.FranchiseProvider(AppLocalStorage()),
        ),
        // P2: FranchiseProvider is now the single source for dynamic branding/theme.
        // shared.UiConfig and ThemeData react to it (via version + live getters).

        Provider<shared.AnalyticsService>(
            create: (_) => shared.AnalyticsServiceImpl()),
        ChangeNotifierProvider(create: (_) => IngredientMetadataProvider()),

        // Shared Core Services
        Provider<shared.AuthService>(create: (_) => shared.AuthServiceImpl()),
        Provider<shared.FirestoreService>(
            create: (_) => shared.FirestoreServiceImpl()),

        // User Stream
        StreamProvider<shared.User?>(
          create: (_) {
            final authService = shared.AuthServiceImpl();
            final firestoreService = shared.FirestoreServiceImpl();
            return authService.authStateChanges.asyncExpand((user) {
              if (user == null) return Stream.value(null);
              return firestoreService.getUserByIdStream(user.id);
            });
          },
          initialData: null,
        ),
      ],
      child: Builder(
        builder: (context) {
          final ingredientProvider =
              Provider.of<IngredientMetadataProvider>(context);
          if (!ingredientProvider.isLoaded) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
              debugShowCheckedModeBanner: false,
            );
          }

          // P2 white-label: wire live FranchiseProvider so all shared.UiConfig.* (colors, appName)
          // and downstream ThemeData become dynamic immediately.
          final fp =
              Provider.of<shared.FranchiseProvider>(context, listen: false);
          // This is the live branding path: FranchiseProvider → UiConfig (colors, appName, theme).                                                                                                   │
          // AppConfig.current remains a static fallback and must not construct FranchiseProvider.                                                                                                    │
          // Do not invent a zero-arg FranchiseProvider() — real construction requires AppLocalStorage.
          shared.UiConfig.setFranchiseProvider(fp);

          return Provider<Map<String, shared.IngredientMetadata>>.value(
            value: ingredientProvider.ingredients,
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                // P2: Theme + title are now fully dynamic from FranchiseProvider branding.
                // Selector on configVersion ensures only theme shell rebuilds on franchise switch.
                return Selector<shared.FranchiseProvider, String>(
                  selector: (ctx, p) =>
                      '${p.currentConfigVersion}|${p.currentPrimaryColorHex}|${p.currentSecondaryColorHex}',
                  builder: (context, brandingKey, _) {
                    return MaterialApp(
                      navigatorKey:
                          navigatorKey, // P2 deep link / QR navigation support
                      title: shared.UiConfig.dynamicAppName,
                      theme: () {
                        final scheme = buildFranchiseColorScheme(
                          primary: shared.UiConfig.primaryColor,
                          secondary: shared.UiConfig.secondaryColor,
                        );
                        return ThemeData(
                          useMaterial3: true,
                          colorScheme: scheme,
                          primaryColor: scheme.primary,
                          scaffoldBackgroundColor: scheme.surface,
                          appBarTheme: AppBarTheme(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            surfaceTintColor: Colors.transparent,
                            scrolledUnderElevation: 0,
                            elevation: DesignTokens.appBarElevation,
                            iconTheme: IconThemeData(color: scheme.onPrimary),
                            titleTextStyle: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.appBarTitleFontSize,
                              fontWeight: shared.UiConfig.fontWeightBold,
                              color: scheme.onPrimary,
                            ),
                          ),
                          cardTheme: CardThemeData(
                            color: scheme.surface,
                            surfaceTintColor: Colors.transparent,
                          ),
                          dividerColor: scheme.outline,
                          textTheme: TextTheme(
                            titleLarge: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.titleFontSize,
                              fontWeight: shared.UiConfig.fontWeightBold,
                              color: scheme.onSurface,
                            ),
                            bodyLarge: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.bodyFontSize,
                              fontWeight: shared.UiConfig.fontWeightNormal,
                              color: scheme.onSurface,
                            ),
                            bodyMedium: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.bodyFontSize,
                              color: scheme.onSurface,
                            ),
                            bodySmall: TextStyle(
                              fontFamily: DesignTokens.fontFamily,
                              fontSize: DesignTokens.captionFontSize,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }(),
                      locale: languageProvider.locale,
                      supportedLocales: AppLocalizations.supportedLocales,
                      localizationsDelegates: const [
                        AppLocalizations.delegate,
                        GlobalMaterialLocalizations.delegate,
                        GlobalWidgetsLocalizations.delegate,
                        GlobalCupertinoLocalizations.delegate,
                      ],
                      home: const HomeWrapper(),
                      debugShowCheckedModeBanner: false,
                      // P2.3: Per-route error boundary for deep resilience (catches widget build errors in any screen)
                      builder: (context, child) {
                        return GlobalErrorBoundary(
                          screenName: 'route',
                          child: child ?? const SizedBox.shrink(),
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  bool _dialogShown = false;
  bool _isInitializing = true;
  bool _brandingLoadStarted = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _brandingSub;
  String? _brandingFranchiseId;

  @override
  void dispose() {
    _brandingSub?.cancel();
    super.dispose();
  }

  void _listenBranding(shared.FranchiseProvider franchiseProvider) {
    final id = franchiseProvider.currentFranchiseId;
    if (id.isEmpty || id == 'unknown') return;
    if (_brandingFranchiseId == id && _brandingSub != null) return;

    _brandingSub?.cancel();
    _brandingFranchiseId = id;
    _brandingLoadStarted = true;

    _brandingSub = FirebaseFirestore.instance
        .collection('franchises')
        .doc(id)
        .snapshots()
        .listen(
      (doc) {
        if (!mounted) return;
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          debugPrint(
            '[branding stream] id=$id primary=${data['primaryColorHex']} '
            'secondary=${data['secondaryColorHex']}',
          );
          franchiseProvider.setBrandingFromFranchiseDoc(data);
        }
      },
      onError: (Object e, StackTrace st) {
        debugPrint('[branding stream] error: $e');
      },
    );
  }

  Future<void> _loadBranding(shared.FranchiseProvider franchiseProvider) async {
    final id = franchiseProvider.currentFranchiseId;
    if (id.isEmpty || id == 'unknown') return;
    try {
      // Drop in-memory branding so a previous primary cannot stick.
      franchiseProvider.setBrandingFromFranchiseDoc(const {});

      DocumentSnapshot<Map<String, dynamic>> doc;
      try {
        doc = await FirebaseFirestore.instance
            .collection('franchises')
            .doc(id)
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        doc = await FirebaseFirestore.instance
            .collection('franchises')
            .doc(id)
            .get(const GetOptions(source: Source.serverAndCache));
      }
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        debugPrint(
          '[branding] id=$id primary=${data['primaryColorHex']} '
          'secondary=${data['secondaryColorHex']} '
          'brandColor=${data['brandColor']}',
        );
        franchiseProvider.setBrandingFromFranchiseDoc(data);
      } else {
        franchiseProvider.setBrandingFromFranchiseDoc({
          'name': 'Doughboys Pizzeria',
          'primaryColorHex': '#E31837',
          'secondaryColorHex': '#FFD700',
        });
      }
    } catch (_) {
      // Fallback: DesignTokens / UiConfig statics
    }
  }

  @override
  Widget build(BuildContext context) {
    final sharedUser = Provider.of<shared.User?>(context);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);

    // CF1 / Decision 11: cold-start + session franchise takes priority over auth.
    // Signed-out users may browse when a franchise is already bound (storage / deep link).
    // Checkout gate remains later (CF6).

    // Kick branding stream as soon as we have a real franchiseId (signed-in or not).
    if (franchiseProvider.hasValidFranchise) {
      _listenBranding(franchiseProvider);
    }

    // No franchise: first landing is SignInScreen (auth + directory entry lives there).
    if (!franchiseProvider.hasValidFranchise) {
      return const SignInScreen();
    }

    // Franchise is bound. Allow signed-out browse (Decision 11 / CF6 partial).
    if (sharedUser == null) {
      return const MainMenuScreen();
    }

    // Signed-in path — keep existing initialize + profile-complete dialog logic.
    if (_isInitializing) {
      _isInitializing = false;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await franchiseProvider.initializeWithUser(sharedUser);
        if (mounted) {
          _listenBranding(franchiseProvider);
          setState(() {});
        }
      });
    } else if (franchiseProvider.hasValidFranchise) {
      _listenBranding(franchiseProvider);
    }

    // Convert to local model for dialog (unchanged)
    final localUser = app_user.User(
      id: sharedUser.id,
      name: sharedUser.name,
      email: sharedUser.email,
      phoneNumber: sharedUser.phoneNumber,
      roles: sharedUser.roles,
      addresses: sharedUser.addresses,
      language: sharedUser.language,
      status: sharedUser.status,
      defaultFranchise: sharedUser.defaultFranchise,
      avatarUrl: sharedUser.avatarUrl,
      franchiseIds: sharedUser.franchiseIds,
      completeProfile: sharedUser.completeProfile,
      onboardingComplete: sharedUser.onboardingComplete,
      isActive: sharedUser.isActive,
      updatedAt: sharedUser.updatedAt,
    );

    if ((localUser.completeProfile == null ||
            localUser.completeProfile == false) &&
        !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CompleteProfileDialog(user: localUser),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const MainMenuScreen();
  }
}
