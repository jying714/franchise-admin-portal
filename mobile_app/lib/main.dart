import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
import 'package:franchise_mobile_app/core/services/analytics_service.dart';
import 'package:franchise_mobile_app/features/language/language_provider.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as app_user;
import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'package:shared_core/shared_core.dart' as shared;

import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/complete_profile_dialog.dart';
import 'firebase_options.dart';

/// Ingredient Metadata Provider
class IngredientMetadataProvider extends ChangeNotifier {
  final Map<String, IngredientMetadata> _ingredients = {};
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  Map<String, IngredientMetadata> get ingredients => _ingredients;

  IngredientMetadataProvider() {
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ingredient_metadata')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] ?? doc.id;
        _ingredients[id] = IngredientMetadata.fromMap({...data, 'id': id});
      }
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      _isLoaded = true;
      notifyListeners();
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => FranchiseProvider()),
        Provider(create: (_) => AnalyticsService()),
        ChangeNotifierProvider(create: (_) => IngredientMetadataProvider()),

        // Concrete implementations from shared_core
        Provider<shared.AuthService>(create: (_) => shared.AuthServiceImpl()),
        Provider<shared.FirestoreService>(
            create: (_) => shared.FirestoreServiceImpl()),

        StreamProvider<shared.User?>(
          create: (_) {
            final authService = shared.AuthServiceImpl();
            final firestoreService = shared.FirestoreServiceImpl();

            return authService.authStateChanges.asyncExpand((user) {
              if (user == null) {
                return Stream.value(null);
              }
              return firestoreService.getUserByIdStream(user.id);
            });
          },
          initialData: null,
        ),
      ],
      child: Builder(
        builder: (context) {
          final ingredientProvider =
              Provider.of<IngredientMetadataProvider>(context);
          if (!ingredientProvider.isLoaded) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
              debugShowCheckedModeBanner: false,
            );
          }

          return Provider<Map<String, IngredientMetadata>>.value(
            value: ingredientProvider.ingredients,
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return MaterialApp(
                  title: 'Doughboys Pizzeria',
                  theme: ThemeData(
                    primaryColor: DesignTokens.primaryColor,
                    scaffoldBackgroundColor: DesignTokens.backgroundColor,
                    colorScheme: ColorScheme.fromSwatch().copyWith(
                      secondary: DesignTokens.secondaryColor,
                    ),
                    textTheme: const TextTheme(
                      titleLarge: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.titleFontSize,
                        fontWeight: DesignTokens.titleFontWeight,
                      ),
                      bodyLarge: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.bodyFontSize,
                        fontWeight: DesignTokens.bodyFontWeight,
                      ),
                    ),
                  ),
                  locale: languageProvider.locale,
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  home: const HomeWrapper(),
                  debugShowCheckedModeBanner: false,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class HomeWrapper extends StatefulWidget {
  const HomeWrapper({super.key});

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  bool _dialogShown = false;

  @override
  Widget build(BuildContext context) {
    final sharedUser = Provider.of<shared.User?>(context);

    if (sharedUser == null) {
      return const SignInScreen();
    }

    // Convert shared.User → local app_user.User for the dialog
    final localUser = app_user.User(
      id: sharedUser.id,
      name: sharedUser.name,
      email: sharedUser.email,
      roles: sharedUser.roles,
      language: sharedUser.language,
      status: sharedUser.status,
      phoneNumber: sharedUser.phoneNumber,
      addresses: sharedUser.addresses,
      defaultFranchise: sharedUser.defaultFranchise,
      avatarUrl: sharedUser.avatarUrl,
      franchiseIds: sharedUser.franchiseIds,
      completeProfile: sharedUser.completeProfile,
      onboardingComplete: sharedUser.onboardingComplete,
      isActive: sharedUser.isActive,
      updatedAt: sharedUser.updatedAt,
    );

    if ((localUser.completeProfile == null ||
            localUser.completeProfile == false) &&
        !_dialogShown) {
      _dialogShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => CompleteProfileDialog(user: localUser),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const MainMenuScreen();
  }
}
