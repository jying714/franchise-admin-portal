class ScheduledOrder {
  final String id;
  final String userId;
  final String franchiseId;
  final List<dynamic> items;
  final String frequency;
  final DateTime nextDate;
  final DateTime? endDate;
  final String status;

  ScheduledOrder({
    required this.id,
    this.userId = '',
    this.franchiseId = '',
    this.items = const [],
    this.frequency = 'weekly',
    DateTime? nextDate,
    this.endDate,
    this.status = 'active',
  }) : nextDate = nextDate ?? DateTime.now().add(Duration(days: 7));
}
