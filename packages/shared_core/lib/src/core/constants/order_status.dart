/// Canonical order status strings for station + shared order lifecycle.
///
/// [Order.status] remains a free-form [String] for backward compatibility with
/// existing mobile/web values. New POS writes should use these constants.
/// Legacy mobile values (e.g. placed, delivered) remain valid on read.
class OrderStatus {
  OrderStatus._();

  // --- Station MVP lifecycle (Decision 14) ---
  static const String draft = 'draft';
  static const String open = 'open';
  static const String needsApproval = 'needs_approval';
  static const String sentToKitchen = 'sent_to_kitchen';
  static const String ready = 'ready';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  // --- Existing customer-channel values still seen in the wild ---
  static const String placed = 'placed';
  static const String delivered = 'delivered';
  static const String preparing = 'preparing';

  /// Statuses the open-order board treats as active (not terminal).
  static const List<String> openBoardStatuses = <String>[
    draft,
    open,
    needsApproval,
    sentToKitchen,
    ready,
    placed,
    preparing,
  ];

  /// Terminal statuses (leave the active board by default).
  static const List<String> terminalStatuses = <String>[
    completed,
    cancelled,
    delivered,
  ];

  static bool isTerminal(String status) {
    final s = status.toLowerCase().trim();
    return terminalStatuses.contains(s);
  }

  static bool isOnOpenBoard(String status) {
    final s = status.toLowerCase().trim();
    return openBoardStatuses.contains(s);
  }
}
