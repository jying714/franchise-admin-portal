import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_localizations/flutter_localizations.dart';

// === SHARED_CORE BARREL (single source of truth) ===
import 'package:shared_core/shared_core.dart' as shared;

// === LOCAL WEB-APP CONCRETE IMPLs ===
import 'package:franchise_admin_portal/core/providers/franchise_subscription_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/platform_plan_selection_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/franchise_info_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_metadata_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/ingredient_type_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_progress_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/menu_item_provider_impl.dart';

import 'package:franchise_admin_portal/core/services/franchise_subscription_service_impl.dart';
import 'package:franchise_admin_portal/core/services/franchise_feature_service_impl.dart';
import 'package:franchise_admin_portal/core/services/analytics_service_impl.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service_impl.dart';
import 'package:franchise_admin_portal/core/services/auth_service_impl.dart';

// === WEB-APP SCREENS & WIDGETS ===
import 'package:franchise_admin_portal/firebase_options.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/core/theme_provider.dart';
import 'package:franchise_admin_portal/core/utils/app_local_storage.dart';

import 'package:franchise_admin_portal/landing_page.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/admin/auth/invite_accept_screen.dart';
import 'package:franchise_admin_portal/widgets/franchise_gate.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/developer/developer_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/franchise/franchise_selector_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/owner_hq_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/invoice_list_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/invoice_detail_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/payout_list_screen.dart';
import 'package:franchise_admin_portal/admin/owner/platform_owner_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/profile/universal_profile_screen.dart';
import 'package:franchise_admin_portal/admin/owner/screens/full_platform_plans_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/available_platform_plans_screen.dart';
import 'package:franchise_admin_portal/admin/owner/screens/full_franchise_subscription_list_screen.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/billing_subscription_tools_screen.dart';
import 'package:franchise_admin_portal/admin/devtools/subscriptions/subscription_dev_tools_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_ingredients_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_ingredient_type_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_categories_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_items_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_feature_setup_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_review_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/menu_item_editor_screen.dart';
import 'package:franchise_admin_portal/widgets/profile_gate_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Returns initial unauth route and optional invite token.
Map<String, dynamic> getInitialUnauthRoute() {
  final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    shared.ErrorLogger.log(
      message: '[getInitialUnauthRoute] User is signed in. Skipping invite-accept route.',
      source: 'main.dart',
      severity: 'info',
    );
    return {'route': '/', 'token': ''};
  }

  final hash = Uri.base.fragment;
  shared.ErrorLogger.log(
    message: '[main.dart][getInitialUnauthRoute] Current hash: $hash',
    source: 'main.dart',
    severity: 'info',
  );

  if (hash.startsWith('/invite-accept')) {
    final queryIndex = hash.indexOf('?');
    String token = '';
    if (queryIndex != -1) {
      final queryString = hash.substring(queryIndex + 1);
      try {
        final params = Uri.splitQueryString(queryString);
        token = params['token'] ?? '';
      } catch (e, stack) {
        shared.ErrorLogger.log(
          message: '[main.dart][getInitialUnauthRoute] Error parsing query string: $e',
          stack: stack.toString(),
          source: 'main.dart',
          severity: 'error',
        );
      }
    }
    return {'route': '/invite-accept', 'token': token};
  }

  shared.ErrorLogger.log(
    message: '[main.dart][getInitialUnauthRoute] Defaulting to landing.',
    source: 'main.dart',
    severity: 'info',
  );
  return {'route': '/', 'token': ''};
}

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    shared.ErrorLogger.log(
      message: details.exceptionAsString(),
      stack: details.stack?.toString(),
      source: 'FlutterError',
      severity: 'fatal',
      contextData: {
        'library': details.library,
        'context': details.context?.toDescription() ?? details.context.toString(),
      },
    );
  };

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await fb_auth.FirebaseAuth.instance.setPersistence(fb_auth.Persistence.LOCAL);

    final storage = AppLocalStorage();
    final authService = AuthServiceImpl();
    final firestoreService = shared.FirestoreServiceImpl();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
          Provider<shared.FranchiseProvider>(
            create: (_) => shared.FranchiseProvider(storage),
          ),
          Provider<shared.AuthService>.value(value: authService),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<shared.FirestoreService>.value(value: firestoreService),
          Provider<shared.AnalyticsService>.value(value: shared.AnalyticsServiceImpl()),
          StreamProvider<fb_auth.User?>.value(
            value: fb_auth.FirebaseAuth.instance.authStateChanges(),
            initialData: null,
          ),
        ],
        child: const FranchiseAppRootSplit(),
      ),
    );
  }, (Object error, StackTrace stack) {
    shared.ErrorLogger.log(
      message: error.toString(),
      stack: stack.toString(),
      source: 'runZonedGuarded',
      severity: 'fatal',
    );
  });
}

