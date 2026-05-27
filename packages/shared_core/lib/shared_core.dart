library shared_core;

// Public API - Clean Barrel (Option A Architecture)

export 'models.dart'; // Existing models barrel

// Config
export 'src/core/config/design_tokens.dart';
export 'src/core/config/branding_config.dart';

// Services
export 'src/core/services/auth_service.dart';
export 'src/core/services/auth_service_impl.dart';
export 'src/core/services/firestore_service.dart';
export 'src/core/services/firestore_service_impl.dart';

// Add more as needed in future batches
