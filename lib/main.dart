import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'core/services/firestore_service.dart';
import 'package:franchise_admin_portal/home_wrapper.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FranchiseAdminPortalApp());
}

class FranchiseAdminPortalApp extends StatelessWidget {
  const FranchiseAdminPortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FirestoreService>(create: (_) => FirestoreService()),

        // 1️⃣ Listen to FirebaseAuth state
        StreamProvider<fb_auth.User?>.value(
          value: fb_auth.FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),

        // 2️⃣ Listen to your app-user document via the new appUserStream()
        StreamProvider<admin_user.User?>(
          create: (context) => context.read<FirestoreService>().appUserStream(),
          initialData: null,
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Franchise Admin Portal',
        theme: ThemeData(
          colorScheme:
              ColorScheme.fromSeed(seedColor: DesignTokens.primaryColor),
          fontFamily: DesignTokens.fontFamily,
          scaffoldBackgroundColor: DesignTokens.backgroundColor,
          appBarTheme: AppBarTheme(
            backgroundColor: DesignTokens.primaryColor,
            foregroundColor: DesignTokens.foregroundColor,
          ),
          textTheme: TextTheme(
            bodyMedium: TextStyle(
              fontFamily: DesignTokens.fontFamily,
              fontSize: 14,
              color: DesignTokens.textColor,
            ),
          ),
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const HomeWrapper(),
      ),
    );
  }
}
