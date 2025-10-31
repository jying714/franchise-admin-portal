import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/promo.dart';

class PromoService {
  late final FirebaseFirestore _db;
  final Logger _logger = Logger('PromoService');

  PromoService() {
    _db = FirebaseFirestore.instance;
  }

  // Apply a promo to the cart
  Future<bool> applyPromo(String franchiseId, String promoId, String userId,
      List<dynamic> cartItems) async {
    try {
      DocumentSnapshot promoDoc = await _db
          .collection('franchises')
          .doc(franchiseId)
          .collection('promotions')
          .doc(promoId)
          .get();

      if (!promoDoc.exists) {
        _logger.warning('Promo $promoId does not exist');
        return false;
      }

      Promo promo =
          Promo.fromFirestore(promoDoc.data() as Map<String, dynamic>, promoId);

      if (!promo.active || promo.endDate.isBefore(DateTime.now())) {
        _logger.warning('Promo $promoId is inactive or expired');
        return false;
      }

      // Validate minimum order value
      double cartTotal = cartItems.fold(
          0.0, (total, item) => total + (item['price'] * item['quantity']));
      if (cartTotal < promo.minOrderValue) {
        _logger.warning(
            'Cart total $cartTotal is below promo minimum ${promo.minOrderValue}');
        return false;
      }

      // Validate applicable items
      if (promo.items.isNotEmpty) {
        bool validItems =
            cartItems.any((item) => promo.items.contains(item['itemId']));
        if (!validItems) {
          _logger.warning('No applicable items for promo $promoId');
          return false;
        }
      }

      // Check max uses
      if (promo.maxUses > 0) {
        if (promo.maxUsesType == 'total') {
          QuerySnapshot uses = await _db
              .collection('franchises')
              .doc(franchiseId)
              .collection('orders')
              .where('promoId', isEqualTo: promoId)
              .get();
          if (uses.docs.length >= promo.maxUses) {
            _logger.warning('Promo $promoId has reached max uses');
            return false;
          }
        } else if (promo.maxUsesType == 'per_user') {
          QuerySnapshot uses = await _db
              .collection('franchises')
              .doc(franchiseId)
              .collection('orders')
              .where('userId', isEqualTo: userId)
              .where('promoId', isEqualTo: promoId)
              .get();
          if (uses.docs.length >= promo.maxUses) {
            _logger.warning(
                'User $userId has reached max uses for promo $promoId');
            return false;
          }
        }
      }

      // Apply promo to cart (update cart with discount)
      _logger.info('Applying promo $promoId to cart for user $userId');
      // TODO: Update cart with promo discount
      return true;
    } catch (e) {
      _logger.severe('Error applying promo $promoId: $e');
      return false;
    }
  }

  // Fetch available promos
  Stream<List<Promo>> getAvailablePromos(String franchiseId) {
    return _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('promotions')
        .where('active', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.now())
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Promo.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
