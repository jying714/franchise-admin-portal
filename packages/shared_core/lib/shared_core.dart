library shared_core;

// Public API - Clean Barrel (single source of truth for mobile_app + future white-label apps)
// Import pattern: import 'package:shared_core/shared_core.dart' as shared;

export 'models.dart'; // All core models
export 'config.dart'; // Config layer (DesignTokens, BrandingConfig, etc.)
export 'src/core/providers/franchise_provider.dart';
export 'src/core/utils/local_storage.dart';
export 'src/core/services/auth_service.dart';
export 'src/core/services/auth_service_impl.dart';
export 'src/core/services/firestore_service.dart';
export 'src/core/services/firestore_service_impl.dart';
export 'src/core/utils/error_logger.dart';
export 'src/core/services/analytics_service.dart';
export 'src/core/services/analytics_service_impl.dart';
export 'src/core/services/mock_payment_service.dart';
export 'utils.dart'
    show
        generateFranchiseQR,
        parseFranchiseQR,
        isFranchiseQR,
        getFranchiseDisplayFromQR;
export 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
