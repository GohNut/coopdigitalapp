
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
  final String? guarantorType; // 'member' or 'external'
  final String? guarantorMemberId;
  final String? guarantorName;
  final String? guarantorRelationship;
  
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
    this.guarantorType,
    this.guarantorMemberId,
    this.guarantorName,
    this.guarantorRelationship,
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
    String? guarantorType,
    String? guarantorMemberId,
    String? guarantorName,
    String? guarantorRelationship,
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
      guarantorType: guarantorType ?? this.guarantorType,
      guarantorMemberId: guarantorMemberId ?? this.guarantorMemberId,
      guarantorName: guarantorName ?? this.guarantorName,
      guarantorRelationship: guarantorRelationship ?? this.guarantorRelationship,
      idCardFileName: idCardFileName ?? this.idCardFileName,
      salarySlipFileName: salarySlipFileName ?? this.salarySlipFileName,
      otherFileName: otherFileName ?? this.otherFileName,
    );
  }
}
