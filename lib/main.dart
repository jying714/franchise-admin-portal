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

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await fb_auth.FirebaseAuth.instance.setPersistence(
      fb_auth.Persistence.LOCAL,
    );

    FlutterError.onError = (FlutterErrorDetails details) async {
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
        child: const FranchiseAdminPortalRoot(),
      ),
    );
  }, (Object error, StackTrace stack) async {
    await ErrorLogger.log(
      message: error.toString(),
      stack: stack.toString(),
      source: 'runZonedGuarded',
      severity: 'fatal',
      screen: 'main',
    );
  });
}

class FranchiseAdminPortalRoot extends StatelessWidget {
  const FranchiseAdminPortalRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    print(
        '[main.dart] FranchiseAdminPortalRoot.build: firebaseUser=${firebaseUser?.email} uid=${firebaseUser?.uid}');
    // ==== UNAUTHENTICATED APP ====
    if (firebaseUser == null) {
      print('[main.dart] Unauthenticated: showing landing/sign-in');
      return MaterialApp(
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
        routes: {
          '/': (_) => const LandingPage(),
          '/landing': (_) => const LandingPage(),
          '/sign-in': (_) => const SignInScreen(),
        },
        initialRoute: '/',
        home: null,
      );
    }

    // ==== AUTHENTICATED APP ====
    print('[main.dart] Authenticated: showing post-login app');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FranchiseProvider>(
            create: (_) => FranchiseProvider()),
        ChangeNotifierProvider(create: (_) => AdminUserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<FirestoreService>.value(value: FirestoreService()),
        Provider(create: (_) => AnalyticsService()),
        StreamProvider<fb_auth.User?>.value(
          value: fb_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
      ],
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
        routes: {
          '/post-login-gate': (_) {
            print('[main.dart] /post-login-gate route built');
            return const ProfileGateScreen();
          },
          '/admin/dashboard': (_) {
            print('[main.dart] /admin/dashboard route built');
            return const FranchiseGate(child: AdminDashboardScreen());
          },
          '/developer/dashboard': (_) {
            print('[main.dart] /developer/dashboard route built');
            return const FranchiseGate(child: DeveloperDashboardScreen());
          },
          '/developer/select-franchise': (_) {
            print('[main.dart] /developer/select-franchise route built');
            return const FranchiseSelectorScreen();
          },
          '/hq-owner/dashboard': (_) {
            print('[main.dart] /hq-owner/dashboard route built');
            return const FranchiseGate(child: OwnerHQDashboardScreen());
          },
          '/unauthorized': (_) {
            print('[main.dart] /unauthorized route built');
            return Scaffold(
              appBar: AppBar(title: const Text('Unauthorized')),
              body: const Center(child: Text('Your account is not active.')),
            );
          },
          '/alerts': (context) {
            print('[main.dart] /alerts route built');
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
        },
        initialRoute: '/post-login-gate',
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
