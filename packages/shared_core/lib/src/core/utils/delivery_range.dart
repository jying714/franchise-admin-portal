import 'dart:math' as math;

/// Pure radius check. Drive-time uses Google Distance Matrix later.
class DeliveryRange {
  DeliveryRange._();

  /// Great-circle distance in miles.
  static double haversineMiles({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const earthMiles = 3958.7613;
    final rLat1 = _rad(lat1);
    final rLat2 = _rad(lat2);
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(rLat1) *
            math.cos(rLat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthMiles * c;
  }

  /// `true` = within range or not enforced.
  /// [maxMiles] ≤ 0 → not enforced (HQ default).
  static bool withinRadiusMiles({
    required double storeLat,
    required double storeLon,
    required double customerLat,
    required double customerLon,
    required double maxMiles,
  }) {
    if (maxMiles <= 0) return true;
    final d = haversineMiles(
      lat1: storeLat,
      lon1: storeLon,
      lat2: customerLat,
      lon2: customerLon,
    );
    return d <= maxMiles;
  }

  static double _rad(double deg) => deg * math.pi / 180.0;
}
