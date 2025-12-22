import 'loan_application_model.dart';
import 'loan_product_model.dart';

abstract class LoanRepository {
  Future<void> submitApplication({
    required String productId,
    required String productName,
    required double interestRate,
    required double amount,
    required int months,
    required double monthlyPayment,
    required double totalInterest,
    required double totalPayment,
    String? objective,
    // Guarantor Info
    String? guarantorType,
    String? guarantorMemberId,
    String? guarantorName,
    String? guarantorRelationship,
    double? guarantorSalary,
    // Documents
    String? idCardFileName,
    String? salarySlipFileName,
    String? otherFileName,
    required String memberId,
  });

  Future<List<LoanApplication>> getLoanApplications({bool forOfficerReview = false});
  Future<List<LoanProduct>> getLoanProducts();
  Future<void> updateLoanStatus(String applicationId, LoanApplicationStatus status, {String? comment});
  
  Future<void> makePayment({
    required String applicationId,
    required int installmentNo,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    int installmentCount = 1,
    String? slipImagePath,
    String? sourceAccountId,
  });

  Future<void> submitAdditionalDocuments({
    required String applicationId,
    required List<String> fileNames,
  });
}
