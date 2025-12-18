import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_digital_app/features/loan/domain/loan_repository.dart';
import 'package:coop_digital_app/features/loan/data/loan_repository_impl.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepositoryImpl();
});
