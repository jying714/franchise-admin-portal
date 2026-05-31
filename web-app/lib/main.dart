// File: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/alert_list_screen.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/firebase_options.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/theme_provider.dart';
import 'package:franchise_admin_portal/core/utils/app_local_storage.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart' show UserProfileNotifier;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/core/services/auth_service_impl.dart' show AuthServiceImpl;
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/landing_page.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/widgets/profile_gate_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/developer/developer_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/franchise/franchise_selector_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/owner_hq_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/invoice_list_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/invoice_detail_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/payout_list_screen.dart';
import 'package:franchise_admin_portal/admin/owner/platform_owner_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/profile/universal_profile_screen.dart';
import 'package:franchise_admin_portal/admin/auth/invite_accept_screen.dart';
import 'package:franchise_admin_portal/admin/profile/franchise_onboarding_screen.dart';
import 'package:franchise_admin_portal/admin/owner/screens/full_platform_plans_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/screens/available_platform_plans_screen.dart';
import 'package:franchise_admin_portal/admin/owner/screens/full_franchise_subscription_list_screen.dart';
import 'package:franchise_admin_portal/admin/devtools/billing/billing_subscription_tools_screen.dart';
import 'package:franchise_admin_portal/admin/devtools/subscriptions/subscription_dev_tools_screen.dart';
import 'package:franchise_admin_portal/core/section_registry.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_ingredients_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_ingredient_type_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_categories_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_menu_items_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_feature_setup_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/menu_item_editor_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/onboarding/screens/onboarding_review_screen.dart';
import 'dart:html' as html;

// (Include ALL your other screen/provider/model imports here)

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Returns initial unauth route and optional invite token, e.g. ('/invite-accept', 'abc123').
Map<String, dynamic> getInitialUnauthRoute() {
  final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    print(
        '[getInitialUnauthRoute] User is signed in. Skipping invite-accept route.');
    return {'route': '/', 'token': ''};
  }
  final hash = html.window.location.hash;
  print(
      '[main.dart][getInitialUnauthRoute] Current window.location.hash: $hash');
  if (hash.startsWith('#/invite-accept')) {
    final queryIndex = hash.indexOf('?');
    String token = '';
    if (queryIndex != -1) {
      final queryString = hash.substring(queryIndex + 1);
      print(
          '[main.dart][getInitialUnauthRoute] Extracted query string: $queryString');
      try {
        final params = Uri.splitQueryString(queryString);
        token = params['token'] ?? '';
        print('[main.dart][getInitialUnauthRoute] Found token param: $token');
      } catch (e, stack) {
        print(
            '[main.dart][getInitialUnauthRoute] Error parsing query string: $e\n$stack');
      }
    } else {
      print('[main.dart][getInitialUnauthRoute] No query string found after ?');
    }
    return {
      'route': '/invite-accept',
      'token': token,
    };
  }
  print(
      '[main.dart][getInitialUnauthRoute] No invite-accept hash found. Defaulting to landing.');
  return {
    'route': '/',
    'token': '',
  };
}

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[GLOBAL ERROR] ${details.exceptionAsString()}');
    debugPrintStack(stackTrace: details.stack);
    ErrorWidget.builder = (FlutterErrorDetails details) {
      debugPrint('ErrorWidget: ${details.exceptionAsString()}');
      return Center(child: Text('Error: ${details.exceptionAsString()}'));
    };
  };
  print('[main.dart] main(): Starting runZonedGuarded.');
  runZonedGuarded(() async {
    print('[main.dart] runZonedGuarded: Initializing Flutter bindings.');
    WidgetsFlutterBinding.ensureInitialized();

    print('[main.dart] runZonedGuarded: Initializing Firebase.');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await fb_auth.FirebaseAuth.instance.setPersistence(
      fb_auth.Persistence.LOCAL,
    );
    print(
        '[main.dart] runZonedGuarded: Firebase initialized and persistence set.');

    FlutterError.onError = (FlutterErrorDetails details) async {
      print('[main.dart] FlutterError.onError: ${details.exceptionAsString()}');
      print(details.stack);
      FlutterError.dumpErrorToConsole(details);
      await shared.ErrorLogger.log(
        message: details.exceptionAsString(),
        stack: details.stack?.toString(),
        source: 'FlutterError',
        severity: 'fatal',
        contextData: {
          'library': details.library,
          'context':
              details.context?.toDescription() ?? details.context.toString(),
        },
      );
    };

    final storage = AppLocalStorage();
    final authService = AuthServiceImpl(); // web's impl with all P2.5 methods
    final firestoreService = shared.FirestoreService(); // or local admin impl if needed
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
          ChangeNotifierProvider(
              create: (_) {
                final fp = shared.FranchiseProvider(storage);
                DesignTokens.setFranchiseProvider(fp); // P2.5 dynamic theming bridge
                return fp;
              }), // P2.5: ctor fixed + UiConfig/DesignTokens wired
          ChangeNotifierProvider<shared.AuthService>.value(value: authService),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<shared.FirestoreService>.value(value: firestoreService),
          Provider(create: (_) => shared.AnalyticsServiceImpl()),
          StreamProvider<fb_auth.User?>.value(
            value: fb_auth.FirebaseAuth.instance.authStateChanges(),
            initialData: null,
          ),
        ],
        child: const FranchiseAppRootSplit(),
      ),
    );
  }, (Object error, StackTrace stack) async {
    print('[main.dart] runZonedGuarded: Uncaught error: $error');
    await shared.ErrorLogger.log(
      message: error.toString(),
      stack: stack.toString(),
      source: 'runZonedGuarded',
      severity: 'fatal',
    );
  });
}

