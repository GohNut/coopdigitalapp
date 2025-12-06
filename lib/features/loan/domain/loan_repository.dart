abstract class LoanRepository {
  Future<void> submitApplication({
    required String productId,
    required double amount,
    required int months,
    String? guarantorId,
    String? objective,
  });
}
