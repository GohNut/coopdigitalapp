class ShareModel {
  final double totalValue;
  final int totalUnits;
  final double monthlyRate;
  final double dividendRate;
  final double shareParValue;
  final int minShareHolding; // Rule: Must hold at least this many units

  const ShareModel({
    required this.totalValue,
    required this.totalUnits,
    required this.monthlyRate,
    required this.dividendRate,
    this.shareParValue = 50.0,
    this.minShareHolding = 100, // Default minimum 100 units
  });

  // Factory for mock data
  factory ShareModel.mock() {
    return const ShareModel(
      totalValue: 125000.00,
      totalUnits: 2500, // Updated to match prompt
      monthlyRate: 500.00, // 10 units * 50 THB
      dividendRate: 5.0, // 5%
    );
  }
}
