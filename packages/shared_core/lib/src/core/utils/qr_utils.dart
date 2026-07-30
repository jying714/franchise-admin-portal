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

  /// Prefer https so phone cameras and online QR tools open a real URL.
  /// Custom scheme `fhq` remains supported by [parseFranchiseQR].
  String scheme = 'https',
  String host = 'franchisehq.io',
}) {
  if (franchiseId.isEmpty) {
    throw ArgumentError('franchiseId cannot be empty');
  }

  final String payload;
  if (scheme == 'fhq') {
    payload = 'fhq://f/$franchiseId';
  } else {
    payload = '$scheme://$host/f/$franchiseId';
  }
  if (name != null && name.isNotEmpty) {
    return '$payload?name=${Uri.encodeComponent(name)}';
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

  String nameFrom(Uri uri) =>
      uri.queryParameters['name'] ?? uri.queryParameters['n'] ?? '';

  try {
    final uri = Uri.parse(trimmed);

    // fhq://f/{id}  → host is "f", path is /{id}
    if ((uri.scheme == 'fhq' ||
            uri.scheme == 'https' ||
            uri.scheme == 'http') &&
        uri.host == 'f' &&
        uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first.trim();
      if (_isSafeFranchiseId(id)) {
        return {'franchiseId': id, 'name': nameFrom(uri)};
      }
    }

    // https://franchisehq.io/f/{id}  or  .../franchise/{id}
    if (uri.pathSegments.length >= 2) {
      final first = uri.pathSegments[0];
      if (first == 'f' || first == 'franchise') {
        final id = uri.pathSegments[1].trim();
        if (_isSafeFranchiseId(id)) {
          return {'franchiseId': id, 'name': nameFrom(uri)};
        }
      }
    }

    if (trimmed.contains('/f/')) {
      final afterF = trimmed.split('/f/').last;
      final id = afterF.split('?').first.split('#').first.trim();
      if (_isSafeFranchiseId(id)) {
        return {
          'franchiseId': id,
          'name': nameFrom(Uri.parse(
              trimmed.contains('://') ? trimmed : 'https://x?$trimmed')),
        };
      }
    }
  } catch (_) {}

  // Raw id only (no path separators)
  if (_isSafeFranchiseId(trimmed)) {
    return {'franchiseId': trimmed, 'name': ''};
  }

  return {'franchiseId': '', 'name': ''};
}

bool _isSafeFranchiseId(String id) {
  if (id.isEmpty || id == 'unknown') return false;
  // Document ids must not contain '/' or the Firestore path is not a document.
  if (id.contains('/')) return false;
  if (id.contains(' ') || id.contains('\n')) return false;
  return true;
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
