import '../../domain/models/share_model.dart';
import '../../domain/models/share_transaction.dart';

class MockShareRepository {
  Future<ShareModel> getShareInfo() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return ShareModel.mock();
  }

  Future<List<ShareTransaction>> getHistory() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      ShareTransaction(
        id: '1',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: ShareTransactionType.monthlyBuy,
        amount: 500.00, // 10 units * 50
        units: 10,
      ),
      ShareTransaction(
        id: '2',
        date: DateTime.now().subtract(const Duration(days: 15)),
        type: ShareTransactionType.dividend,
        amount: 5000.00,
        units: 0, // Dividend usually cash, or converted? Assuming cash for now based on prompt saying "get dividend"
      ),
      ShareTransaction(
        id: '3',
        date: DateTime.now().subtract(const Duration(days: 32)),
        type: ShareTransactionType.monthlyBuy,
        amount: 500.00,
        units: 10,
      ),
      ShareTransaction(
        id: '4',
        date: DateTime.now().subtract(const Duration(days: 45)),
        type: ShareTransactionType.extraBuy,
        amount: 2500.00,
        units: 50,
      ),
    ];
  }

  Future<bool> buyExtraShares(double amount) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Always success for mock
  }

  Future<bool> changeMonthlySubscription(double newAmount) async {
    await Future.delayed(const Duration(seconds: 1));
    return true; // Always success for mock
  }

  // Check if member can sell shares
  Future<bool> checkSellEligibility() async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: Eligible if total units > 100 (min holding)
    // For demo, we just return true or random, but let's say true for now.
    return true; 
  }

  Future<bool> sellShares(double amount) async {
    await Future.delayed(const Duration(seconds: 1));
    // In real app, would call API to process sell
    // Logic: 
    // 1. Validate units
    // 2. Reduce total units
    // 3. Credit wallet
    return true;
  }
}