/// Returns a non-null themeMode for MaterialApp, with debug prints and ultra-defensive fallback.
ThemeMode safeThemeMode(BuildContext context) {
  try {
    final themeMode =
        Provider.of<ThemeProvider>(context, listen: true).themeMode;
    print('[main.dart][safeThemeMode] ThemeProvider.themeMode = $themeMode');
    return themeMode ?? ThemeMode.system;
  } catch (e, stack) {
    print(
        '[main.dart][safeThemeMode] ThemeProvider not found in context: $e\n$stack');
    return ThemeMode.system;
  }
}

/// Root widget that cleanly splits unauthenticated vs authenticated
class FranchiseAppRootSplit extends StatelessWidget {
  const FranchiseAppRootSplit({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    print('[main.dart][FranchiseAppRootSplit] firebaseUser: $firebaseUser');

    final userNotifier =
        Provider.of<UserProfileNotifier>(context, listen: false);
    if (firebaseUser != null &&
        userNotifier.user == null &&
        !userNotifier.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        userNotifier
            .loadUser(); // âœ… defer user loading until firebaseUser is available
      });
    }

    // ==== UNAUTHENTICATED APP ====
    if (firebaseUser == null) {
      print(
          '[main.dart][FranchiseAppRootSplit] Unauthenticated: showing public app');
      return Builder(
        builder: (ctx) {
          final initial = getInitialUnauthRoute();
          final String initialRoute = initial['route'] as String;
          final String inviteToken = initial['token'] as String;
          print(
              '[main.dart][FranchiseAppRootSplit] Unauthed initialRoute: $initialRoute, inviteToken: $inviteToken');
          debugPrint(
              'AppLocalizations.supportedLocales: ${AppLocalizations.supportedLocales}');

          return MaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            title: 'Franchise Admin Portal',
            theme: _lightTheme,
            darkTheme: _darkTheme,
            themeMode:
                Provider.of<ThemeProvider>(context, listen: true).themeMode ??
                    ThemeMode.system,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            initialRoute: initialRoute,
            onGenerateRoute: (RouteSettings settings) {
              print(
                  '[DEBUG][main.dart][onGenerateRoute] [UNAUTH] route=${settings.name}, args=${settings.arguments}');
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
        final shared.FranchiseProvider =
            Provider.of<shared.FranchiseProvider>(context, listen: false);
        final userNotifier =
            Provider.of<UserProfileNotifier>(context, listen: false);
        final firebaseUser = Provider.of<fb_auth.User?>(context, listen: false);

        final user = userNotifier.user;
        final requiresFranchise = user?.isFranchiseRequired ?? true;
        final fid = shared.FranchiseProvider.franchiseId;
        final isFranchiseReady = !requiresFranchise ||
            (fid != null && fid.isNotEmpty && fid != 'unknown');

        if (!isUserReady || !isFranchiseReady) {
          debugPrint('[FranchiseAppRootSplit] â³ Waiting for readiness...');
          debugPrint('[FranchiseAppRootSplit] firebaseUser: $firebaseUser');
          debugPrint('[FranchiseAppRootSplit] isUserReady = $isUserReady');
          debugPrint(
              '[FranchiseAppRootSplit] isFranchiseReady = $isFranchiseReady');
          debugPrint('[FranchiseAppRootSplit] user = $user');
          debugPrint(
              '[FranchiseAppRootSplit] user loading = ${userNotifier.loading}');
          debugPrint('[FranchiseAppRootSplit] franchiseId = $fid');
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // ========= FULL BUSINESS PROVIDER TREE =========
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AdminUserProvider()),
            ChangeNotifierProxyProvider<shared.FranchiseProvider,
                FranchiseSubscriptionNotifier>(
              create: (_) => FranchiseSubscriptionNotifier(
                service: FranchiseSubscriptionService(),
                franchiseId: '',
              ),
              update: (_, shared.FranchiseProvider, notifier) {
                final fid = shared.FranchiseProvider.franchiseId;
                final userNotifier =
                    Provider.of<UserProfileNotifier>(_, listen: false);
                final userRoles = userNotifier.user?.roles ?? [];

                notifier ??= FranchiseSubscriptionNotifier(
                  service: FranchiseSubscriptionService(),
                  franchiseId: fid,
                );

                notifier.setUserRoles(userRoles);

                if (shared.FranchiseProvider.hasValidFranchise &&
                    fid.isNotEmpty &&
                    fid != notifier.franchiseId) {
                  notifier.updateFranchiseId(fid);
                }

                return notifier;
              },
            ),
            ChangeNotifierProvider(
                create: (_) => PlatformPlanSelectionProvider()),
            // FirestoreService is provided at the root level above.
            ChangeNotifierProxyProvider2<shared.FranchiseProvider, shared.FirestoreService,
                FranchiseInfoProvider>(
              create: (_) => FranchiseInfoProvider(
                firestore: Provider.of<shared.FirestoreService>(_, listen: false),
                shared.FranchiseProvider:
                    Provider.of<shared.FranchiseProvider>(_, listen: false),
              ),
              update: (_, shared.FranchiseProvider, firestoreService, previous) {
                final provider = previous ??
                    FranchiseInfoProvider(
                      firestore: firestoreService,
                      shared.FranchiseProvider: shared.FranchiseProvider,
                    );
                provider.loadFranchiseInfo();
                return provider;
              },
            ),
            ChangeNotifierProxyProvider2<shared.FranchiseProvider, shared.FirestoreService,
                FranchiseFeatureProvider>(
              create: (_) => FranchiseFeatureProvider(
                service: FranchiseFeatureService(),
                franchiseId: '',
              ),
              update: (_, shared.FranchiseProvider, firestoreService, previous) {
                final fid = shared.FranchiseProvider.franchiseId;
                if (!shared.FranchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ??
                    FranchiseFeatureProvider(
                      service: FranchiseFeatureService(),
                      franchiseId: fid,
                    );
                if (fid.isNotEmpty && fid != provider.currentFranchiseId) {
                  provider.setFranchiseId(fid);
                }
                return provider;
              },
            ),
            ChangeNotifierProxyProvider2<FirestoreService, shared.FranchiseProvider,
                OnboardingProgressProvider>(
              create: (_) => OnboardingProgressProvider(
                firestore: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseId: '',
              ),
              update: (_, firestoreService, shared.FranchiseProvider, previous) {
                final fid = shared.FranchiseProvider.franchiseId ?? '';
                final provider = previous ??
                    OnboardingProgressProvider(
                      firestore: firestoreService,
                      franchiseId: fid,
                    );
                if (fid.isNotEmpty && fid != provider.franchiseId) {
                  return OnboardingProgressProvider(
                    firestore: firestoreService,
                    franchiseId: fid,
                  );
                }
                return provider;
              },
            ),
            ChangeNotifierProxyProvider2<FirestoreService,
                FranchiseInfoProvider, IngredientMetadataProvider>(
              create: (_) => IngredientMetadataProvider(
                firestoreService:
                    Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseId: '',
              ),
              update: (_, firestore, franchiseInfo, previous) {
                final franchiseId = franchiseInfo.franchise?.id ?? '';
                final provider = previous ??
                    IngredientMetadataProvider(
                      firestoreService: firestore,
                      franchiseId: franchiseId,
                    );
                if (franchiseId.isNotEmpty &&
                    franchiseId != provider.franchiseId &&
                    franchiseId != 'unknown') {
                  return IngredientMetadataProvider(
                    firestoreService: firestore,
                    franchiseId: franchiseId,
                  )..load();
                }
                return provider;
              },
            ),
            ChangeNotifierProxyProvider2<FirestoreService, shared.FranchiseProvider,
                CategoryProvider>(
              create: (_) => CategoryProvider(
                firestore: Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseId: '',
              ),
              update: (_, firestore, shared.FranchiseProvider, previous) {
                final fid = shared.FranchiseProvider.franchiseId;
                if (!shared.FranchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ??
                    CategoryProvider(
                      firestore: firestore,
                      franchiseId: fid,
                    );
                if (fid.isNotEmpty && fid != provider.franchiseId) {
                  provider.updateFranchiseId(fid);
                }
                return provider;
              },
            ),
            ChangeNotifierProxyProvider3<shared.FirestoreService, shared.FranchiseProvider,
                FranchiseInfoProvider, MenuItemProvider>(
              create: (_) => MenuItemProvider(
                firestoreService:
                    Provider.of<shared.FirestoreService>(_, listen: false),
                franchiseInfoProvider:
                    Provider.of<FranchiseInfoProvider>(_, listen: false),
              ),
              update: (_, firestoreService, shared.FranchiseProvider,
                  franchiseInfoProvider, previous) {
                final fid = shared.FranchiseProvider.franchiseId;
                if (!shared.FranchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ??
                    MenuItemProvider(
                      firestoreService: firestoreService,
                      franchiseInfoProvider: franchiseInfoProvider,
                    );
                provider.franchiseInfoProvider = franchiseInfoProvider;
                if (fid.isNotEmpty && fid != 'unknown') {
                  provider.loadMenuItems(fid);
                }
                return provider;
              },
            ),
            ChangeNotifierProxyProvider2<FirestoreService, shared.FranchiseProvider,
                IngredientTypeProvider>(
              create: (_) => IngredientTypeProvider(),
              update: (_, firestoreService, shared.FranchiseProvider, previous) {
                final fid = shared.FranchiseProvider.franchiseId;
                if (!shared.FranchiseProvider.hasValidFranchise) return previous!;
                final provider = previous ?? IngredientTypeProvider();
                if (fid.isNotEmpty && fid != provider.franchiseId) {
                  provider.loadIngredientTypes(fid);
                }
                return provider;
              },
            ),
            Provider(create: (_) => AnalyticsService()),
            Provider<AuditLogService>.value(value: AuditLogService()),
            StreamProvider<fb_auth.User?>.value(
              value: fb_auth.FirebaseAuth.instance.authStateChanges(),
              initialData: null,
            ),
            ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
            ChangeNotifierProvider(
              create: (_) => FranchiseeInvitationProvider(
                service: FranchiseeInvitationService(
                  firestoreService:
                      Provider.of<shared.FirestoreService>(_, listen: false),
                ),
              ),
            ),
            ChangeNotifierProvider(create: (_) => RestaurantTypeProvider()),
          ],
          child: FranchiseAuthenticatedRoot(
            key: ValueKey(firebaseUser?.uid),
          ),
        );
      },
    );
  }
}

/// Authenticated app root and routing logic, with full debug tracing and robust provider effect
class FranchiseAuthenticatedRoot extends StatefulWidget {
  const FranchiseAuthenticatedRoot({super.key});

  @override
  State<FranchiseAuthenticatedRoot> createState() =>
      _FranchiseAuthenticatedRootState();
}

class _FranchiseAuthenticatedRootState
    extends State<FranchiseAuthenticatedRoot> {
  String? _lastUid;
  bool _initializingUser = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final fbUser = Provider.of<fb_auth.User?>(context, listen: false);
      final adminUserProvider =
          Provider.of<AdminUserProvider>(context, listen: false);
      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);
      final shared.FranchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);

