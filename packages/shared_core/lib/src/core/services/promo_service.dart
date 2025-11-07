// packages/shared_core/lib/src/core/services/promo_service.dart

import '../models/promo.dart';

/// Pure interface — no Firebase, no Flutter
abstract class PromoService {
  /// Applies a promo code to the cart and returns true if successful
  Future<bool> applyPromo({
    required String franchiseId,
    required String promoId,
    required String userId,
    required List<dynamic> cartItems,
  });

  /// Streams available (active + not expired) promos for a franchise
  Stream<List<Promo>> getAvailablePromos(String franchiseId);
}