/// Safe themeMode with defensive fallback (no print).
ThemeMode safeThemeMode(BuildContext context) {
  try {
    return Provider.of<ThemeProvider>(context, listen: true).themeMode ?? ThemeMode.system;
  } catch (e, stack) {
    shared.ErrorLogger.log(
      message: 'ThemeProvider not found in context',
      stack: stack.toString(),
      source: 'safeThemeMode',
      severity: 'warning',
    );
    return ThemeMode.system;
  }
}

/// Authenticated app root and routing logic
class FranchiseAuthenticatedRoot extends StatefulWidget {
  const FranchiseAuthenticatedRoot({super.key});

  @override
  State<FranchiseAuthenticatedRoot> createState() =>
      _FranchiseAuthenticatedRootState();
}

class _FranchiseAuthenticatedRootState extends State<FranchiseAuthenticatedRoot> {
  @override
  Widget build(BuildContext context) {
    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, _) {
        final userNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
        final user = userNotifier.user;

        if (user?.roles?.contains('platform_owner') ?? false) {
          return const MaterialApp(home: PlatformOwnerDashboardScreen(currentScreen: 'platform-owner/dashboard'));
        }
        if (user?.roles?.contains('hq_owner') ?? false) {
          return const MaterialApp(home: OwnerHqDashboardScreen());
        }
        return FranchiseGate(
          child: const AdminDashboardScreen(),
        );
      },
    );
  }
}