      if (fbUser == null) {
        debugPrint('[FranchiseAuthenticatedRoot] âŒ No Firebase user.');
        return;
      }

      if (fbUser.uid == _lastUid) {
        debugPrint(
            '[FranchiseAuthenticatedRoot] ðŸ” UID unchanged (${fbUser.uid}), skipping listenToAdminUser.');
        return;
      }

      if (_initializingUser) {
        debugPrint(
            '[FranchiseAuthenticatedRoot] â³ Already initializing user, skipping.');
        return;
      }

      _initializingUser = true;
      _lastUid = fbUser.uid;

      debugPrint(
          '[FranchiseAuthenticatedRoot] âœ… Detected Firebase UID: ${fbUser.uid}');
      debugPrint(
          '[FranchiseAuthenticatedRoot] â¬ Calling listenToAdminUser (post-frame)...');

      adminUserProvider.listenToAdminUser(
        firestoreService,
        fbUser.uid,
        shared.FranchiseProvider,
      );

      _initializingUser = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = Provider.of<fb_auth.User?>(context);
    final adminUserProvider = Provider.of<AdminUserProvider>(context);

    print('[FranchiseAuthenticatedRoot] ðŸ”„ build() called');
    print('[DEBUG] fbUser: ${fbUser?.email} (${fbUser?.uid})');
    print('[DEBUG] AdminUser loading: ${adminUserProvider.loading}');
    print('[DEBUG] AdminUser loaded: ${adminUserProvider.user}');

