import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';

// Shared Core
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;

// Local Providers & Config
import 'package:franchise_mobile_app/features/language/language_provider.dart';
import 'package:franchise_mobile_app/core/models/user.dart' as app_user;
import 'package:franchise_mobile_app/config/ui_config.dart';
// Note: FranchiseProvider now comes exclusively from shared_core (single source of truth)

// Screens
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/features/auth/sign_in_screen.dart';
import 'package:franchise_mobile_app/features/user_accounts/complete_profile_dialog.dart';
import 'firebase_options.dart';

/// Ingredient Metadata Provider (global for now)
class IngredientMetadataProvider extends ChangeNotifier {
  final Map<String, shared.IngredientMetadata> _ingredients = {};
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;
  Map<String, shared.IngredientMetadata> get ingredients => _ingredients;

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
        _ingredients[id] =
            shared.IngredientMetadata.fromMap({...data, 'id': id});
      }
      _isLoaded = true;
      notifyListeners();
      print(
          '✅ [IngredientMetadataProvider] Loaded ${_ingredients.length} ingredients');
    } catch (e) {
      _isLoaded = true;
      notifyListeners();
      print('❌ [IngredientMetadataProvider] Failed to load ingredients: $e');
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

        /// FranchiseProvider from shared_core ONLY (P1 cleanup: dual wrapper removed).
        /// All franchise state + logic lives in shared_core.
        /// The plain Provider is sufficient: Consumers use it for hasValidFranchise guards + currentFranchiseId reads.
        Provider<shared.FranchiseProvider>(
          create: (_) => shared.FranchiseProvider(AppLocalStorage()),
        ),

        Provider<shared.AnalyticsService>(
            create: (_) => shared.AnalyticsServiceImpl()),
        ChangeNotifierProvider(create: (_) => IngredientMetadataProvider()),

        // Shared Core Services
        Provider<shared.AuthService>(create: (_) => shared.AuthServiceImpl()),
        Provider<shared.FirestoreService>(
            create: (_) => shared.FirestoreServiceImpl()),

        // User Stream
        StreamProvider<shared.User?>(
          create: (_) {
            final authService = shared.AuthServiceImpl();
            final firestoreService = shared.FirestoreServiceImpl();
            return authService.authStateChanges.asyncExpand((user) {
              if (user == null) return Stream.value(null);
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

          return Provider<Map<String, shared.IngredientMetadata>>.value(
            value: ingredientProvider.ingredients,
            child: Consumer<LanguageProvider>(
              builder: (context, languageProvider, child) {
                return MaterialApp(
                  title: 'Doughboys Pizzeria',
                  theme: ThemeData(
                    primaryColor: UiConfig.primaryColor,
                    scaffoldBackgroundColor: UiConfig.backgroundColorDark,
                    colorScheme: ColorScheme.fromSwatch().copyWith(
                      secondary: UiConfig.secondaryColor,
                    ),
                    textTheme: TextTheme(
                      titleLarge: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.titleFontSize,
                        fontWeight: UiConfig.fontWeightBold,
                      ),
                      bodyLarge: TextStyle(
                        fontFamily: DesignTokens.fontFamily,
                        fontSize: DesignTokens.bodyFontSize,
                        fontWeight: UiConfig.fontWeightNormal,
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
  bool _isInitializing = true; // ← NEW

  @override
  Widget build(BuildContext context) {
    final sharedUser = Provider.of<shared.User?>(context);
    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);

    if (sharedUser == null) {
      return const SignInScreen();
    }

    // Initialize franchise (only once)
    if (_isInitializing && !franchiseProvider.hasValidFranchise) {
      _isInitializing = false; // prevent multiple calls
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print('🔄 [HomeWrapper] Starting franchise initialization...');
        await franchiseProvider.initializeWithUser(sharedUser);
        print('✅ [HomeWrapper] Franchise initialization completed');
        if (mounted) setState(() {}); // force rebuild
      });
    }

    // Show loading while initializing
    if (_isInitializing || !franchiseProvider.hasValidFranchise) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Convert to local model for dialog
    final localUser = app_user.User(
      id: sharedUser.id,
      name: sharedUser.name,
      email: sharedUser.email,
      phoneNumber: sharedUser.phoneNumber,
      roles: sharedUser.roles,
      addresses: sharedUser.addresses,
      language: sharedUser.language,
      status: sharedUser.status,
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
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => CompleteProfileDialog(user: localUser),
          );
        }
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return const MainMenuScreen();
  }
}
