import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/loan_repository.dart';
import '../domain/loan_application_model.dart';
import '../domain/loan_product_model.dart';

class FirebaseLoanRepository implements LoanRepository {
  final FirebaseFirestore _firestore;

  FirebaseLoanRepository(this._firestore);

  @override
  Future<void> submitApplication({
    required String productId,
    required double amount,
    required int months,
    String? guarantorId,
    String? objective,
  }) async {
    await _firestore.collection('loan_applications').add({
      'productId': productId, // "Ordinary", "Emergency"
      'requestAmount': amount,
      'months': months,
      'guarantorId': guarantorId,
      'objective': objective,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
      'memberId': 'user_001', // Mock User ID for now
    });
  }

  @override
  Future<List<LoanApplication>> getLoanApplications() async {
    // TODO: Implement fetching from Firestore
    return [];
  }

  @override
  Future<List<LoanProduct>> getLoanProducts() {
    // TODO: Implement fetching loan products from Firestore
    throw UnimplementedError();
  }
}
