import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:shared_core/src/core/services/auth_service.dart';
import 'package:franchise_mobile_app/core/services/analytics_service.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/features/language/language_provider.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as app_user;
import 'package:franchise_mobile_app/core/models/ingredient_metadata.dart';
import 'firebase_options.dart';
// Import required screens/widgets:
import 'package:franchise_mobile_app/features/splash/splash_screen.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/complete_profile_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// --- IngredientMetadata Firestore Loader Provider ---
class IngredientMetadataProvider extends ChangeNotifier {
  final Map<String, IngredientMetadata> _ingredients = {};
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  Map<String, IngredientMetadata> get ingredients => _ingredients;

  IngredientMetadataProvider() {
    _loadIngredients();
    //print('[DEBUG] All loaded ingredient IDs: ${_ingredients.keys.toList()}');
    for (var entry in _ingredients.entries) {
      //print('[DEBUG] Ingredient: ${entry.key} -> ${entry.value.toMap()}');
    }
  }

  Future<void> _loadIngredients() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('ingredient_metadata')
          .get();
      //print('[DEBUG] ingredient_metadata docs loaded: ${snapshot.docs.length}');
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final id = data['id'] ?? doc.id;
        //print('[DEBUG] Loading ingredient: $id');
        _ingredients[id] = IngredientMetadata.fromMap({...data, 'id': id});
      }
      //print('[DEBUG] All loaded ingredient IDs: ${_ingredients.keys.toList()}');
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      //print('[DEBUG] Error loading ingredient_metadata: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // The ChangeNotifierProvider for loading ingredient metadata
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        Provider(create: (_) => AuthService()),
        Provider(create: (_) => AnalyticsService()),
        Provider(create: (_) => FirestoreService()),
        // Loader for ingredient metadata
        ChangeNotifierProvider(create: (_) => IngredientMetadataProvider()),
        // StreamProvider for Firestore-backed User model, synced with Firebase Auth state
        StreamProvider<app_user.User?>(
          create: (context) {
            final auth = Provider.of<AuthService>(context, listen: false);
            final firestore =
                Provider.of<FirestoreService>(context, listen: false);
            return auth.authStateChanges.asyncExpand((fbUser) {
              if (fbUser == null) return Stream.value(null);
              return firestore.getUserByIdStream(fbUser.uid);
            });
          },
          initialData: null,
        ),
      ],
      // This Provider<Map<String, IngredientMetadata>> is used by all screens for
      // ingredient lookup, including CustomizationModal and menu item display.
      // It is updated on app startup and can be extended to reload on demand.
      // NEW: Inject a Provider<Map<String, IngredientMetadata>> above MaterialApp
      child: Builder(
        builder: (context) {
          final ingredientProvider =
              Provider.of<IngredientMetadataProvider>(context);

          // While loading ingredients, show loading (ensures Provider is available before app builds)
          if (!ingredientProvider.isLoaded) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
              debugShowCheckedModeBanner: false,
            );
          }

          // Provide the loaded Map<String, IngredientMetadata> for all screens
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
                      bodyMedium: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.captionFontSize,
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
    final appUser = Provider.of<app_user.User?>(context);

    // Still loading or not signed in
    if (appUser == null) {
      final auth = Provider.of<AuthService>(context, listen: false);
      // If Firebase Auth's user is null, show Sign In
      if (auth.currentUser == null) {
        return const SignInScreen();
      }
      // Otherwise show splash while Firestore user loads
      return const SplashScreen();
    }

    // If profile is incomplete (null or false), show the forced dialog (once)
    if ((appUser.completeProfile == null || appUser.completeProfile == false) &&
        !_dialogShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _dialogShown = true;
        await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => CompleteProfileDialog(user: appUser),
        );
        // Optionally refresh or reload user data after dialog
        // setState(() {}); // Uncomment if needed
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Profile is complete, load main menu
    return const MainMenuScreen();
  }
}
