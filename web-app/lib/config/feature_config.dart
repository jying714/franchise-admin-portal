import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:shared_core/shared_core.dart' show FeatureConfig;

/// Firebase loader for feature toggles
/// Wraps shared_core instance
class FeatureConfigLoader {
  static final Logger _logger = Logger('FeatureConfigLoader');

  /// Load and apply to shared instance
  static Future<void> load(String franchiseId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('features')
          .get();

      final data = doc.data() ?? {};
      FeatureConfig.instance.apply(data);
    } catch (e, stk) {
      _logger.severe('Error loading feature toggles', e, stk);
    }
  }
}
