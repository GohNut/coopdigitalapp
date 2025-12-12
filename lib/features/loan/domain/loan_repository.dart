import 'loan_application_model.dart';
import 'loan_product_model.dart';

abstract class LoanRepository {
  Future<void> submitApplication({
    required String productId,
    required double amount,
    required int months,
    String? guarantorId,
    String? objective,
  });

  Future<List<LoanApplication>> getLoanApplications();
  Future<List<LoanProduct>> getLoanProducts();
}
