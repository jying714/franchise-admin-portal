library shared_core;

// Public API - Clean Barrel (single source of truth for mobile_app + future white-label apps)
// Import pattern: import 'package:shared_core/shared_core.dart' as shared;

export 'models.dart'; // All core models (MenuItem, Order, User, Category, Banner, etc.)

// Config - consolidated barrel (DesignTokens, BrandingConfig, FeatureConfig, AppConfig, etc.)
export 'config.dart'; // UiConfig (mobile) bridges these; DesignTokens = pure scalars only

// Providers
export 'src/core/providers/franchise_provider.dart';

// Interfaces for platform adapters (storage, etc.)
export 'src/core/utils/local_storage.dart';

// Services (core runtime services used by mobile flows)
export 'src/core/services/auth_service.dart';
export 'src/core/services/auth_service_impl.dart';
export 'src/core/services/firestore_service.dart';
export 'src/core/services/firestore_service_impl.dart';

export 'src/core/services/analytics_service.dart';
export 'src/core/services/analytics_service_impl.dart';

// Firebase (needed for FirebaseAuth in CartIconBadge etc.)
export 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;

// Add more as needed (keep this barrel minimal but complete for customer mobile flows)