/// Root widget that cleanly splits unauthenticated vs authenticated
class FranchiseAppRootSplit extends StatelessWidget {
  const FranchiseAppRootSplit({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);

    final userNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
    if (firebaseUser != null && userNotifier.user == null && !userNotifier.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNotifier.loadUser();
      });
    }

    // ==== UNAUTHENTICATED APP ====
    if (firebaseUser == null) {
      return Builder(
        builder: (ctx) {
          final initial = getInitialUnauthRoute();
          final String initialRoute = initial['route'] as String;
          final String inviteToken = initial['token'] as String;

          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Franchise Admin Portal',
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode: Provider.of<ThemeProvider>(context, listen: true).themeMode ?? ThemeMode.system,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: initialRoute,
            onGenerateRoute: (RouteSettings settings) {
              Uri uri = Uri.parse(settings.name ?? '/');
              final String path = uri.path;

              if (path == '/' || path == '/landing') {
                return MaterialPageRoute(builder: (_) => const LandingPage());
              }
              if (path == '/sign-in') {
                return MaterialPageRoute(builder: (_) => const SignInScreen());
              }
              if (path == '/invite-accept') {
                String? token;
                if (uri.queryParameters.containsKey('token')) {
                  token = uri.queryParameters['token'];
                } else if (settings.arguments is Map &&
                    (settings.arguments as Map).containsKey('token')) {
                  token = (settings.arguments as Map)['token'] as String?;
                } else if (inviteToken.isNotEmpty) {
                  token = inviteToken;
                }

                return MaterialPageRoute(
                  builder: (_) => InviteAcceptScreen(inviteToken: token),
                );
              }

              return MaterialPageRoute(builder: (_) => const LandingPage());
            },
          );
        },
      );
    }

    // ==== AUTHENTICATED APP ====
    return Selector<UserProfileNotifier, bool>(
      selector: (_, notifier) => notifier.user != null && !notifier.loading,
      builder: (context, isUserReady, _) {
        final franchiseProvider = Provider.of<shared.FranchiseProvider>(context, listen: false);
        final userNotifier = Provider.of<UserProfileNotifier>(context, listen: false);
        final firebaseUser = Provider.of<fb_auth.User?>(context, listen: false);

        final user = userNotifier.user;
        final requiresFranchise = user?.isFranchiseRequired ?? true;
        final fid = franchiseProvider.franchiseId;
        final isFranchiseReady = !requiresFranchise ||
            (fid != null && fid.isNotEmpty && fid != 'unknown');

        if (!isUserReady || !isFranchiseReady) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }

        // ========= FULL BUSINESS PROVIDER TREE (concrete *_Impl only) =========
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => shared.AdminUserProvider()),

            ChangeNotifierProxyProvider<shared.FranchiseProvider, FranchiseSubscriptionProviderImpl>(
              create: (_) => FranchiseSubscriptionProviderImpl(
                service: FranchiseSubscriptionServiceImpl(),
                franchiseId: '',
              ),
              update: (_, franchiseProvider, notifier) {
                final fid = franchiseProvider.franchiseId;
                final userNotifierLocal = Provider.of<UserProfileNotifier>(_, listen: false);
                final userRoles = userNotifierLocal.user?.roles ?? [];

                notifier ??= FranchiseSubscriptionProviderImpl(
                  service: FranchiseSubscriptionServiceImpl(),
                  franchiseId: fid,
                );

                notifier.setUserRoles(userRoles);

                if (franchiseProvider.hasValidFranchise &&
                    fid.isNotEmpty &&
                    fid != notifier.franchiseId) {
                  notifier.updateFranchiseId(fid);
                }

                return notifier;
              },
            ),

            ChangeNotifierProvider(create: (_) => PlatformPlanSelectionProviderImpl()),

            ChangeNotifierProxyProvider2<shared.FranchiseProvider, shared.FirestoreService, FranchiseInfoProviderImpl>(
              create: (_) => FranchiseInfoProviderImpl(
                firestore: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseProvider: Provider.of<shared.FranchiseProvider>(_, listen: false),
              ),
              update: (_, franchiseProvider, firestoreService, previous) {
                final provider = previous ??
                    FranchiseInfoProviderImpl(
                      firestore: firestoreService,
                      franchiseProvider: franchiseProvider,
                    );
                provider.loadFranchiseInfo();
                return provider;
              },
            ),

            ChangeNotifierProxyProvider2<shared.FranchiseProvider, shared.FirestoreService, FranchiseFeatureProviderImpl>(
              create: (_) => FranchiseFeatureProviderImpl(
                service: FranchiseFeatureServiceImpl(),
                franchiseId: '',
              ),
              update: (_, franchiseProvider, firestoreService, previous) {
                final fid = franchiseProvider.franchiseId;
                if (!franchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ??
                    FranchiseFeatureProviderImpl(
                      service: FranchiseFeatureServiceImpl(),
                      franchiseId: fid,
                    );
                if (fid.isNotEmpty && fid != provider.currentFranchiseId) {
                  provider.setFranchiseId(fid);
                }
                return provider;
              },
            ),

            ChangeNotifierProxyProvider2<shared.FirestoreService, shared.FranchiseProvider, OnboardingProgressProviderImpl>(
              create: (_) => OnboardingProgressProviderImpl(
                firestore: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseId: '',
              ),
              update: (_, firestoreService, franchiseProvider, previous) {
                final fid = franchiseProvider.franchiseId ?? '';
                final provider = previous ??
                    OnboardingProgressProviderImpl(
                      firestore: firestoreService,
                      franchiseId: fid,
                    );
                if (fid.isNotEmpty && fid != provider.franchiseId) {
                  return OnboardingProgressProviderImpl(
                    firestore: firestoreService,
                    franchiseId: fid,
                  );
                }
                return provider;
              },
            ),

            ChangeNotifierProxyProvider2<shared.FirestoreService, FranchiseInfoProvider, IngredientMetadataProviderImpl>(
              create: (_) => IngredientMetadataProviderImpl(
                shared.firestoreService: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseId: '',
              ),
              update: (_, firestore, franchiseInfo, previous) {
                final franchiseId = franchiseInfo.franchise?.id ?? '';
                final provider = previous ??
                    IngredientMetadataProviderImpl(
                      shared.firestoreService: firestore,
                      franchiseId: franchiseId,
                    );
                if (franchiseId.isNotEmpty &&
                    franchiseId != provider.franchiseId &&
                    franchiseId != 'unknown') {
                  return IngredientMetadataProviderImpl(
                    shared.firestoreService: firestore,
                    franchiseId: franchiseId,
                  )..load();
                }
                return provider;
              },
            ),

            ChangeNotifierProxyProvider2<shared.FirestoreService, shared.FranchiseProvider, shared.CategoryProvider>(
              create: (_) => shared.CategoryProvider(
                firestore: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseId: '',
              ),
              update: (_, firestore, franchiseProvider, previous) {
                final fid = franchiseProvider.franchiseId;
                if (!franchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ??
                    shared.CategoryProvider(
                      firestore: firestore,
                      franchiseId: fid,
                    );
                if (fid.isNotEmpty && fid != provider.franchiseId) {
                  provider.updateFranchiseId(fid);
                }
                return provider;
              },
            ),

            ChangeNotifierProxyProvider3<shared.FirestoreService, shared.FranchiseProvider, FranchiseInfoProvider, MenuItemProviderImpl>(
              create: (_) => MenuItemProviderImpl(
                shared.firestoreService: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseInfoProvider: Provider.of<FranchiseInfoProvider>(_, listen: false),
              ),
              update: (_, sharedFirestoreService, franchiseProvider, franchiseInfoProvider, previous) {
                final fid = franchiseProvider.franchiseId;
                if (!franchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ??
                    MenuItemProviderImpl(
                      shared.firestoreService: sharedFirestoreService,
                      franchiseInfoProvider: franchiseInfoProvider,
                    );
                provider.franchiseInfoProvider = franchiseInfoProvider;
                if (fid.isNotEmpty && fid != 'unknown') {
                  provider.loadMenuItems(fid);
                }
                return provider;
              },
            ),

            ChangeNotifierProxyProvider2<shared.FirestoreService, shared.FranchiseProvider, IngredientTypeProviderImpl>(
              create: (_) => IngredientTypeProviderImpl(
                shared.firestoreService: Provider.of<shared.FirestoreService>(_, listen: false),
              ),
              update: (_, sharedFirestoreService, franchiseProvider, previous) {
                final fid = franchiseProvider.franchiseId;
                if (!franchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ?? IngredientTypeProviderImpl(
                  shared.firestoreService: sharedFirestoreService,
                );
                if (fid.isNotEmpty && fid != provider.franchiseId) {
                  provider.franchiseId = fid;
                  provider.load(franchiseIdOverride: fid);
                }
                return provider;
              },
            ),

            Provider<AuditLogService>.value(value: AuditLogServiceImpl()),
            ChangeNotifierProvider(
              create: (_) => FranchiseeInvitationProvider(
                service: FranchiseeInvitationService(
                  shared.firestoreService: Provider.of<shared.FirestoreService>(_, listen: false),
                ),
              ),
            ),
            ChangeNotifierProvider(create: (_) => RestaurantTypeProvider()),

            Provider<shared.AnalyticsService>.value(value: shared.AnalyticsServiceImpl()),
            StreamProvider<fb_auth.User?>.value(
              value: fb_auth.FirebaseAuth.instance.authStateChanges(),
              initialData: null,
            ),
            ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
          ],
          child: FranchiseAuthenticatedRoot(
            key: ValueKey(firebaseUser?.uid),
          ),
        );
      },
    );
  }
}


