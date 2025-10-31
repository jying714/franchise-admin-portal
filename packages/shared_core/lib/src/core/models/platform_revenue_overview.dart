// File: lib/core/models/platform_revenue_overview.dart
class PlatformRevenueOverview {
  final double totalRevenueYtd;
  final double subscriptionRevenue;
  final double royaltyRevenue;
  final double overdueAmount;

  PlatformRevenueOverview({
    required this.totalRevenueYtd,
    required this.subscriptionRevenue,
    required this.royaltyRevenue,
    required this.overdueAmount,
  });
}
