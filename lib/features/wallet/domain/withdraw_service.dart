class WithdrawService {
  Future<Map<String, dynamic>> withdraw({
    required String bankId,
    required String accountNo,
    required double amount,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(seconds: 2));

    if (amount < 100.0) {
      throw Exception('Withdrawal amount must be at least 100.00 THB');
    }

    // Mock Success Response
    return {
      'transaction_id': 'TXN-${DateTime.now().millisecondsSinceEpoch}',
      'status': 'SUCCESS',
      'amount': amount,
      'fee': 0.0, // Free for Co-op members?
      'remainder_balance': 9500.00 - amount, // Mock balance
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

final withdrawServiceProvider = WithdrawService();
