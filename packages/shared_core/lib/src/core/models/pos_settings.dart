class PosSettings {
  final String franchiseId;

  /// When false, large-order hold is disabled.
  final bool largeOrderThresholdEnabled;

  /// Dollar threshold (null = not used).
  final double? largeOrderAmountThreshold;

  /// Item-count threshold (null = not used).
  final int? largeOrderItemCountThreshold;

  /// Max split tenders (Decision 14 default: 3).
  final int maxSplitTenders;

  /// Prep / promised time in minutes.
  final int prepTimeMinutes;

  /// PIN session idle timeout in minutes.
  final int pinSessionTimeoutMinutes;

  /// Auto-print kitchen ticket when card order is paid.
  final bool autoPrintOnCardPaid;

  /// Auto-print kitchen ticket when cash tender completes.
  final bool autoPrintOnCashPaid;

  /// Auto-print when an online (mobile/web) order enters the board.
  final bool autoPrintOnOnlineOrder;

  /// Default tip prompt percents (e.g. 15, 18, 20). Empty = no prompts.
  final List<double> defaultTipPercents;

  PosSettings({
    required this.franchiseId,
    this.largeOrderThresholdEnabled = false,
    this.largeOrderAmountThreshold,
    this.largeOrderItemCountThreshold,
    this.maxSplitTenders = 3,
    this.prepTimeMinutes = 20,
    this.pinSessionTimeoutMinutes = 15,
    this.autoPrintOnCardPaid = true,
    this.autoPrintOnCashPaid = true,
    this.autoPrintOnOnlineOrder = true,
    this.defaultTipPercents = const <double>[15, 18, 20],
  });

  factory PosSettings.defaults(String franchiseId) {
    return PosSettings(franchiseId: franchiseId);
  }

  factory PosSettings.fromFirestore(
      Map<String, dynamic> data, String franchiseId) {
    final tipsRaw = data['defaultTipPercents'];
    final tips = tipsRaw is List
        ? tipsRaw
            .map((e) => (e as num?)?.toDouble())
            .whereType<double>()
            .toList()
        : const <double>[15, 18, 20];

    return PosSettings(
      franchiseId: franchiseId,
      largeOrderThresholdEnabled:
          data['largeOrderThresholdEnabled'] as bool? ?? false,
      largeOrderAmountThreshold:
          (data['largeOrderAmountThreshold'] as num?)?.toDouble(),
      largeOrderItemCountThreshold:
          data['largeOrderItemCountThreshold'] as int?,
      maxSplitTenders: data['maxSplitTenders'] as int? ?? 3,
      prepTimeMinutes: data['prepTimeMinutes'] as int? ?? 20,
      pinSessionTimeoutMinutes: data['pinSessionTimeoutMinutes'] as int? ?? 15,
      autoPrintOnCardPaid: data['autoPrintOnCardPaid'] as bool? ?? true,
      autoPrintOnCashPaid: data['autoPrintOnCashPaid'] as bool? ?? true,
      autoPrintOnOnlineOrder: data['autoPrintOnOnlineOrder'] as bool? ?? true,
      defaultTipPercents: tips.isEmpty ? const <double>[15, 18, 20] : tips,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'franchiseId': franchiseId,
      'largeOrderThresholdEnabled': largeOrderThresholdEnabled,
      'largeOrderAmountThreshold': largeOrderAmountThreshold,
      'largeOrderItemCountThreshold': largeOrderItemCountThreshold,
      'maxSplitTenders': maxSplitTenders,
      'prepTimeMinutes': prepTimeMinutes,
      'pinSessionTimeoutMinutes': pinSessionTimeoutMinutes,
      'autoPrintOnCardPaid': autoPrintOnCardPaid,
      'autoPrintOnCashPaid': autoPrintOnCashPaid,
      'autoPrintOnOnlineOrder': autoPrintOnOnlineOrder,
      'defaultTipPercents': defaultTipPercents,
    };
  }

  PosSettings copyWith({
    String? franchiseId,
    bool? largeOrderThresholdEnabled,
    double? largeOrderAmountThreshold,
    int? largeOrderItemCountThreshold,
    int? maxSplitTenders,
    int? prepTimeMinutes,
    int? pinSessionTimeoutMinutes,
    bool? autoPrintOnCardPaid,
    bool? autoPrintOnCashPaid,
    bool? autoPrintOnOnlineOrder,
    List<double>? defaultTipPercents,
  }) {
    return PosSettings(
      franchiseId: franchiseId ?? this.franchiseId,
      largeOrderThresholdEnabled:
          largeOrderThresholdEnabled ?? this.largeOrderThresholdEnabled,
      largeOrderAmountThreshold:
          largeOrderAmountThreshold ?? this.largeOrderAmountThreshold,
      largeOrderItemCountThreshold:
          largeOrderItemCountThreshold ?? this.largeOrderItemCountThreshold,
      maxSplitTenders: maxSplitTenders ?? this.maxSplitTenders,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      pinSessionTimeoutMinutes:
          pinSessionTimeoutMinutes ?? this.pinSessionTimeoutMinutes,
      autoPrintOnCardPaid: autoPrintOnCardPaid ?? this.autoPrintOnCardPaid,
      autoPrintOnCashPaid: autoPrintOnCashPaid ?? this.autoPrintOnCashPaid,
      autoPrintOnOnlineOrder:
          autoPrintOnOnlineOrder ?? this.autoPrintOnOnlineOrder,
      defaultTipPercents: defaultTipPercents ?? this.defaultTipPercents,
    );
  }
}
