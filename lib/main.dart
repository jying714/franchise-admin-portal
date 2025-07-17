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

    runApp(const FranchiseAdminPortalApp());
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

class FranchiseAdminPortalApp extends StatelessWidget {
  const FranchiseAdminPortalApp({super.key});

  String _getInitialRouteFromHash() {
    final hash = html.window.location.hash;
    if (hash.startsWith('#/invite-accept')) {
      return '/invite-accept' + hash.substring('#/invite-accept'.length);
    }
    return '/';
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        Provider<FirestoreService>.value(value: FirestoreService()),
        Provider(create: (_) => AnalyticsService()),
        StreamProvider<fb_auth.User?>.value(
          value: fb_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => FranchiseProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
        // Do NOT put FranchiseeInvitationProvider here!
      ],
      child: FranchiseAdminPortalRoot(initialRoute: _getInitialRouteFromHash()),
    );
  }
}

class FranchiseAdminPortalRoot extends StatelessWidget {
  final String initialRoute;
  const FranchiseAdminPortalRoot({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FranchiseeInvitationProvider(
        service: FranchiseeInvitationService(
          firestoreService:
              Provider.of<FirestoreService>(context, listen: false),
        ),
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Franchise Admin Portal',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: ThemeProvider().themeMode,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        initialRoute: initialRoute,
        onGenerateRoute: (RouteSettings settings) {
          print('[main.dart] onGenerateRoute: route=${settings.name}');
          final uri = Uri.parse(settings.name ?? '/');
          final fbUser = Provider.of<fb_auth.User?>(context, listen: false);

          // ==== UNAUTHENTICATED APP ====
          if (fbUser == null) {
            if (uri.path == '/' || uri.path == '/landing') {
              print('[main.dart] Routing to LandingPage');
              return MaterialPageRoute(
                  builder: (context) => const LandingPage());
            }
            if (uri.path == '/sign-in') {
              print('[main.dart] Routing to SignInScreen');
              return MaterialPageRoute(
                  builder: (context) => const SignInScreen());
            }
            if (uri.path == '/invite-accept') {
              final args = settings.arguments as Map?;
              final token = args?['token'] as String?;
              print('[main.dart] Routing to InviteAcceptScreen, token=$token');
              return MaterialPageRoute(
                builder: (context) => InviteAcceptScreen(inviteToken: token),
              );
            }
            print('[main.dart] Routing to fallback LandingPage');
            return MaterialPageRoute(builder: (context) => const LandingPage());
          }

          // ==== AUTHENTICATED APP ====
          final userProvider =
              Provider.of<AdminUserProvider>(context, listen: false);
          final user = userProvider.user;

          // === Role-based root/landing routing ===
          if (uri.path == '/' || uri.path == '/landing') {
            // No user or roles: Unauthorized
            if (user == null || user.roles == null || user.roles.isEmpty) {
              print('[main.dart] Routing to Unauthorized (no user/roles)');
              return MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Unauthorized')),
                  body: const Center(
                      child: Text('Your account is not active or authorized.')),
                ),
              );
            }
            // Role-based dashboard routing
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
            // Fallback for other roles
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
                body: const Center(child: Text('Your account is not active.')),
              ),
            );
          }
          if (uri.path == '/alerts') {
            print('[main.dart] Routing to AlertListScreen');
            return MaterialPageRoute(
              builder: (context) {
                final user =
                    Provider.of<AdminUserProvider>(context, listen: false).user;
                final franchiseId = user?.defaultFranchise ??
                    ((user?.franchiseIds.isNotEmpty ?? false)
                        ? user!.franchiseIds.first
                        : '');
                return AlertListScreen(
                  franchiseId: franchiseId,
                  developerMode: user?.isDeveloper ?? false,
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
              builder: (context) => InviteAcceptScreen(inviteToken: token),
            );
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
        },
        home: null,
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