// ===== THEME DEFINITIONS (shared.DesignTokens only - per barrel rules) =====

final ThemeData _lightTheme = ThemeData(
  fontFamily: shared.DesignTokens.fontFamily,
  primaryColor: shared.DesignTokens.primaryColor,
  scaffoldBackgroundColor: shared.DesignTokens.backgroundColor,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: shared.DesignTokens.primaryColor,
    onPrimary: shared.DesignTokens.foregroundColor,
    secondary: shared.DesignTokens.secondaryColor,
    onSecondary: shared.DesignTokens.foregroundColor,
    error: shared.DesignTokens.errorColor,
    onError: shared.DesignTokens.errorTextColor,
    background: shared.DesignTokens.backgroundColor,
    onBackground: shared.DesignTokens.textColor,
    surface: shared.DesignTokens.surfaceColor,
    onSurface: shared.DesignTokens.textColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: shared.DesignTokens.appBarBackgroundColor,
    foregroundColor: shared.DesignTokens.appBarForegroundColor,
    iconTheme: IconThemeData(color: shared.DesignTokens.appBarIconColor),
    elevation: shared.DesignTokens.appBarElevation,
    titleTextStyle: TextStyle(
      fontFamily: shared.DesignTokens.appBarFontFamily,
      fontSize: shared.DesignTokens.appBarTitleFontSize,
      fontWeight: shared.DesignTokens.appBarTitleFontWeight,
      color: shared.DesignTokens.appBarForegroundColor,
    ),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminBodyFontSize,
      color: shared.DesignTokens.textColor,
    ),
    titleLarge: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminTitleFontSize,
      fontWeight: shared.DesignTokens.titleFontWeight,
      color: shared.DesignTokens.textColor,
    ),
    titleMedium: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminCaptionFontSize,
      color: shared.DesignTokens.secondaryTextColor,
    ),
  ),
  cardTheme: CardTheme(
    color: shared.DesignTokens.surfaceColor,
    elevation: shared.DesignTokens.adminCardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(shared.DesignTokens.adminCardRadius),
    ),
    margin: EdgeInsets.all(shared.DesignTokens.adminCardSpacing),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: shared.DesignTokens.primaryColor,
      foregroundColor: shared.DesignTokens.foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shared.DesignTokens.adminButtonRadius),
      ),
      elevation: shared.DesignTokens.adminButtonElevation,
      textStyle: TextStyle(
        fontSize: shared.DesignTokens.adminButtonFontSize,
        fontFamily: shared.DesignTokens.fontFamily,
        fontWeight: shared.DesignTokens.titleFontWeight,
      ),
      padding: shared.DesignTokens.buttonPadding,
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: shared.DesignTokens.surfaceColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(shared.DesignTokens.dialogBorderRadius),
    ),
    elevation: shared.DesignTokens.adminDialogElevation,
    titleTextStyle: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminTitleFontSize,
      fontWeight: FontWeight.bold,
      color: shared.DesignTokens.textColor,
    ),
    contentTextStyle: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminBodyFontSize,
      color: shared.DesignTokens.textColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(shared.DesignTokens.formFieldRadius),
    ),
  ),
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: shared.DesignTokens.fontFamily,
  primaryColor: shared.DesignTokens.primaryColor,
  scaffoldBackgroundColor: shared.DesignTokens.backgroundColorDark,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: shared.DesignTokens.primaryColor,
    onPrimary: shared.DesignTokens.foregroundColorDark,
    secondary: shared.DesignTokens.secondaryColor,
    onSecondary: shared.DesignTokens.foregroundColorDark,
    error: shared.DesignTokens.errorColor,
    onError: shared.DesignTokens.errorTextColor,
    background: shared.DesignTokens.backgroundColorDark,
    onBackground: shared.DesignTokens.textColorDark,
    surface: shared.DesignTokens.surfaceColorDark,
    onSurface: shared.DesignTokens.textColorDark,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: shared.DesignTokens.appBarBackgroundColorDark,
    foregroundColor: shared.DesignTokens.appBarForegroundColorDark,
    iconTheme: IconThemeData(color: shared.DesignTokens.appBarForegroundColorDark),
    elevation: shared.DesignTokens.appBarElevation,
    titleTextStyle: TextStyle(
      fontFamily: shared.DesignTokens.appBarFontFamily,
      fontSize: shared.DesignTokens.appBarTitleFontSize,
      fontWeight: shared.DesignTokens.appBarTitleFontWeight,
      color: shared.DesignTokens.appBarForegroundColorDark,
    ),
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: shared.DesignTokens.backgroundColorDark,
    scrimColor: Colors.black.withOpacity(0.5),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminBodyFontSize,
      color: shared.DesignTokens.textColorDark,
    ),
    titleLarge: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminTitleFontSize,
      fontWeight: shared.DesignTokens.titleFontWeight,
      color: shared.DesignTokens.textColorDark,
    ),
    titleMedium: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminCaptionFontSize,
      color: shared.DesignTokens.secondaryTextColor,
    ),
  ),
  cardTheme: CardTheme(
    color: shared.DesignTokens.surfaceColorDark,
    elevation: shared.DesignTokens.adminCardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(shared.DesignTokens.adminCardRadius),
    ),
    margin: EdgeInsets.all(shared.DesignTokens.adminCardSpacing),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: shared.DesignTokens.primaryColor,
      foregroundColor: shared.DesignTokens.foregroundColorDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(shared.DesignTokens.adminButtonRadius),
      ),
      elevation: shared.DesignTokens.adminButtonElevation,
      textStyle: TextStyle(
        fontSize: shared.DesignTokens.adminButtonFontSize,
        fontFamily: shared.DesignTokens.fontFamily,
        fontWeight: shared.DesignTokens.titleFontWeight,
      ),
      padding: shared.DesignTokens.buttonPadding,
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: shared.DesignTokens.surfaceColorDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(shared.DesignTokens.dialogBorderRadius),
    ),
    elevation: shared.DesignTokens.adminDialogElevation,
    titleTextStyle: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminTitleFontSize,
      fontWeight: FontWeight.bold,
      color: shared.DesignTokens.textColorDark,
    ),
    contentTextStyle: TextStyle(
      fontFamily: shared.DesignTokens.fontFamily,
      fontSize: shared.DesignTokens.adminBodyFontSize,
      color: shared.DesignTokens.textColorDark,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(color: shared.DesignTokens.hintTextColorDark),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(shared.DesignTokens.formFieldRadius),
    ),
  ),
  dividerColor: shared.DesignTokens.dividerColorDark,
  iconTheme: IconThemeData(color: shared.DesignTokens.textColorDark),
);