    // Still loading user profile
    if (adminUserProvider.loading || adminUserProvider.user == null) {
      print(
          '[FranchiseAuthenticatedRoot] â³ Waiting on admin user profile...');
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Roles missing
    if (adminUserProvider.user?.roles == null) {
      print(
          '[FranchiseAuthenticatedRoot] âŒ User roles missing. Unauthorized.');
      debugPrint(
          'AppLocalizations.supportedLocales: ${AppLocalizations.supportedLocales}');

      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Unauthorized')),
          body: const Center(
            child: Text(
                'You are not authorized to access this portal.\n[DEBUG] No roles property.'),
          ),
        ),
      );
    }

    // âœ… Build full app
    print(
        '[FranchiseAuthenticatedRoot] âœ… App user loaded. Proceeding with router...');
    print(
        '[FranchiseAuthenticatedRoot] âœ… All data ready. Building MaterialApp with router...');
    print('[DEBUG] Roles: ${adminUserProvider.user?.roles}');
    return Builder(
      builder: (ctx) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Franchise Admin Portal',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: safeThemeMode(ctx),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // initialRoute: '/post-login-gate',
        onGenerateRoute: (RouteSettings settings) {
          print('[DEBUG][onGenerateRoute] Route name: ${settings.name}');

          // DEFENSIVE GATE: Block routing until user/provider is loaded!
          final adminUserProvider =
              Provider.of<AdminUserProvider>(ctx, listen: false);
          if (adminUserProvider.loading || adminUserProvider.user == null) {
            print(
                '[main.dart] User or provider not loaded, showing loading spinner and blocking route processing.');
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          try {
            print('-----------------------------------------------------');
            print('[DEBUG][onGenerateRoute] Route name: ${settings.name}');
            final uri = Uri.parse(settings.name ?? '/');
            final user = adminUserProvider.user;

            if (user == null) {
              print('[main.dart] User is null. Blocking routing.');
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }
            print('[DEBUG][onGenerateRoute] User roles: ${user.roles}');
            print('[DEBUG][onGenerateRoute] User object: $user');
            print(
                '[DEBUG][onGenerateRoute] Route arguments: ${settings.arguments}');
            if (user.isActive == false) {
              print(
                  '[main.dart] User is suspended or inactive. Redirecting to /unauthorized');
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(
                    child: Text(
                        'Your account is currently suspended or inactive.'),
                  ),
                ),
              );
            }

            // Role-based root/landing routing
            if (uri.path == '/' ||
                uri.path == '/landing' ||
                settings.name == null) {
              print('[DEBUG][onGenerateRoute] Root/landing route hit.');

              if (user.roles.contains('platform_owner')) {
                print('[main.dart] Routing to PlatformOwnerDashboardScreen');
                return MaterialPageRoute(
                  builder: (context) => const PlatformOwnerDashboardScreen(
                    currentsource: '/platform-owner/dashboard' /* was screen, Phase 4 fix */,
                  ),
                );
              }

              if (user.roles.contains('hq_owner')) {
                print('[main.dart] Routing to OwnerHQDashboardScreen');
                return MaterialPageRoute(
                  builder: (context) => const FranchiseGate(
                    child: OwnerHQDashboardScreen(
                      currentsource: '/hq-owner/dashboard' /* was screen, Phase 4 fix */,
                    ),
                  ),
                );
              }

              if (user.roles.contains('developer')) {
                print('[main.dart] Routing to DeveloperDashboardScreen');
                return MaterialPageRoute(
                  builder: (context) => const FranchiseGate(
                    child: DeveloperDashboardScreen(
                      currentsource: '/developer/dashboard' /* was screen, Phase 4 fix */,
                    ),
                  ),
                );
              }

              print('[main.dart] Routing to AdminDashboardScreen (fallback)');
              return MaterialPageRoute(
                builder: (context) => const FranchiseGate(
                  child: AdminDashboardScreen(
                    currentsource: '/admin/dashboard' /* was screen, Phase 4 fix */,
                  ),
                ),
              );
            }

            // ======= Standard Authenticated Routes =======
            if (uri.path == '/post-login-gate') {
              print('[main.dart] Routing to ProfileGateScreen');
              return MaterialPageRoute(
                  builder: (context) => const ProfileGateScreen());
            }
            if (uri.path == '/admin/dashboard') {
              final sectionKey = uri.queryParameters['section'];
              return MaterialPageRoute(
                builder: (context) => FranchiseGate(
                  child: AdminDashboardScreen(
                      initialSectionKey: sectionKey ?? 'dashboardHome'),
                ),
              );
            }
            if (uri.path == '/developer/dashboard') {
              print('[main.dart] Routing to DeveloperDashboardScreen');
              return MaterialPageRoute(
                builder: (context) => const FranchiseGate(
                  child: DeveloperDashboardScreen(
                      currentsource: '/developer/dashboard' /* was screen, Phase 4 fix */),
                ),
              );
            }

            if (uri.path == '/developer/select-franchise') {
              print('[main.dart] Routing to FranchiseSelectorScreen');
              return MaterialPageRoute(
                  builder: (context) => const FranchiseSelectorScreen());
            }
            if (uri.path == '/hq-owner/dashboard') {
              print('[main.dart] Routing to OwnerHQDashboardScreen');
              return MaterialPageRoute(
                builder: (context) => const FranchiseGate(
                  child: OwnerHQDashboardScreen(
                      currentsource: '/hq-owner/dashboard' /* was screen, Phase 4 fix */),
                ),
              );
            }
            if (uri.path == '/platform-owner/dashboard') {
              print('[main.dart] Routing to PlatformOwnerDashboardScreen');
              return MaterialPageRoute(
                builder: (context) => const PlatformOwnerDashboardScreen(
                    currentsource: '/platform-owner/dashboard' /* was screen, Phase 4 fix */),
              );
            }
            if (uri.path == '/platform/plans') {
              print('[main.dart] Routing to FullPlatformPlansScreen');
              return MaterialPageRoute(
                builder: (context) => const FullPlatformPlansScreen(),
              );
            }
            if (uri.path == '/platform/subscriptions') {
              print(
                  '[main.dart] Routing to FullFranchiseSubscriptionListScreen');
              return MaterialPageRoute(
                builder: (context) =>
                    const FullFranchiseSubscriptionListScreen(),
              );
            }
            if (uri.path == '/developer/tools/billing') {
              print('[main.dart] Routing to BillingSubscriptionToolsScreen');
              return MaterialPageRoute(
                builder: (context) => const BillingSubscriptionToolsScreen(),
              );
            }

            if (uri.path == '/developer/tools/subscriptions') {
              print('[main.dart] Routing to SubscriptionDevToolsScreen');
              return MaterialPageRoute(
                builder: (context) => const SubscriptionDevToolsScreen(),
              );
            }

            if (uri.path == '/unauthorized') {
              print('[main.dart] Routing to Unauthorized');
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Unauthorized')),
                  body:
                      const Center(child: Text('Your account is not active.')),
                ),
              );
            }
            if (uri.path == '/alerts') {
              print('[main.dart] Routing to AlertListScreen');
              final franchiseId = user.defaultFranchise ??
                  ((user.franchiseIds.isNotEmpty)
                      ? user.franchiseIds.first
                      : '');
              print(
                  '[DEBUG][onGenerateRoute] AlertListScreen franchiseId: $franchiseId');
              return MaterialPageRoute(
                builder: (context) {
                  return AlertListScreen(
                    franchiseId: franchiseId,
                    developerMode: user.isDeveloper ?? false,
                  );
                },
              );
            }
            if (uri.path == '/hq/invoices') {
              print('[main.dart] Routing to InvoiceListScreen');
              return MaterialPageRoute(
                  builder: (context) => const InvoiceListScreen());
            }
            if (uri.path == '/hq/invoice_detail') {
              final args = settings.arguments as String?;
              print(
                  '[main.dart] Routing to InvoiceDetailScreen, invoiceId=$args');
              return MaterialPageRoute(
                  builder: (context) =>
                      InvoiceDetailScreen(invoiceId: args ?? ''));
            }
            if (uri.path == '/hq/payouts') {
              print('[main.dart] Routing to PayoutListScreen');
              return MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider(
                  create: (context) => PayoutFilterProvider(),
                  child: const PayoutListScreen(),
                ),
              );
            }
            if (uri.path == '/profile') {
              print('[main.dart] Routing to UniversalProfileScreen');
              return MaterialPageRoute(
                  builder: (context) => const UniversalProfileScreen());
            }
            if (uri.path == '/onboarding/menu') {
              return MaterialPageRoute(
                builder: (context) => FranchiseGate(
                  child:
                      AdminDashboardScreen(initialSectionKey: 'onboardingMenu'),
                ),
              );
            }
            // DASHBOARD route handling (supports with/without ?section= param)
            if (uri.path == '/dashboard') {
              final sectionParam = uri.queryParameters['section'];

              // Default to first sidebar section if no param
              final targetSectionKey = sectionParam?.isNotEmpty == true
                  ? sectionParam!
                  : getSidebarSections().first.key;

              print('[ROUTER] ðŸ“Œ Requested /dashboard');
              print('[ROUTER] ðŸ”‘ Target section key: "$targetSectionKey"');

              final sectionExists =
                  sectionRegistry.any((s) => s.key == targetSectionKey);
              if (!sectionExists) {
                print('[ROUTER] âŒ No matching section found, using default.');
              }

              return MaterialPageRoute(
                builder: (context) {
                  return FranchiseGate(
                    child: Builder(
                      builder: (ctx) {
                        final shared.FranchiseProvider =
                            Provider.of<shared.FranchiseProvider>(ctx, listen: false);
                        final franchiseId = shared.FranchiseProvider.franchiseId;

                        print('[ROUTER] ðŸ” franchiseId = "$franchiseId"');

                        if (franchiseId.isEmpty || franchiseId == 'unknown') {
                          print(
                              '[ROUTER] âš ï¸ Franchise ID loading â€” showing spinner.');
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        // Prerequisite data checks for onboarding sections
                        // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        return FutureBuilder<void>(
                          future: () async {
                            try {
                              if (targetSectionKey == 'onboardingIngredients') {
                                print(
                                    '[ROUTER] ðŸ“¦ Preloading data for Ingredients...');

                                final ingredientTypesProvider =
                                    ctx.read<IngredientTypeProvider>();
                                final ingredientsProvider =
                                    ctx.read<IngredientMetadataProvider>();

                                // Ingredient Types preload
                                if (ingredientTypesProvider.types.isEmpty) {
                                  print(
                                      '[ROUTER]    âž¤ Loading Ingredient Types...');
                                  await ingredientTypesProvider
                                      .loadTypes(franchiseId);
                                  print(
                                      '[ROUTER]    âœ” Loaded Ingredient Types: count=${ingredientTypesProvider.types.length}');
                                } else {
                                  print(
                                      '[ROUTER]    âœ” Ingredient Types already loaded: count=${ingredientTypesProvider.types.length}');
                                }

                                // Ingredient Metadata preload
                                if (!ingredientsProvider.isInitialized) {
                                  print(
                                      '[ROUTER]    âž¤ Loading Ingredients...');
                                  await ingredientsProvider.load();
                                  print(
                                      '[ROUTER]    âœ” Loaded Ingredients: count=${ingredientsProvider.ingredients.length}');
                                } else {
                                  print(
                                      '[ROUTER]    âœ” Ingredients already loaded: count=${ingredientsProvider.ingredients.length}');
                                }
                              } else if (targetSectionKey ==
                                  'onboardingIngredientTypes') {
                                print(
                                    '[ROUTER] ðŸ“¦ Preloading data for Ingredient Types only...');

                                final ingredientTypesProvider =
                                    ctx.read<IngredientTypeProvider>();

                                if (ingredientTypesProvider.types.isEmpty) {
                                  print(
                                      '[ROUTER]    âž¤ Loading Ingredient Types...');
                                  await ingredientTypesProvider
                                      .loadTypes(franchiseId);
                                  print(
                                      '[ROUTER]    âœ” Loaded Ingredient Types: count=${ingredientTypesProvider.types.length}');
                                } else {
                                  print(
                                      '[ROUTER]    âœ” Ingredient Types already loaded: count=${ingredientTypesProvider.types.length}');
                                }
                              }
                            } catch (e, st) {
                              print(
                                  '[ROUTER][ERROR] âš  Failed while preloading prerequisites.');
                              print('    Exception: $e');
                              print('    Stacktrace: $st');
                            }
                          }(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Scaffold(
                                body:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }

                            // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                            // Navigate to AdminDashboardScreen
                            // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                            print(
                                '[ROUTER] âœ… Navigating to AdminDashboardScreen with section "$targetSectionKey"');
                            return AdminDashboardScreen(
                              key: ValueKey(
                                  'AdminDashboardsource: $targetSectionKey' /* was screen, Phase 4 fix */),
                              initialSectionKey: targetSectionKey,
                            );
                          },
                        );
                      },
                    ),
                  );
                },
                settings: settings,
              );
            }

            if (uri.path == '/onboarding/ingredient-types') {
              return MaterialPageRoute(
                builder: (context) => const IngredientTypeManagementScreen(),
              );
            }
            if (uri.path == '/onboarding/categories') {
              return MaterialPageRoute(
                builder: (_) => const OnboardingCategoriesScreen(),
              );
            }
            if (uri.path == '/onboarding/menu_items') {
              return MaterialPageRoute(
                builder: (_) => const OnboardingMenuItemsScreen(),
              );
            }
            if (uri.path == '/onboarding/feature_setup') {
              return MaterialPageRoute(
                builder: (_) => const OnboardingFeatureSetupScreen(),
                settings: settings, // â† passes .arguments
              );
            }
            if (uri.path == '/onboarding/review') {
              return MaterialPageRoute(
                builder: (context) =>
                    ChangeNotifierProvider<OnboardingReviewProvider>(
                  create: (context) => OnboardingReviewProvider(
                    franchiseFeatureProvider:
                        Provider.of<FranchiseFeatureProvider>(context,
                            listen: false),
                    ingredientTypeProvider: Provider.of<IngredientTypeProvider>(
                        context,
                        listen: false),
                    ingredientMetadataProvider:
                        Provider.of<IngredientMetadataProvider>(context,
                            listen: false),
                    categoryProvider:
                        Provider.of<CategoryProvider>(context, listen: false),
                    menuItemProvider:
                        Provider.of<MenuItemProvider>(context, listen: false),
                    firestoreService:
                        Provider.of<shared.FirestoreService>(context, listen: false),
                    auditLogService:
                        Provider.of<AuditLogService>(context, listen: false),
                  ),
                  child:
                      OnboardingReviewScreen(), // <-- Make this widget "dumb" (stateless or stateful)
                ),
              );
            }
            if (uri.path == '/invite-accept') {
              final args = settings.arguments as Map?;
              final token = args?['token'] as String?;
              print('[main.dart] Routing to InviteAcceptScreen, token=$token');
              return MaterialPageRoute(
                  builder: (context) => InviteAcceptScreen(inviteToken: token));
            }
            if (uri.path == '/franchise-onboarding') {
              final args = settings.arguments as Map?;
              String? token = args?['token'] as String?;
              if (token == null || token.isEmpty) {
                // Try to get from AuthService
                token = Provider.of<AuthService>(context, listen: false)
                    .getInviteToken();
                print('[main.dart] Fetched token from AuthService: $token');
              }
              print(
                  '[main.dart] Routing to FranchiseOnboardingScreen, token=$token');
              if (token == null || token.isEmpty) {
                print(
                    '[main.dart] FranchiseOnboardingsource: Invalid or missing token!' /* was screen, Phase 4 fix */);
                return MaterialPageRoute(
                  builder: (context) => Scaffold(
                    appBar: AppBar(title: const Text('Invalid Invite')),
                    body: const Center(
                        child: Text('Invalid or missing invitation token.')),
                  ),
                );
              }
              return MaterialPageRoute(
                builder: (context) =>
                    FranchiseOnboardingScreen(inviteToken: token),
              );
            }
            if (uri.path == '/hq-owner/available-plans') {
              print(
                  '[main.dart] Routing to AvailablePlatformPlansScreen (HQ Owner)');
              return MaterialPageRoute(
                builder: (context) => const AvailablePlatformPlansScreen(),
              );
            }
            print('[main.dart] Routing to fallback LandingPage');
            return MaterialPageRoute(builder: (context) => const LandingPage());
          } catch (e, stack) {
            print('[DEBUG][onGenerateRoute] Caught error: $e');
            print(stack);
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Fatal Routing Error')),
                body: SingleChildScrollView(
                  child: Text(
                    'Exception: $e\n$stack',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

// ===== THEME DEFINITIONS =====

final ThemeData _lightTheme = ThemeData(
  fontFamily: DesignTokens.fontFamily,
  primaryColor: DesignTokens.primaryColor,
  scaffoldBackgroundColor: DesignTokens.backgroundColor,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: DesignTokens.primaryColor,
    onPrimary: DesignTokens.foregroundColor,
    secondary: DesignTokens.secondaryColor,
    onSecondary: DesignTokens.foregroundColor,
    error: DesignTokens.errorColor,
    onError: DesignTokens.errorTextColor,
    background: DesignTokens.backgroundColor,
    onBackground: DesignTokens.textColor,
    surface: DesignTokens.surfaceColor,
    onSurface: DesignTokens.textColor,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: DesignTokens.appBarBackgroundColor,
    foregroundColor: DesignTokens.appBarForegroundColor,
    iconTheme: IconThemeData(color: DesignTokens.appBarIconColor),
    elevation: DesignTokens.appBarElevation,
    titleTextStyle: TextStyle(
      fontFamily: DesignTokens.appBarFontFamily,
      fontSize: DesignTokens.appBarTitleFontSize,
      fontWeight: DesignTokens.appBarTitleFontWeight,
      color: DesignTokens.appBarForegroundColor,
    ),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminBodyFontSize,
      color: DesignTokens.textColor,
    ),
    titleLarge: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminTitleFontSize,
      fontWeight: DesignTokens.titleFontWeight,
      color: DesignTokens.textColor,
    ),
    titleMedium: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminCaptionFontSize,
      color: DesignTokens.secondaryTextColor,
    ),
  ),
  cardTheme: CardTheme(
    color: DesignTokens.surfaceColor,
    elevation: DesignTokens.adminCardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
    ),
    margin: EdgeInsets.all(DesignTokens.adminCardSpacing),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DesignTokens.primaryColor,
      foregroundColor: DesignTokens.foregroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminButtonRadius),
      ),
      elevation: DesignTokens.adminButtonElevation,
      textStyle: TextStyle(
        fontSize: DesignTokens.adminButtonFontSize,
        fontFamily: DesignTokens.fontFamily,
        fontWeight: DesignTokens.titleFontWeight,
      ),
      padding: DesignTokens.buttonPadding,
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: DesignTokens.surfaceColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
    ),
    elevation: DesignTokens.adminDialogElevation,
    titleTextStyle: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminTitleFontSize,
      fontWeight: FontWeight.bold,
      color: DesignTokens.textColor,
    ),
    contentTextStyle: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminBodyFontSize,
      color: DesignTokens.textColor,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.formFieldRadius),
    ),
  ),
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: DesignTokens.fontFamily,
  primaryColor: DesignTokens.primaryColor,
  scaffoldBackgroundColor: DesignTokens.backgroundColorDark,
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: DesignTokens.primaryColor,
    onPrimary: DesignTokens.foregroundColorDark,
    secondary: DesignTokens.secondaryColor,
    onSecondary: DesignTokens.foregroundColorDark,
    error: DesignTokens.errorColor,
    onError: DesignTokens.errorTextColor,
    background: DesignTokens.backgroundColorDark,
    onBackground: DesignTokens.textColorDark,
    surface: DesignTokens.surfaceColorDark,
    onSurface: DesignTokens.textColorDark,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: DesignTokens.appBarBackgroundColorDark,
    foregroundColor: DesignTokens.appBarForegroundColorDark,
    iconTheme: IconThemeData(color: DesignTokens.appBarForegroundColorDark),
    elevation: DesignTokens.appBarElevation,
    titleTextStyle: TextStyle(
      fontFamily: DesignTokens.appBarFontFamily,
      fontSize: DesignTokens.appBarTitleFontSize,
      fontWeight: DesignTokens.appBarTitleFontWeight,
      color: DesignTokens.appBarForegroundColorDark,
    ),
  ),
  drawerTheme: DrawerThemeData(
    backgroundColor: DesignTokens.backgroundColorDark,
    scrimColor: Colors.black.withOpacity(0.5),
  ),
  textTheme: TextTheme(
    bodyMedium: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminBodyFontSize,
      color: DesignTokens.textColorDark,
    ),
    titleLarge: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminTitleFontSize,
      fontWeight: DesignTokens.titleFontWeight,
      color: DesignTokens.textColorDark,
    ),
    titleMedium: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminCaptionFontSize,
      color: DesignTokens.secondaryTextColor,
    ),
  ),
  cardTheme: CardTheme(
    color: DesignTokens.surfaceColorDark,
    elevation: DesignTokens.adminCardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
    ),
    margin: EdgeInsets.all(DesignTokens.adminCardSpacing),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: DesignTokens.primaryColor,
      foregroundColor: DesignTokens.foregroundColorDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminButtonRadius),
      ),
      elevation: DesignTokens.adminButtonElevation,
      textStyle: TextStyle(
        fontSize: DesignTokens.adminButtonFontSize,
        fontFamily: DesignTokens.fontFamily,
        fontWeight: DesignTokens.titleFontWeight,
      ),
      padding: DesignTokens.buttonPadding,
    ),
  ),
  dialogTheme: DialogTheme(
    backgroundColor: DesignTokens.surfaceColorDark,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
    ),
    elevation: DesignTokens.adminDialogElevation,
    titleTextStyle: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminTitleFontSize,
      fontWeight: FontWeight.bold,
      color: DesignTokens.textColorDark,
    ),
    contentTextStyle: TextStyle(
      fontFamily: DesignTokens.fontFamily,
      fontSize: DesignTokens.adminBodyFontSize,
      color: DesignTokens.textColorDark,
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: TextStyle(color: DesignTokens.hintTextColorDark),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(DesignTokens.formFieldRadius),
    ),
  ),
  dividerColor: DesignTokens.dividerColorDark,
  iconTheme: IconThemeData(color: DesignTokens.textColorDark),
);



