import '../../../services/dynamic_loan_api.dart'; // Import Service
import '../../../services/dynamic_deposit_api.dart'; // Import Deposit Service
import '../../auth/domain/user_role.dart';
import '../domain/loan_repository.dart';
import '../domain/loan_application_model.dart';
import '../domain/loan_product_model.dart';

class LoanRepositoryImpl implements LoanRepository {
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
    String? depositAccountId,
    String? depositAccountNumber,
    String? depositAccountName,
  }) async {
    // Generate Application ID
    final applicationId = 'REQ-${DateTime.now().millisecondsSinceEpoch}';
    
    // Mock Applicant Info (In real app, fetch from User Profile Service)
    final applicantInfo = {
      'memberid': memberId,
      'prefix': 'คุณ',
      'firstname': CurrentUser.name.split(' ').first,
      'lastname': CurrentUser.name.split(' ').length > 1 ? CurrentUser.name.split(' ').last : '',
      'idcard': '1234567890123',
      'salary': 35000.0,
      'currentdebt': 12000.0,
      'mobile': '0812345678',
      'email': 'member@coop.com',
    };

    // Prepare Guarantor List
    List<Map<String, dynamic>> guarantors = [];
    if (guarantorType != null) {
      if (guarantorType == 'member' && guarantorMemberId != null) {
         guarantors.add({
           'memberid': guarantorMemberId,
           'name': 'สมาชิกสหกรณ์ (Mock)', // In real app, fetch name by ID
           'relationship': 'เพื่อนสมาชิก', // Default for member
           'salary': 0.0,
         });
      } else if (guarantorType == 'external') {
         guarantors.add({
           'memberid': '', // No member ID for external
           'name': guarantorName ?? 'ไม่ระบุ',
           'relationship': guarantorRelationship ?? 'ไม่ระบุ',
           'salary': guarantorSalary ?? 0.0,
         });
      }
    }

    // สร้าง payload ที่มี key ครบทุกครั้ง
    final data = {
      'applicationid': applicationId,
      'memberid': memberId, // Root level memberid
      'applicantinfo': applicantInfo, // Nested applicant info
      
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
      
      // บัญชีรับเงินกู้
      'depositaccountid': depositAccountId,
      'depositaccountnumber': depositAccountNumber,
      'depositaccountname': depositAccountName,
      
      // ข้อมูลหลักประกัน/ผู้ค้ำ
      'securityinfo': {
        'guarantors': guarantors,
        'collaterals': [],
      },
      
      // เอกสารแนบ (Documents Array structure)
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
      
      // สถานะ
      'status': 'pending',
      'createdat': DateTime.now().toIso8601String(),
    };
    
    await DynamicLoanApiService.createLoan(data);
  }

  @override
  Future<List<LoanApplication>> getLoanApplications() async {
    try {
      // Example filter: get all for current user (need memberId)
      // Build filter based on role
      final filter = <String, dynamic>{};
      
      // If not officer, filter by memberId to show only own loans
      if (!CurrentUser.isOfficerOrApprover) {
        filter['memberid'] = CurrentUser.id;
      }
      
      final response = await DynamicLoanApiService.getLoans(filter);
      
      if (response['status'] == 'success') {
        if (response['data'] is List) {
          final List<dynamic> data = response['data'];
          return data.map((json) => LoanApplication.fromJson(json)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error loading loan applications: $e');
      return [];
    }
  }

  @override
  Future<List<LoanProduct>> getLoanProducts() async {
    try {
      final response = await DynamicLoanApiService.getLoanProducts();
      
      if (response['status'] == 'success') {
        if (response['data'] is List) {
          final List<dynamic> data = response['data'];
          return data.map((json) => LoanProduct.fromJson(json)).toList();
        }
        return [];
      }
      return [];
    } catch (e) {
      print('Error loading loan products: $e');
      return [];
    }
  }

  @override
  Future<void> updateLoanStatus(String applicationId, LoanApplicationStatus status, {String? comment}) async {
    // Convert Enum to String compatible with API (e.g. 'approved', 'rejected')
    String statusStr = status.name;
    await DynamicLoanApiService.updateLoanStatus(applicationId, statusStr, comment: comment);
    
    // If approved, deposit loan amount to the selected account
    if (status == LoanApplicationStatus.approved) {
      await _depositLoanToAccount(applicationId);
    }
  }
  
  /// ฝากเงินกู้เข้าบัญชีที่ผู้กู้เลือกไว้
  Future<void> _depositLoanToAccount(String applicationId) async {
    try {
      // 1. ดึงข้อมูล loan application
      final response = await DynamicLoanApiService.getLoans({'applicationid': applicationId});
      
      if (response['status'] != 'success' || response['data'] is! List || (response['data'] as List).isEmpty) {
        print('Loan application not found for deposit');
        return;
      }
      
      final loanData = (response['data'] as List).first;
      final depositAccountId = loanData['depositaccountid'];
      final requestAmount = (loanData['requestamount'] ?? 0.0).toDouble();
      
      // ถ้าไม่มี depositAccountId ให้ skip
      if (depositAccountId == null || depositAccountId.toString().isEmpty) {
        print('No deposit account specified for this loan');
        return;
      }
      
      // 2. ดึงข้อมูลบัญชีเพื่อหายอดเงินปัจจุบัน
      final accountData = await DynamicDepositApiService.getAccountById(depositAccountId);
      if (accountData == null) {
        print('Deposit account not found: $depositAccountId');
        return;
      }
      
      final currentBalance = (accountData['balance'] ?? 0.0).toDouble();
      
      // 3. ฝากเงินกู้เข้าบัญชี
      await DynamicDepositApiService.deposit(
        accountId: depositAccountId,
        amount: requestAmount,
        currentBalance: currentBalance,
        description: 'รับเงินกู้ - $applicationId',
      );
      
      print('Loan amount $requestAmount deposited to account $depositAccountId');
    } catch (e) {
      print('Error depositing loan to account: $e');
      // ไม่ throw error เพื่อไม่ให้กระทบการอนุมัติ
    }
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
  }) async {
    await DynamicLoanApiService.recordPayment(
      applicationId: applicationId,
      memberId: CurrentUser.id,
      installmentNo: installmentNo,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentType: paymentType,
      installmentCount: installmentCount,
      slipImageUrl: slipImagePath,
    );
  }

  /// Save (create or update) a loan product
  Future<void> saveLoanProduct(LoanProduct product) async {
    await DynamicLoanApiService.createOrUpdateLoanProduct(product.toJson());
  }

  /// Delete a loan product
  Future<void> deleteLoanProduct(String productId) async {
    await DynamicLoanApiService.deleteLoanProduct(productId);
  }
}
