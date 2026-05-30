class Loyalty {
  final int points;
  final List<LoyaltyReward> redeemedRewards;
  final List<dynamic> transactions;

  Loyalty({
    this.points = 0,
    this.redeemedRewards = const [],
    this.transactions = const [],
  });
}

class LoyaltyReward {
  final String name;
  final int points;

  LoyaltyReward({required this.name, required this.points});
}
