import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// === SHARED_CORE BARREL ===
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
import 'package:franchise_admin_portal/core/providers/category_provider_impl.dart';
import 'package:franchise_admin_portal/core/providers/onboarding_review_provider_impl.dart';
import 'package:franchise_admin_portal/core/services/franchise_subscription_service_impl.dart';
import 'package:franchise_admin_portal/core/services/franchise_feature_service_impl.dart';
import 'package:franchise_admin_portal/core/services/analytics_service_impl.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service_impl.dart';
import 'package:franchise_admin_portal/core/services/auth_service_impl.dart';
import 'package:franchise_admin_portal/core/services/invoice_service_impl.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';
import 'package:franchise_admin_portal/core/services/firebase_storage_service_impl.dart'; // Adjust path if needed
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
import 'package:franchise_admin_portal/admin/platform_owner/platform_owner_dashboard_screen.dart';
import 'package:franchise_admin_portal/widgets/profile_gate_screen.dart';
import 'package:franchise_admin_portal/widgets/auth_profile_listener.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart'; // Web-specific DesignTokens (returns Color)

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Map<String, dynamic> getInitialUnauthRoute() {
  final currentUser = fb_auth.FirebaseAuth.instance.currentUser;
  if (currentUser != null) {
    shared.ErrorLogger.log(
      message:
          '[getInitialUnauthRoute] User is signed in. Skipping invite-accept route.',
      source: 'main.dart',
      severity: 'info',
    );
    return {'route': '/', 'token': ''};
  }

  final hash = Uri.base.fragment;
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
          message:
              '[main.dart][getInitialUnauthRoute] Error parsing query string: $e',
          stack: stack.toString(),
          source: 'main.dart',
          severity: 'error',
        );
      }
    }
    return {'route': '/invite-accept', 'token': token};
  }

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
      contextData: {'library': details.library},
    );
  };

  Provider.debugCheckInvalidValueType = null;

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);
    await fb_auth.FirebaseAuth.instance
        .setPersistence(fb_auth.Persistence.LOCAL);

    final storage = AppLocalStorage();
    final authService = AuthServiceImpl();
    final firestoreService = shared.FirestoreServiceImpl();

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
          Provider<shared.FranchiseProvider>(
              create: (_) => shared.FranchiseProvider(storage)),
          Provider<shared.AuthService>.value(value: authService),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<shared.FirestoreService>.value(value: firestoreService),
          Provider<shared.AnalyticsService>.value(
              value: shared.AnalyticsServiceImpl()),

          // === Subscription (outer for early Consumer<User?> in auth gate) ===
          ChangeNotifierProxyProvider<shared.FranchiseProvider,
              FranchiseSubscriptionProviderImpl>(
            create: (_) => FranchiseSubscriptionProviderImpl(
                service: FranchiseSubscriptionServiceImpl(), franchiseId: ''),
            update: (_, fp, prev) {
              final notifier = prev ??
                  FranchiseSubscriptionProviderImpl(
                      service: FranchiseSubscriptionServiceImpl(),
                      franchiseId: fp.franchiseId ?? '');
              if (fp.franchiseId != null &&
                  fp.franchiseId != notifier.franchiseId)
                notifier.updateFranchiseId(fp.franchiseId!);
              return notifier;
            },
          ),
          Provider<shared.FranchiseSubscriptionProvider>.value(
              value: FranchiseSubscriptionProviderImpl(
                  service: FranchiseSubscriptionServiceImpl(),
                  franchiseId: '')),
          Provider<FranchiseSubscriptionProviderImpl>.value(
              value: FranchiseSubscriptionProviderImpl(
                  service: FranchiseSubscriptionServiceImpl(),
                  franchiseId: '')),

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
        severity: 'fatal');
  });
}

class FranchiseAuthenticatedRoot extends StatefulWidget {
  const FranchiseAuthenticatedRoot({super.key});

  @override
  State<FranchiseAuthenticatedRoot> createState() =>
      _FranchiseAuthenticatedRootState();
}

