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
    required String productName,
    required double interestRate,
    required double amount,
    required int months,
    required double monthlyPayment,
    required double totalInterest,
    required double totalPayment,
    String? objective,
    String? guarantorType,
    String? guarantorMemberId,
    String? guarantorName,
    String? guarantorRelationship,
    double? guarantorSalary,
    String? idCardFileName,
    String? salarySlipFileName,
    String? otherFileName,
    required String memberId,
  }) async {
    await _firestore.collection('loan_applications').add({
      // ข้อมูลผลิตภัณฑ์
      'productid': productId,
      'productname': productName,
      'interestrate': interestRate,
      
      // ข้อมูลวงเงินและการคำนวณ
      'requestamount': amount,
      'requestterm': months,
      'monthlypayment': monthlyPayment,
      'totalinterest': totalInterest,
      'totalpayment': totalPayment,
      
      // ข้อมูลการกู้
      'purpose': objective,
      
      // ข้อมูลหลักประกัน/ผู้ค้ำ
      'securityinfo': {
        'guarantors': [
          if (guarantorType != null) {
            if (guarantorType == 'member' && guarantorMemberId != null) 
               {
                 'memberid': guarantorMemberId,
                 'name': 'สมาชิกสหกรณ์ (Mock)',
                 'relationship': 'เพื่อนสมาชิก',
                 'salary': 0.0,
               }
            else if (guarantorType == 'external') 
               {
                 'memberid': '',
                 'name': guarantorName ?? 'ไม่ระบุ',
                 'relationship': guarantorRelationship ?? 'ไม่ระบุ',
                 'salary': guarantorSalary ?? 0.0,
               }
          }
        ],
        'collaterals': [],
      },
      
      // เอกสารแนบ
      'documents': [
        if (idCardFileName != null) {
          'type': 'id_card',
          'name': idCardFileName,
          'status': 'pending',
        },
        if (salarySlipFileName != null) {
          'type': 'salary_slip',
          'name': salarySlipFileName,
          'status': 'pending',
        },
        if (otherFileName != null) {
          'type': 'other',
          'name': otherFileName, // In real app, this might be multiple files
          'status': 'pending',
        },
      ],
      
      // สถานะและข้อมูลระบบ
      'status': 'pending',
      'createdat': FieldValue.serverTimestamp(),
      'memberid': memberId,
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
  @override
  Future<void> updateLoanStatus(String applicationId, LoanApplicationStatus status, {String? comment}) async {
    // TODO: Implement status update in Firestore
    throw UnimplementedError();
  }

  @override
  Future<void> makePayment({
    required String applicationId,
    required int installmentNo,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    int installmentCount = 1,
    String? slipImagePath,
    String? sourceAccountId,
  }) async {
    // TODO: Implement payment recording in Firestore
    throw UnimplementedError();
  }

  @override
  Future<void> submitAdditionalDocuments({
    required String applicationId,
    required List<String> fileNames,
  }) async {
    // TODO: Implement document submission in Firestore
    throw UnimplementedError();
  }
}
