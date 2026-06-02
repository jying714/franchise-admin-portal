import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_localizations/flutter_localizations.dart';

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
import 'package:franchise_admin_portal/admin/owner/platform_owner_dashboard_screen.dart';
import 'package:franchise_admin_portal/widgets/profile_gate_screen.dart';
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
  Widget build(BuildContext context) {
    return Consumer<shared.FranchiseProvider>(
      builder: (context, franchiseProvider, _) {
        final userNotifier =
            Provider.of<UserProfileNotifier>(context, listen: false);
        final user = userNotifier.user;

        if (user?.roles?.contains(shared.User.rolePlatformOwner) ?? false) {
          return const MaterialApp(
            home: PlatformOwnerDashboardScreen(
                currentScreen: 'platform-owner/dashboard'),
          );
        }
        if (user?.roles?.contains(shared.User.roleHqOwner) ?? false) {
          return const MaterialApp(home: OwnerHQDashboardScreen());
        }
        return FranchiseGate(child: const AdminDashboardScreen());
      },
    );
  }
}

class FranchiseAppRootSplit extends StatelessWidget {
  const FranchiseAppRootSplit({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final userNotifier =
        Provider.of<UserProfileNotifier>(context, listen: false);

    if (firebaseUser != null &&
        userNotifier.user == null &&
        !userNotifier.loading) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => userNotifier.loadUser());
    }

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
              return MaterialPageRoute(builder: (_) => const SignInScreen());
            if (path == '/invite-accept') {
              String? token = (settings.arguments as Map?)?['token'] as String?;
              return MaterialPageRoute(
                  builder: (_) => InviteAcceptScreen(inviteToken: token));
            }
            return MaterialPageRoute(builder: (_) => const LandingPage());
          },
        );
      });
    }

    // AUTHENTICATED
    return Selector<UserProfileNotifier, bool>(
      selector: (_, notifier) => notifier.user != null && !notifier.loading,
      builder: (context, isUserReady, _) {
        final franchiseProvider =
            Provider.of<shared.FranchiseProvider>(context, listen: false);
        final user =
            Provider.of<UserProfileNotifier>(context, listen: false).user;
        final requiresFranchise = user?.isFranchiseRequired ?? true;
        final fid = franchiseProvider.franchiseId;
        final isFranchiseReady = !requiresFranchise ||
            (fid != null && fid.isNotEmpty && fid != 'unknown');

        if (!isUserReady || !isFranchiseReady) {
          return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => shared.AdminUserProvider()),
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
            ChangeNotifierProvider(
                create: (_) => PlatformPlanSelectionProviderImpl()),
            ChangeNotifierProxyProvider2<shared.FranchiseProvider,
                shared.FirestoreService, FranchiseInfoProviderImpl>(
              create: (_) => FranchiseInfoProviderImpl(
                  firestore: shared.FirestoreServiceImpl(),
                  franchiseProvider:
                      shared.FranchiseProvider(AppLocalStorage())),
              update: (_, fp, fs, prev) => prev ??
                  FranchiseInfoProviderImpl(
                      firestore: fs, franchiseProvider: fp)
                ..loadFranchiseInfo(),
            ),
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
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, OnboardingProgressProviderImpl>(
              create: (_) => OnboardingProgressProviderImpl(
                  firestore: shared.FirestoreServiceImpl(), franchiseId: ''),
              update: (_, fs, fp, prev) =>
                  prev ??
                  OnboardingProgressProviderImpl(
                      firestore: fs, franchiseId: fp.franchiseId ?? ''),
            ),
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, IngredientMetadataProviderImpl>(
              create: (_) => IngredientMetadataProviderImpl(
                  firestore: shared.FirestoreServiceImpl(), franchiseId: ''),
              update: (_, fs, fp, prev) =>
                  prev ??
                  IngredientMetadataProviderImpl(
                      firestore: fs, franchiseId: fp.franchiseId ?? ''),
            ),
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, CategoryProviderImpl>(
              create: (_) => CategoryProviderImpl(
                  firestore: shared.FirestoreServiceImpl(), franchiseId: ''),
              update: (_, fs, fp, prev) =>
                  prev ??
                  CategoryProviderImpl(
                      firestore: fs, franchiseId: fp.franchiseId ?? ''),
            ),
            ChangeNotifierProxyProvider3<
                shared.FirestoreService,
                shared.FranchiseProvider,
                FranchiseInfoProviderImpl,
                MenuItemProviderImpl>(
              create: (_) => MenuItemProviderImpl(
                  firestoreService: shared.FirestoreServiceImpl(),
                  franchiseInfoProvider: FranchiseInfoProviderImpl(
                      firestore: shared.FirestoreServiceImpl(),
                      franchiseProvider:
                          shared.FranchiseProvider(AppLocalStorage()))),
              update: (_, fs, fp, fip, prev) =>
                  prev ??
                  MenuItemProviderImpl(
                      firestoreService: fs, franchiseInfoProvider: fip),
            ),
            ChangeNotifierProxyProvider2<shared.FirestoreService,
                shared.FranchiseProvider, IngredientTypeProviderImpl>(
              create: (_) => IngredientTypeProviderImpl(
                  firestoreService: shared.FirestoreServiceImpl()),
              update: (_, fs, fp, prev) =>
                  prev ?? IngredientTypeProviderImpl(firestoreService: fs)
                    ..franchiseId = fp.franchiseId ?? '',
            ),
            Provider<shared.AuditLogService>.value(
                value: AuditLogServiceImpl()),
            Provider<shared.AnalyticsService>.value(
                value: shared.AnalyticsServiceImpl()),
            StreamProvider<fb_auth.User?>.value(
                value: fb_auth.FirebaseAuth.instance.authStateChanges(),
                initialData: null),
          ],
          child: FranchiseAuthenticatedRoot(key: ValueKey(firebaseUser?.uid)),
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