class _FranchiseAuthenticatedRootState
    extends State<FranchiseAuthenticatedRoot> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final firebaseUser = Provider.of<fb_auth.User?>(context, listen: false);
      if (firebaseUser == null) {
        shared.ErrorLogger.log(
          message: 'FranchiseAuthenticatedRoot: firebaseUser still null',
          source: 'main.dart',
          severity: 'error',
        );
        return;
      }

      debugPrint(
          '[FranchiseAuthenticatedRoot] Handoff STARTED for uid: ${firebaseUser.uid}');

      final userNotifier =
          Provider.of<UserProfileNotifier>(context, listen: false);
      final adminProvider =
          Provider.of<shared.AdminUserProvider>(context, listen: false);
      final franchiseProvider =
          Provider.of<shared.FranchiseProvider>(context, listen: false);
      // Mirrors mobile UiConfig.setFranchiseProvider and enables DesignTokens live getters.
      DesignTokens.setFranchiseProvider(franchiseProvider);
      final firestoreService =
          Provider.of<shared.FirestoreService>(context, listen: false);

      userNotifier.listenToUser(firebaseUser.uid);
      adminProvider.listenToAdminUser(
          firestoreService, firebaseUser.uid, franchiseProvider);
      // Force franchise context initialization
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final franchiseProvider =
            Provider.of<shared.FranchiseProvider>(context, listen: false);
        final adminUser = adminProvider.user;

        if (adminUser != null) {
          await franchiseProvider.initializeWithUser(adminUser);
          // Extra force for dependent providers
          franchiseProvider.forceRefreshFranchiseId(
              adminUser.defaultFranchise ??
                  adminUser.franchiseIds.firstOrNull ??
                  'test');

          try {
            final currentFranchiseId = franchiseProvider.currentFranchiseId;
            if (currentFranchiseId.isNotEmpty &&
                currentFranchiseId != 'unknown') {
              final docSnapshot = await FirebaseFirestore.instance
                  .collection('franchises')
                  .doc(currentFranchiseId)
                  .get();
              if (docSnapshot.exists) {
                final brandingData = docSnapshot.data() as Map<String, dynamic>;
                franchiseProvider.setBrandingFromFranchiseDoc(brandingData);
              }
            }
          } catch (e) {
            // Silent failure
          }
        }
      });

      shared.ErrorLogger.log(
        message: 'FranchiseAuthenticatedRoot handoff SUCCESS',
        source: 'main.dart',
        severity: 'info',
        contextData: {'userId': firebaseUser.uid},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthProfileListener(
      child: Consumer<shared.AdminUserProvider>(
        builder: (context, adminUserProvider, _) {
          final user = adminUserProvider.user;
          debugPrint(
              '[FranchiseAuthenticatedRoot] Consumer rebuild - user: ${user?.id} roles: ${user?.roles}');

          if (user == null) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 24),
                      Text('Loading dashboard...'),
                    ],
                  ),
                ),
              ),
            );
          }

          Widget dashboard;
          if (user.roles?.contains(shared.User.rolePlatformOwner) ?? false) {
            dashboard = const PlatformOwnerDashboardScreen(
                currentScreen: 'platform-owner/dashboard');
          } else if (user.roles?.contains(shared.User.roleHqOwner) ?? false) {
            dashboard = const OwnerHQDashboardScreen(
                currentScreen: 'owner-hq/dashboard');
          } else if (user.roles?.contains(shared.User.roleDeveloper) ?? false) {
            dashboard = const DeveloperDashboardScreen(
                currentScreen: 'developer/dashboard');
          } else {
            dashboard = const AdminDashboardScreen();
          }

          return MaterialApp(
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
            home: dashboard,
            onGenerateRoute: (settings) {
              final name = settings.name?.toLowerCase() ?? '/';
              debugPrint('[onGenerateRoute] Requested: $name');

              // === NEW: Parse query param and pass initialSectionKey ===
              String? initialSectionKey;
              final uri = name.startsWith('/') ? Uri.parse(name) : null;
              if (uri?.queryParameters['section'] != null) {
                initialSectionKey = uri!.queryParameters['section'];
              }
              // === END NEW ===

              if (name.contains('hq-owner') || name.contains('hq')) {
                return MaterialPageRoute(
                    builder: (_) => const OwnerHQDashboardScreen(
                        currentScreen: 'owner-hq/dashboard'));
              }
              if (name.contains('admin')) {
                return MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen());
              }
              if (name.contains('platform-owner') ||
                  name.contains('platform')) {
                return MaterialPageRoute(
                    builder: (_) => const PlatformOwnerDashboardScreen(
                        currentScreen: 'platform-owner/dashboard'));
              }
              if (name.contains('developer')) {
                return MaterialPageRoute(
                    builder: (_) => const DeveloperDashboardScreen(
                        currentScreen: 'developer/dashboard'));
              }

              if (name.contains('onboarding') || initialSectionKey != null) {
                return MaterialPageRoute(
                  builder: (_) => AdminDashboardScreen(
                    initialSectionKey: initialSectionKey ?? 'onboardingMenu',
                  ),
                );
              }

              // Fallback
              return MaterialPageRoute(builder: (_) => dashboard);
            },
          );
        },
      ),
    );
  }
}

