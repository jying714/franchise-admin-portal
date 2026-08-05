// packages/shared_core/lib/utils.dart

// Core utils (pure Dart)
export 'src/core/utils/error_logger.dart';
export 'src/core/utils/export_utils_core.dart';
export 'src/core/utils/formatting_core.dart';
export 'src/core/utils/log_utils_core.dart';
export 'src/core/utils/schema_templates.dart';
export 'src/core/utils/user_permissions.dart';
export 'src/core/utils/qr_utils.dart'; // P2 QR + deep link foundations (pure Dart payload)
export 'src/core/utils/local_storage.dart'; // Interface only, implemented in web-app and mobile-app
export 'src/core/utils/pin_hash.dart';

// Feature utils (pure Dart)
export 'src/core/utils/features/enum_platform_features.dart';
export 'src/core/utils/features/feature_extensions.dart';
export 'src/core/utils/features/feature_gate.dart';
export 'src/core/utils/features/feature_guard.dart';
export 'src/core/utils/features/feature_lock_overlay.dart';
