import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show FlutterError, FlutterErrorDetails;
import 'package:provider/provider.dart';
import 'dart:async' show Zone, runZonedGuarded;
import 'package:franchise_mobile_app/core/widgets/global_error_boundary.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';
import 'package:app_links/app_links.dart'; // P2 deep linking foundations

// Shared Core
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;

// Local Providers & Config
import 'package:franchise_mobile_app/features/language/language_provider.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as app_user;
import 'package:franchise_mobile_app/config/ui_config.dart';
// Note: FranchiseProvider now comes exclusively from shared_core (single source of truth)

// Screens
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/complete_profile_dialog.dart';
import 'firebase_options.dart';

/// Global navigator key for deep link / QR navigation from anywhere (foundations)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Ingredient Metadata Provider (global for now)
class IngredientMetadataProvider extends ChangeNotifier {
  final Map<String, shared.IngredientMetadata> _ingredients = {};
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  Map<String, shared.IngredientMetadata> get ingredients => _ingredients;

  IngredientMetadataProvider() {
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      // P2.3 hardening: ingredient_metadata is under franchises/{franchiseId}/ingredient_metadata per schema.
      // Use last selected (from storage) or safe default to avoid global collectionGroup/top-level leak.
      String fid = 'doughboyspizzeria';
      try {
        final stored = await AppLocalStorage().getString('selectedFranchiseId');
        if (stored != null && stored.isNotEmpty && stored != 'unknown') {
          fid = stored;
        }
      } catch (_) {}
      final snapshot = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(fid)
          .collection('ingredient_metadata')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] ?? doc.id;
        _ingredients[id] =
            shared.IngredientMetadata.fromMap({...data, 'id': id});
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoaded = true;
      notifyListeners();
      // Error intentionally not logged here (one-time bootstrap provider)
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // P2.3 Production Readiness: Comprehensive error boundaries + resilience
  // 1. Flutter framework errors
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

  // 2. Async / Zone errors (catches errors in Futures, streams, etc. outside try/catch)
  void _reportZoneError(Object error, StackTrace stack) {
    shared.ErrorLogger.log(
      message: 'Uncaught async error: $error',
      source: 'Zone',
      severity: 'fatal',
      stack: stack.toString(),
      contextData: {'phase': 'runApp'},
    );
  }

  // 3. Wire shared.ErrorLogger (can be overridden later with Crashlytics etc.)
  shared.ErrorLogger.setCustomLogger(({
    required String message,
    String? source,
    String? severity,
    String? stack,
    Map<String, dynamic>? contextData,
  }) {
    // Example: also send to Firebase Crashlytics in prod builds if package added
    // if (kReleaseMode) FirebaseCrashlytics.instance.recordError(...);
    // For now the default + our log above is sufficient
  });

  // P2 deep link foundations (app_links)
  _initDeepLinks();

  // Run inside a guarded zone for full async coverage + wrap root with GlobalErrorBoundary
  runZonedGuarded(() {
    runApp(
      GlobalErrorBoundary(
        screenName: 'root',
        child: const MyApp(),
      ),
    );
  }, _reportZoneError);
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

    final context = navigatorKey.currentContext;
    if (context != null) {
      final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);

      // Use the same pattern as QrScanScreen for consistency
      fp.setFranchiseId(franchiseId).then((_) {
        // Best-effort branding reload (FranchiseProvider + UiConfig)
        FirebaseFirestore.instance
            .collection('franchises')
            .doc(franchiseId)
            .get()
            .then((doc) {
          if (doc.exists && doc.data() != null) {
            fp.setBrandingFromFranchiseDoc(doc.data()!);
          }
        }).catchError((_) {});

        if (navigatorKey.currentContext != null) {
          Navigator.of(navigatorKey.currentContext!).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
            (route) => false,
          );
        }
      }).catchError((_) {});
    }
  } catch (_) {
    // invalid / unknown link - silently ignore
  }
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
        Provider<shared.FranchiseProvider>(
          create: (_) => shared.FranchiseProvider(AppLocalStorage()),
        ),
        // P2: FranchiseProvider is now the single source for dynamic branding/theme.
        // UiConfig and ThemeData react to it (via version + live getters).

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

          // P2 white-label: wire live FranchiseProvider so all UiConfig.* (colors, appName)
          // and downstream ThemeData become dynamic immediately.
          final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
          UiConfig.setFranchiseProvider(fp);

          return Provider<Map<String, shared.IngredientMetadata>>.value(
            value: ingredientProvider.ingredients,
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                // P2: Theme + title are now fully dynamic from FranchiseProvider branding.
                // Selector on configVersion ensures only theme shell rebuilds on franchise switch.
                return Selector<shared.FranchiseProvider, int>(
                  selector: (ctx, p) => p.currentConfigVersion,
                  builder: (context, version, _) {
                    return MaterialApp(
                      navigatorKey: navigatorKey, // P2 deep link / QR navigation support
                      title: UiConfig.dynamicAppName,
                      theme: ThemeData(
                        primaryColor: UiConfig.primaryColor,
                        scaffoldBackgroundColor: UiConfig.backgroundColorDark,
                        colorScheme: ColorScheme.fromSwatch().copyWith(
                          secondary: UiConfig.secondaryColor,
                        ),
                        textTheme: TextTheme(
                          titleLarge: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.titleFontSize,
                            fontWeight: UiConfig.fontWeightBold,
                          ),
                          bodyLarge: TextStyle(
                            fontFamily: DesignTokens.fontFamily,
                            fontSize: DesignTokens.bodyFontSize,
                            fontWeight: UiConfig.fontWeightNormal,
                          ),
                        ),
                      ),
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
  bool _isInitializing = true; // ← NEW

  @override
  Widget build(BuildContext context) {
    final sharedUser = Provider.of<shared.User?>(context);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);

    if (sharedUser == null) {
      return const SignInScreen();
    }

    // Initialize franchise (only once)
    if (_isInitializing && !franchiseProvider.hasValidFranchise) {
      _isInitializing = false; // prevent multiple calls
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await franchiseProvider.initializeWithUser(sharedUser);

        // P2 foundations: fetch full franchise doc and push branding into provider.
        // This makes UiConfig colors + appName + ThemeData live for this franchise.
        try {
          final doc = await FirebaseFirestore.instance
              .collection('franchises')
              .doc(franchiseProvider.currentFranchiseId)
              .get();
          if (doc.exists && doc.data() != null) {
            franchiseProvider.setBrandingFromFranchiseDoc(doc.data()!);
          } else {
            franchiseProvider.setBrandingFromFranchiseDoc({
              'name': 'Doughboys Pizzeria',
              'primaryColorHex': '#E31837',
              'secondaryColorHex': '#FFD700',
            });
          }
        } catch (_) {
          // Silent fallback to DesignTokens/UiConfig statics
        }

        if (mounted) setState(() {}); // force rebuild (version bump also triggers Selector)
      });
    }

    // Show loading while initializing
    if (_isInitializing || !franchiseProvider.hasValidFranchise) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Convert to local model for dialog
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
