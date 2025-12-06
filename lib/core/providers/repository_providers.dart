import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coop_digital_app/features/loan/domain/loan_repository.dart';
import 'package:coop_digital_app/features/loan/data/firebase_loan_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  // In real app, we might check if Firebase is initialized.
  // For now, assume it is or handle errors in Repository.
  return FirebaseLoanRepository(FirebaseFirestore.instance);
});
