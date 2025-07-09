import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:franchise_admin_portal/admin/error_logs/error_logs_screen.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/firebase_options.dart';
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/services/analytics_service.dart';
import 'package:franchise_admin_portal/core/theme_provider.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/home_wrapper.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'widgets/user_profile_notifier.dart'; // adjust path if needed
import 'widgets/auth_profile_listener.dart'; // adjust path if needed
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Use a shared FirestoreService for error logging at app root
  final firestoreService = FirestoreService();

  const defaultFranchiseId = 'unknown';

  runZonedGuarded(() {
    // Global Flutter framework error logging
    FlutterError.onError = (FlutterErrorDetails details) async {
      FlutterError.dumpErrorToConsole(details);
      await firestoreService.logError(
        defaultFranchiseId,
        message: details.exceptionAsString(),
        source: 'FlutterError',
        stackTrace: details.stack?.toString(),
        severity: 'fatal',
        screen: 'main',
        contextData: {
          'library': details.library,
          'context': details.context.toString(),
        },
      );
    };

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FranchiseProvider>(
              create: (_) => FranchiseProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthService()),
          Provider<FirestoreService>.value(value: firestoreService),
          Provider(create: (_) => AnalyticsService()),
          StreamProvider<fb_auth.User?>.value(
            value: fb_auth.FirebaseAuth.instance.authStateChanges(),
            initialData: null,
          ),
          ChangeNotifierProvider(create: (_) => UserProfileNotifier()),
        ],
        child: Builder(builder: (context) {
          final firebaseUser = Provider.of<fb_auth.User?>(context);
          final franchiseProvider = Provider.of<FranchiseProvider>(context);
          final franchiseId =
              franchiseProvider.franchiseId ?? 'defaultFranchiseId';

          print('main.dart: firebaseUser?.email = ${firebaseUser?.email}');
          print('main.dart: franchiseId = $franchiseId');

          return AuthProfileListener(
            franchiseId: franchiseId,
            child: KeyedSubtree(
              key: ValueKey(firebaseUser?.uid ?? 'nouid'),
              child: FranchiseAdminPortalApp(franchiseId: franchiseId),
            ),
          );
        }),
      ),
    );
  }, (Object error, StackTrace stack) async {
    // Global Dart errors outside Flutter framework (async, etc)
    await firestoreService.logError(
      defaultFranchiseId,
      message: error.toString(),
      source: 'runZonedGuarded',
      stackTrace: stack.toString(),
      severity: 'fatal',
      screen: 'main',
      contextData: {},
    );
  });
}

class FranchiseAdminPortalApp extends StatelessWidget {
  final String franchiseId;
  const FranchiseAdminPortalApp({super.key, required this.franchiseId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Franchise Admin Portal',
          theme: ThemeData(
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
                borderRadius:
                    BorderRadius.circular(DesignTokens.adminCardRadius),
              ),
              margin: EdgeInsets.all(DesignTokens.adminCardSpacing),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                foregroundColor: DesignTokens.foregroundColor,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminButtonRadius),
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
                borderRadius:
                    BorderRadius.circular(DesignTokens.dialogBorderRadius),
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
                borderRadius:
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
            ),
          ),
          darkTheme: ThemeData(
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
              iconTheme:
                  IconThemeData(color: DesignTokens.appBarForegroundColorDark),
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
                borderRadius:
                    BorderRadius.circular(DesignTokens.adminCardRadius),
              ),
              margin: EdgeInsets.all(DesignTokens.adminCardSpacing),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryColor,
                foregroundColor: DesignTokens.foregroundColorDark,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(DesignTokens.adminButtonRadius),
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
                borderRadius:
                    BorderRadius.circular(DesignTokens.dialogBorderRadius),
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
                borderRadius:
                    BorderRadius.circular(DesignTokens.formFieldRadius),
              ),
            ),
            dividerColor: DesignTokens.dividerColorDark,
            iconTheme: IconThemeData(color: DesignTokens.textColorDark),
          ),
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeWrapper(franchiseId: franchiseId),
        );
      },
    );
  }
}
