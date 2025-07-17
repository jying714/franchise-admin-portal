// File: lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:franchise_admin_portal/admin/hq_owner/widgets/alert_list_screen.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/firebase_options.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/services/analytics_service.dart';
import 'package:franchise_admin_portal/core/theme_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/providers/franchise_gate.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/landing_page.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/widgets/profile_gate_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/developer/developer_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/franchise/franchise_selector_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/owner_hq_dashboard_screen.dart';
import 'package:franchise_admin_portal/widgets/financials/invoice_list_screen.dart';
import 'package:franchise_admin_portal/widgets/financials/invoice_detail_screen.dart';
import 'package:franchise_admin_portal/admin/hq_owner/payout_list_screen.dart';
import 'package:franchise_admin_portal/core/providers/payout_filter_provider.dart';
import 'package:franchise_admin_portal/admin/owner/platform_owner_dashboard_screen.dart';
import 'package:franchise_admin_portal/core/providers/franchisee_invitation_provider.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invitation_service.dart';
import 'package:franchise_admin_portal/admin/profile/universal_profile_screen.dart';
import 'package:franchise_admin_portal/admin/auth/invite_accept_screen.dart';
import 'package:franchise_admin_portal/admin/profile/franchise_onboarding_screen.dart';
import 'dart:html' as html;