class FranchiseAppRootSplit extends StatelessWidget {
  const FranchiseAppRootSplit({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<fb_auth.User?>(
      builder: (context, firebaseUser, _) {
        // UNAUTHENTICATED
        if (firebaseUser == null) {
          return Builder(builder: (ctx) {
            final initial = getInitialUnauthRoute();
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
              initialRoute: initial['route'] as String,
              onGenerateRoute: (settings) {
                final path = Uri.parse(settings.name ?? '/').path;
                if (path == '/' || path == '/landing')
                  return MaterialPageRoute(builder: (_) => const LandingPage());
                if (path == '/sign-in')
                  return MaterialPageRoute(
                      builder: (_) => const SignInScreen());
                if (path == '/invite-accept') {
                  String? token =
                      (settings.arguments as Map?)?['token'] as String?;
                  return MaterialPageRoute(
                      builder: (_) => InviteAcceptScreen(inviteToken: token));
                }
                return MaterialPageRoute(builder: (_) => const LandingPage());
              },
            );
          });
        }

        // AUTHENTICATED - Force dashboard
        // AUTHENTICATED - Force dashboard
        // AUTHENTICATED - Force dashboard
        return MultiProvider(
          providers: [
            // === Core Providers ===
            ChangeNotifierProvider(create: (_) => shared.AdminUserProvider()),
            Provider<shared.InvoiceService>(
                create: (_) => InvoiceServiceImpl()),

            // === ADMIN FIRESTORE SERVICE ===
            Provider<shared.FirestoreService>(
                create: (_) => AdminFirestoreService()),

            // === SINGLE SOURCE OF TRUTH ===
            Provider<shared.FranchiseProvider>(
                create: (_) => shared.FranchiseProvider(AppLocalStorage())),

            // === Franchise Info ===
            ChangeNotifierProxyProvider2<shared.FranchiseProvider,
                shared.FirestoreService, FranchiseInfoProviderImpl>(
              create: (context) => FranchiseInfoProviderImpl(
                firestore: Provider.of<shared.FirestoreService>(context,
                    listen: false),
                franchiseProvider: Provider.of<shared.FranchiseProvider>(
                    context,
                    listen: false),
              ),
              update: (_, fp, fs, prev) => prev ??
                  FranchiseInfoProviderImpl(
                      firestore: fs, franchiseProvider: fp)
                ..loadFranchiseInfo(),
            ),

            // === Franchise Feature ===
            ChangeNotifierProxyProvider2<shared.FranchiseProvider,
                shared.FirestoreService, FranchiseFeatureProviderImpl>(
              create: (_) => FranchiseFeatureProviderImpl(
                  service: FranchiseFeatureServiceImpl(), franchiseId: ''),
              update: (_, fp, fs, prev) {
                final p = prev ??
                    FranchiseFeatureProviderImpl(
                        service: FranchiseFeatureServiceImpl(),
                        franchiseId: fp.franchiseId ?? '');
                if (fp.franchiseId != null) p.setFranchiseId(fp.franchiseId!);
                return p;
              },
            ),

            // === Abstract Alias for FranchiseFeatureProvider (fixes DashboardHomeScreen + FeatureGuard) ===
            ProxyProvider<FranchiseFeatureProviderImpl,
                shared.FranchiseFeatureProvider>(
              update: (_, impl, __) => impl,
            ),

            // === Onboarding Progress ===
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, OnboardingProgressProviderImpl>(
              create: (_) => OnboardingProgressProviderImpl(
                  firestore: shared.FirestoreServiceImpl(), franchiseId: ''),
              update: (_, fs, fp, prev) =>
                  prev ??
                  OnboardingProgressProviderImpl(
                      firestore: fs, franchiseId: fp.franchiseId ?? ''),
            ),

            // === Ingredient Metadata ===
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, IngredientMetadataProviderImpl>(
              create: (context) => IngredientMetadataProviderImpl(
                  firestore: Provider.of<shared.FirestoreService>(context,
                      listen: false),
                  franchiseId: ''),
              update: (_, fs, fp, prev) {
                final notifier = prev ??
                    IngredientMetadataProviderImpl(
                        firestore: fs, franchiseId: fp.franchiseId ?? '');
                if (fp.franchiseId != null && fp.franchiseId!.isNotEmpty)
                  notifier.updateFranchiseId(fp.franchiseId!);
                return notifier;
              },
            ),

            // === Category ===
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, CategoryProviderImpl>(
              create: (context) => CategoryProviderImpl(
                  firestore: AdminFirestoreService(), franchiseId: ''),
              update: (_, fs, fp, prev) =>
                  prev ??
                  CategoryProviderImpl(
                      firestore: fs, franchiseId: fp.franchiseId ?? ''),
            ),

            // === Ingredient Type ===
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, IngredientTypeProviderImpl>(
              create: (context) => IngredientTypeProviderImpl(
                  firestoreService: AdminFirestoreService()),
              update: (_, fs, fp, prev) {
                final notifier = prev ??
                    IngredientTypeProviderImpl(
                        firestoreService: AdminFirestoreService());
                if (fp.franchiseId != null && fp.franchiseId!.isNotEmpty)
                  notifier.franchiseId = fp.franchiseId!;
                return notifier;
              },
            ),

            // === Menu Item Provider ===
            ChangeNotifierProxyProvider6<
                shared.FirestoreService,
                shared.FranchiseProvider,
                FranchiseInfoProviderImpl,
                IngredientMetadataProviderImpl,
                CategoryProviderImpl,
                IngredientTypeProviderImpl,
                MenuItemProviderImpl>(
              create: (context) => MenuItemProviderImpl(
                firestoreService: Provider.of<shared.FirestoreService>(context,
                    listen: false),
                franchiseInfoProvider: Provider.of<FranchiseInfoProviderImpl>(
                    context,
                    listen: false),
                ingredientProvider: Provider.of<IngredientMetadataProviderImpl>(
                    context,
                    listen: false),
                categoryProvider:
                    Provider.of<CategoryProviderImpl>(context, listen: false),
                typeProvider: Provider.of<IngredientTypeProviderImpl>(context,
                    listen: false),
              ),
              update: (_, fs, fp, fip, ingP, catP, typeP, prev) =>
                  prev ??
                  MenuItemProviderImpl(
                    firestoreService: fs,
                    franchiseInfoProvider: fip,
                    ingredientProvider: ingP,
                    categoryProvider: catP,
                    typeProvider: typeP,
                  ),
            ),

            // === Firebase Storage ===
            Provider<shared.FirebaseStorageService>(
                create: (_) => FirebaseStorageServiceImpl()),

            // === Logging & Analytics ===
            Provider<shared.AuditLogService>.value(
                value: AuditLogServiceImpl()),
            Provider<shared.AnalyticsService>.value(
                value: shared.AnalyticsServiceImpl()),
          ],
          child: const FranchiseAuthenticatedRoot(),
        );
      },
    );
  }
}

