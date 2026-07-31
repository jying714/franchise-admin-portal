/// Station permission strings (Decision 14).
/// Must match values stored on [Staff.permissions].
class PosPermissions {
  PosPermissions._();

  static const String takeOrder = 'take_order';
  static const String takePayment = 'take_payment';
  static const String openDrawer = 'open_drawer';
  static const String voidItem = 'void_item';
  static const String voidOrder = 'void_order';
  static const String refund = 'refund';
  static const String discount = 'discount';
  static const String eightySixItem = '86_item';
  static const String viewOrders = 'view_orders';
  static const String manageTables = 'manage_tables';
  static const String changeSettings = 'change_settings';
  static const String approveLargeOrder = 'approve_large_order';
  static const String managerOverride = 'manager_override';

  /// Actions that always require a fresh re-PIN even if session is active.
  static const Set<String> elevatedRequiresRepin = <String>{
    voidItem,
    voidOrder,
    refund,
    eightySixItem,
    approveLargeOrder,
    changeSettings,
    managerOverride,
  };

  static const List<String> all = <String>[
    takeOrder,
    takePayment,
    openDrawer,
    voidItem,
    voidOrder,
    refund,
    discount,
    eightySixItem,
    viewOrders,
    manageTables,
    changeSettings,
    approveLargeOrder,
    managerOverride,
  ];
}
