import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/firebase_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'core/services/firestore_service.dart';
import 'core/models/user.dart';
import 'admin/dashboard/admin_dashboard_screen.dart';

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
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        StreamProvider<User?>(
          create: (_) => FirestoreService().currentUserStream(),
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
        home: const SignInScreen(),
      ),
    );
  }
}
