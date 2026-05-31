/// Pure Dart QR payload utilities for franchise white-label deep linking and QR codes.
/// 
/// Payload format (custom scheme for foundations):
///   fhq://f/{franchiseId}
///   fhq://f/{franchiseId}?name=EncodedName
///
/// This is the data encoded *into* the visual QR code.
/// Used by:
/// - Profile / share section to generate displayable franchise QR
/// - QrScanScreen + deep link handler to parse and switch FranchiseProvider
///
/// No Flutter / native deps. Safe for shared_core barrel.

/// Generates the deep-link / QR payload string for a given franchise.
String generateFranchiseQR(
  String franchiseId, {
  String? name,
  String scheme = 'fhq',
}) {
  if (franchiseId.isEmpty) {
    throw ArgumentError('franchiseId cannot be empty');
  }

  var payload = '$scheme://f/$franchiseId';
  if (name != null && name.isNotEmpty) {
    payload += '?name=${Uri.encodeComponent(name)}';
  }
  return payload;
}

/// Parses a scanned or deep-linked QR payload and returns structured data.
/// Returns at minimum {'franchiseId': '...', 'name': '...' }
Map<String, String> parseFranchiseQR(String qrContent) {
  final trimmed = qrContent.trim();
  if (trimmed.isEmpty) {
    return {'franchiseId': '', 'name': ''};
  }

  try {
    final uri = Uri.parse(trimmed);

    // Standard fhq://f/{id} or https://franchisehq.io/f/{id}
    if (uri.pathSegments.length >= 2) {
      final first = uri.pathSegments[0];
      if (first == 'f' || first == 'franchise') {
        final id = uri.pathSegments[1];
        if (id.isNotEmpty) {
          return {
            'franchiseId': id,
            'name': uri.queryParameters['name'] ?? uri.queryParameters['n'] ?? '',
          };
        }
      }
    }

    // Fallback: https://.../f/123 or raw id
    if (trimmed.contains('/f/')) {
      final afterF = trimmed.split('/f/').last;
      final id = afterF.split('?').first.split('#').first;
      if (id.isNotEmpty) {
        return {
          'franchiseId': id,
          'name': Uri.splitQueryString(trimmed.split('?').lastOrNull ?? '')['name'] ?? '',
        };
      }
    }
  } catch (_) {
    // not a uri, treat as raw franchise id (test data etc)
  }

  // Last resort: treat whole content as franchiseId (allows manual paste of just the id)
  return {'franchiseId': trimmed, 'name': ''};
}

/// Convenience: returns true if the payload looks like a valid franchise QR.
bool isFranchiseQR(String data) {
  final parsed = parseFranchiseQR(data);
  return parsed['franchiseId']!.isNotEmpty;
}

/// Returns a user-friendly display string for the franchise from QR data.
String getFranchiseDisplayFromQR(String qrData) {
  final p = parseFranchiseQR(qrData);
  final name = p['name'];
  if (name != null && name.isNotEmpty) {
    return '$name (${p['franchiseId']})';
  }
  return p['franchiseId']!;
}
