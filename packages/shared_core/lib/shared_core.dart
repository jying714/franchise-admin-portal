library shared_core;

// Public API - Clean Barrel (single source of truth)

export 'models.dart'; // All core models
export 'config.dart'; // Config layer (DesignTokens, BrandingConfig, etc.)
export 'constants.dart'; // Constants
export 'utils.dart'; // All utils

// Core providers (all used by main.dart)
export 'src/core/providers/franchise_provider.dart';
export 'src/core/providers/admin_user_provider.dart';
export 'src/core/providers/franchise_subscription_provider.dart';
export 'src/core/providers/platform_plan_selection_provider.dart';
export 'src/core/providers/franchise_info_provider.dart';
export 'src/core/providers/franchise_feature_provider.dart';
export 'src/core/providers/ingredient_metadata_provider.dart';
export 'src/core/providers/ingredient_type_provider.dart';
export 'src/core/providers/onboarding_progress_provider.dart';
export 'src/core/providers/onboarding_review_provider.dart';
export 'src/core/providers/payout_filter_provider.dart';
export 'src/core/providers/restaurant_type_provider.dart';
export 'src/core/providers/franchisee_invitation_provider.dart';
export 'src/core/providers/category_provider.dart';
export 'src/core/providers/menu_item_provider.dart';
export 'src/core/providers/role_guard.dart';
export 'src/core/providers/user_profile_provider.dart';
export 'src/core/providers/platform_financials_provider.dart';

// Core services (all used by main.dart)
export 'src/core/services/auth_service.dart';
export 'src/core/services/auth_service_impl.dart';
export 'src/core/services/firestore_service.dart';
export 'src/core/services/inventory_ledger.dart';
export 'src/core/services/firestore_service_impl.dart';
export 'src/core/services/franchise_subscription_service.dart';
export 'src/core/services/franchise_feature_service.dart';
export 'src/core/services/franchisee_invitation_service.dart';
export 'src/core/services/franchise_onboarding_service.dart';
export 'src/core/services/audit_log_service.dart';
export 'src/core/services/analytics_service.dart';
export 'src/core/services/analytics_service_impl.dart';
export 'src/core/services/mock_payment_service.dart';
export 'src/core/services/admin_auth_audit_service.dart';
export 'src/core/services/firebase_storage_service.dart';
export 'src/core/services/invoice_service.dart';
export 'src/core/services/notification_service.dart';
export 'src/core/services/payout_service.dart';
export 'src/core/services/promo_service.dart';
export 'src/core/services/pos_firestore_service.dart';
export 'src/core/services/labor_firestore_service.dart';
export 'src/core/services/promo_pricing.dart';

// Bounded-context repositories (Phase A — docs/slices/bounded-context-repos-v1.md)
export 'src/core/repositories/menu_repository.dart';
export 'src/core/repositories/menu_firestore_repository.dart';
export 'src/core/repositories/config_repository.dart';
export 'src/core/repositories/config_firestore_repository.dart';

// Enrichment
export 'src/core/services/enrichment/franchise_subscription_enricher.dart';

// Firebase (for convenience in web-app)
export 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;

// Domain exports
export 'src/core/domain/menu_pricing.dart';
export 'src/core/domain/menu_customization_selection.dart';
