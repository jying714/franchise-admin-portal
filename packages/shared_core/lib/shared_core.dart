library shared_core;

// Public API - Clean Barrel

export 'models.dart'; // Existing models barrel

// Config
export 'src/core/config/design_tokens.dart';
export 'src/core/config/branding_config.dart';

// Providers (NEW)
export 'src/core/providers/franchise_provider.dart';

// Interfaces for platform adapters (storage, etc.)
export 'src/core/utils/local_storage.dart';

// Services
export 'src/core/services/auth_service.dart';
export 'src/core/services/auth_service_impl.dart';
export 'src/core/services/firestore_service.dart';
export 'src/core/services/firestore_service_impl.dart';

export 'src/core/services/analytics_service.dart';
export 'src/core/services/analytics_service_impl.dart';

// Firebase (needed for FirebaseAuth in CartIconBadge)
export 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;

// Add more as needed