/// Returns initial unauth route and optional invite token, e.g. ('/invite-accept', 'abc123').
Map<String, dynamic> getInitialUnauthRoute() {
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
      await ErrorLogger.log(
        message: details.exceptionAsString(),
        stack: details.stack?.toString(),
        source: 'FlutterError',
        severity: 'fatal',
        screen: 'main',
        contextData: {
          'library': details.library,
          'context':
              details.context?.toDescription() ?? details.context.toString(),
        },
      );
    };

    final firestoreService = FirestoreService();
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          Provider<FirestoreService>.value(value: firestoreService),
          Provider(create: (_) => AnalyticsService()),
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
    await ErrorLogger.log(
      message: error.toString(),
      stack: stack.toString(),
      source: 'runZonedGuarded',
      severity: 'fatal',
      screen: 'main',
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
            initialRoute: initialRoute,
            onGenerateRoute: (RouteSettings settings) {
              print(
                  '[DEBUG][main.dart][onGenerateRoute] [UNAUTH] route=${settings.name}, args=${settings.arguments}');
              Uri uri = Uri.parse(settings.name ?? '/');
              final String path = uri.path;

              if (path == '/' || path == '/landing') {
                print(
                    '[DEBUG][main.dart][onGenerateRoute] Routing to LandingPage.');
                return MaterialPageRoute(builder: (_) => const LandingPage());
              }
              if (path == '/sign-in') {
                print(
                    '[DEBUG][main.dart][onGenerateRoute] Routing to SignInScreen.');
                return MaterialPageRoute(builder: (_) => const SignInScreen());
              }
              if (path == '/invite-accept') {
                String? token;
                if (uri.queryParameters.containsKey('token')) {
                  token = uri.queryParameters['token'];
                  print(
                      '[DEBUG][main.dart][onGenerateRoute] Got token from URI: $token');
                } else if (settings.arguments is Map &&
                    (settings.arguments as Map).containsKey('token')) {
                  token = (settings.arguments as Map)['token'] as String?;
                  print(
                      '[DEBUG][main.dart][onGenerateRoute] Got token from RouteSettings.arguments: $token');
                } else if (inviteToken.isNotEmpty) {
                  token = inviteToken;
                  print(
                      '[DEBUG][main.dart][onGenerateRoute] Using initial inviteToken: $token');
                }
                print(
                    '[DEBUG][main.dart][onGenerateRoute] Routing to InviteAcceptScreen with token: $token');
                return MaterialPageRoute(
                  builder: (_) => InviteAcceptScreen(inviteToken: token),
                );
              }
              print(
                  '[DEBUG][main.dart][onGenerateRoute] Routing to fallback LandingPage.');
              return MaterialPageRoute(builder: (_) => const LandingPage());
            },
          );
        },
      );
    }

    // ==== AUTHENTICATED APP ====
    print(
        '[main.dart][FranchiseAppRootSplit] Authenticated: showing authenticated app');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FranchiseProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<FirestoreService>.value(value: FirestoreService()),
        Provider(create: (_) => AnalyticsService()),
        StreamProvider<fb_auth.User?>.value(
          value: fb_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
        ChangeNotifierProvider(
          create: (_) => FranchiseeInvitationProvider(
            service: FranchiseeInvitationService(
              firestoreService: Provider.of<FirestoreService>(_, listen: false),
            ),
          ),
        ),
      ],
      child: const FranchiseAuthenticatedRoot(),
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final fbUser = Provider.of<fb_auth.User?>(context);
    final adminUserProvider =
        Provider.of<AdminUserProvider>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    // Only start listening if not already listening to this user
    if (fbUser != null &&
        fbUser.uid != _lastUid &&
        (adminUserProvider.user == null ||
            adminUserProvider.user?.id != fbUser.uid)) {
      _lastUid = fbUser.uid;
      print(
          '[FranchiseAuthenticatedRoot] (didChangeDependencies) Scheduling listenToAdminUser for UID: ${fbUser.uid}');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        adminUserProvider.listenToAdminUser(firestoreService, fbUser.uid);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fbUser = Provider.of<fb_auth.User?>(context);
    final adminUserProvider = Provider.of<AdminUserProvider>(context);

    print(
        '[DEBUG][FranchiseAuthenticatedRoot] fbUser: ${fbUser?.email}, uid: ${fbUser?.uid}');
    print(
        '[DEBUG][FranchiseAuthenticatedRoot] adminUserProvider.loading: ${adminUserProvider.loading}');
    print(
        '[DEBUG][FranchiseAuthenticatedRoot] adminUserProvider.user: ${adminUserProvider.user}');

    if (adminUserProvider.loading || adminUserProvider.user == null) {
      print(
          '[FranchiseAuthenticatedRoot] User profile is still loading OR user not yet loaded...');
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (adminUserProvider.user?.roles == null) {
      print(
          '[FranchiseAuthenticatedRoot] Authenticated but app user FOUND, but roles are NULL!');
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Unauthorized')),
          body: const Center(
            child: Text(
                'Your account is not active or authorized.\n[DEBUG] User profile missing roles property.'),
          ),
        ),
      );
    }

    // Success! Build the app.
    print(
        '[FranchiseAuthenticatedRoot] Authenticated and app user loaded. Building router.');
    print(
        '[DEBUG][FranchiseAuthenticatedRoot] Proceeding to MaterialApp, user roles: ${adminUserProvider.user?.roles}');

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
        initialRoute: '/post-login-gate',
        onGenerateRoute: (RouteSettings settings) {
          print('[DEBUG][onGenerateRoute] Route name: ${settings.name}');
          try {
            print('-----------------------------------------------------');
            print('[DEBUG][onGenerateRoute] Route name: ${settings.name}');
            final uri = Uri.parse(settings.name ?? '/');
            final user = adminUserProvider.user!;
            print('[DEBUG][onGenerateRoute] User roles: ${user.roles}');
            print('[DEBUG][onGenerateRoute] User object: $user');
            print(
                '[DEBUG][onGenerateRoute] Route arguments: ${settings.arguments}');

            // Role-based root/landing routing
            if (uri.path == '/' || uri.path == '/landing') {
              print('[DEBUG][onGenerateRoute] Root/landing route hit.');
              if (user.roles.contains('platform_owner')) {
                print('[main.dart] Routing to PlatformOwnerDashboardScreen');
                return MaterialPageRoute(
                    builder: (context) => const PlatformOwnerDashboardScreen());
              }
              if (user.roles.contains('hq_owner')) {
                print('[main.dart] Routing to OwnerHQDashboardScreen');
                return MaterialPageRoute(
                    builder: (context) =>
                        const FranchiseGate(child: OwnerHQDashboardScreen()));
              }
              if (user.roles.contains('developer')) {
                print('[main.dart] Routing to DeveloperDashboardScreen');
                return MaterialPageRoute(
                    builder: (context) =>
                        const FranchiseGate(child: DeveloperDashboardScreen()));
              }
              print('[main.dart] Routing to AdminDashboardScreen (fallback)');
              return MaterialPageRoute(
                  builder: (context) =>
                      const FranchiseGate(child: AdminDashboardScreen()));
            }

            // ======= Standard Authenticated Routes =======
            if (uri.path == '/post-login-gate') {
              print('[main.dart] Routing to ProfileGateScreen');
              return MaterialPageRoute(
                  builder: (context) => const ProfileGateScreen());
            }
            if (uri.path == '/admin/dashboard') {
              print('[main.dart] Routing to AdminDashboardScreen');
              return MaterialPageRoute(
                  builder: (context) =>
                      const FranchiseGate(child: AdminDashboardScreen()));
            }
            if (uri.path == '/developer/dashboard') {
              print('[main.dart] Routing to DeveloperDashboardScreen');
              return MaterialPageRoute(
                  builder: (context) =>
                      const FranchiseGate(child: DeveloperDashboardScreen()));
            }
            if (uri.path == '/developer/select-franchise') {
              print('[main.dart] Routing to FranchiseSelectorScreen');
              return MaterialPageRoute(
                  builder: (context) => const FranchiseSelectorScreen());
            }
            if (uri.path == '/hq-owner/dashboard') {
              print('[main.dart] Routing to OwnerHQDashboardScreen');
              return MaterialPageRoute(
                  builder: (context) =>
                      const FranchiseGate(child: OwnerHQDashboardScreen()));
            }
            if (uri.path == '/platform-owner/dashboard') {
              print('[main.dart] Routing to PlatformOwnerDashboardScreen');
              return MaterialPageRoute(
                  builder: (context) => const PlatformOwnerDashboardScreen());
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
            if (uri.path == '/invite-accept') {
              final args = settings.arguments as Map?;
              final token = args?['token'] as String?;
              print('[main.dart] Routing to InviteAcceptScreen, token=$token');
              return MaterialPageRoute(
                  builder: (context) => InviteAcceptScreen(inviteToken: token));
            }
            if (uri.path == '/franchise-onboarding') {
              final args = settings.arguments as Map?;
              final token = args?['token'] as String?;
              print(
                  '[main.dart] Routing to FranchiseOnboardingScreen, token=$token');
              if (token == null || token.isEmpty) {
                print(
                    '[main.dart] FranchiseOnboardingScreen: Invalid or missing token!');
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
                      FranchiseOnboardingScreen(inviteToken: token));
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
