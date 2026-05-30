/// App-wide configuration for deep linking, schemes, and white-label foundations (P2).
class AppConfig {
  AppConfig._();

  // Custom scheme for deep links / QR (e.g. fhq://f/{franchiseId})
  static const String deepLinkScheme = 'fhq';
  static const String deepLinkHost = 'f';

  // Web / universal link fallback (used for QR data + external sharing)
  static const String webDeepLinkHost = 'franchisehq.io';
  static const String webDeepLinkScheme = 'https';

  /// Builds a shareable / QR-encodable URL for a franchise.
  static String buildFranchiseDeepLink(String franchiseId, {String? name}) {
    final uri = Uri(
      scheme: webDeepLinkScheme,
      host: webDeepLinkHost,
      path: '/f/$franchiseId',
      queryParameters: name != null && name.isNotEmpty ? {'name': name} : null,
    );
    return uri.toString();
  }

  /// Alternative custom-scheme version (useful for installed app direct launch)
  static String buildCustomSchemeLink(String franchiseId) {
    return '$deepLinkScheme://$deepLinkHost/$franchiseId';
  }

  // Future: other app config (feature flags moved to FeatureConfig, etc.)
}
