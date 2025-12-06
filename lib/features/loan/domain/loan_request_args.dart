
import 'loan_product_model.dart';

class LoanRequestArgs {
  final LoanProduct product;
  final double amount;
  final int months;
  final double monthlyPayment;
  final double totalInterest;
  final double totalPayment;

  LoanRequestArgs({
    required this.product,
    required this.amount,
    required this.months,
    required this.monthlyPayment,
    required this.totalInterest,
    required this.totalPayment,
  });
}
