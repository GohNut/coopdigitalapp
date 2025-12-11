
import 'loan_product_model.dart';

class LoanRequestArgs {
  final LoanProduct product;
  final double amount;
  final int months;
  final double monthlyPayment;
  final double totalInterest;
  final double totalPayment;
  
  // Info step data
  final String? objective;
  final String? guarantorMemberId;
  
  // Document step data
  final String? idCardFileName;
  final String? salarySlipFileName;
  final String? otherFileName;

  LoanRequestArgs({
    required this.product,
    required this.amount,
    required this.months,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalPayment,
    this.objective,
    this.guarantorMemberId,
    this.idCardFileName,
    this.salarySlipFileName,
    this.otherFileName,
  });

  /// Create a copy with updated values
  LoanRequestArgs copyWith({
    LoanProduct? product,
    double? amount,
    int? months,
    double? monthlyPayment,
    double? totalInterest,
    double? totalPayment,
    String? objective,
    String? guarantorMemberId,
    String? idCardFileName,
    String? salarySlipFileName,
    String? otherFileName,
  }) {
    return LoanRequestArgs(
      product: product ?? this.product,
      amount: amount ?? this.amount,
      months: months ?? this.months,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      totalInterest: totalInterest ?? this.totalInterest,
      totalPayment: totalPayment ?? this.totalPayment,
      objective: objective ?? this.objective,
      guarantorMemberId: guarantorMemberId ?? this.guarantorMemberId,
      idCardFileName: idCardFileName ?? this.idCardFileName,
      salarySlipFileName: salarySlipFileName ?? this.salarySlipFileName,
      otherFileName: otherFileName ?? this.otherFileName,
    );
  }
}