// THEME (Fixed with DesignTokens)
final ThemeData _lightTheme = ThemeData(
  fontFamily: shared.DesignTokens.fontFamily,
  primaryColor: DesignTokens.primaryColor, // Use web DesignTokens (Color)
  scaffoldBackgroundColor: DesignTokens.backgroundColor,
  colorScheme: ColorScheme.light(
    primary: DesignTokens.primaryColor,
    onPrimary: Colors.white,
    secondary: DesignTokens.secondaryColor,
    onSecondary: Colors.white,
    error: DesignTokens.errorColor,
    onError: Colors.white,
    background: DesignTokens.backgroundColor,
    onBackground: DesignTokens.textColor,
    surface: DesignTokens.surfaceColor,
    onSurface: DesignTokens.textColor,
  ),
  appBarTheme: const AppBarTheme(elevation: 2),
);

final ThemeData _darkTheme = ThemeData(
  brightness: Brightness.dark,
  fontFamily: shared.DesignTokens.fontFamily,
  primaryColor: DesignTokens.primaryColor,
  scaffoldBackgroundColor: DesignTokens.backgroundColorDark,
  colorScheme: ColorScheme.dark(
    primary: DesignTokens.primaryColor,
    onPrimary: Colors.white,
    secondary: DesignTokens.secondaryColor,
    onSecondary: Colors.white,
    error: DesignTokens.errorColor,
    onError: Colors.white,
    background: DesignTokens.backgroundColorDark,
    onBackground: DesignTokens.textColorDark,
    surface: DesignTokens.surfaceColorDark,
    onSurface: DesignTokens.textColorDark,
  ),
);
