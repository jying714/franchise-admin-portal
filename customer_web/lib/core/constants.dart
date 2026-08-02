// customer_web/lib/core/constants.dart
/// Customer storefront entry & tenancy locks (Decision 11 + Hosting model).
///
/// Hosting model (locked):
/// - One Firebase Hosting site for customer_web.
/// - Platform host (e.g. order.franchisehq.io) serves all franchises via path.
/// - Optional: franchise CNAME → same Hosting site; hostname resolved to franchiseId.
///
/// Bind priority at runtime:
/// 1. Path /f/{franchiseId}  (always works — QR / SMS / no custom domain)
/// 2. Hostname lookup        (domain_index / storefrontDomain — Phase 10+)
/// 3. No franchise           → landing (no silent default tenant)

class CustomerWebConstants {
  CustomerWebConstants._();

  /// Path segment used in /f/{franchiseId}
  static const String franchisePathPrefix = 'f';

  /// Platform host examples (informational; not enforced in v1 code).
  static const String platformHostExample = 'order.franchisehq.io';

  /// Firestore collection for hostname → franchiseId (future).
  /// Doc id = normalized hostname (lowercase, no port).
  /// Field: franchiseId (string).
  static const String domainIndexCollection = 'domain_index';

  /// Optional field on franchises/{id} (future HQ publish).
  static const String storefrontDomainField = 'storefrontDomain';
  static const String storefrontUrlField = 'storefrontUrl';
}
