import 'dart:convert';
import 'package:http/http.dart' as http;

class DynamicLoanApiService {
  // เปลี่ยนเป็น IP ของเครื่อง Server หรือ localhost (สำหรับ Android Emulator ใช้ 10.0.2.2)
  static const String _baseUrl = 'https://member.rspcoop.com/api/v1/loan';
  
  static Future<Map<String, dynamic>> createLoan(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_applications',
        'data': data,
        'upsert': true,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create loan: ${response.body}');
    }
  }
  
  static Future<Map<String, dynamic>> updateLoanStatus(String applicationId, String status, {String? comment}) async {
    final data = {
      'applicationid': applicationId,
      'status': status,
    };
    
    if (comment != null) {
      data['officercomment'] = comment;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/create'), // Using create for upsert
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_applications',
        'data': data,
        'upsert': true, // Important: This tells the API to update if exists
        'key': 'applicationid', // Tell API which field is the unique key
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update loan status: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getLoans(Map<String, dynamic> filter, {int? limit, int? skip}) async {
    final body = {
      'collection': 'loan_applications',
      'filter': filter,
    };
    if (limit != null) body['limit'] = limit;
    if (skip != null) body['skip'] = skip;

    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get loans: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> getLoanProducts() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_products',
        'filter': {}, // Empty filter to get all
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get loan products: ${response.body}');
    }
  }

  /// Record a loan payment
  /// - For advance payments: creates separate records for each installment
  /// - For full payoff: creates one record and marks loan as closed
  static Future<Map<String, dynamic>> recordPayment({
    required String applicationId,
    required String memberId,
    required int installmentNo,
    required double amount,
    required String paymentMethod,
    required String paymentType,
    int installmentCount = 1,
    String? slipImageUrl,
  }) async {
    final paymentId = 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    
    // 1. Get current loan application first
    final getLoanResponse = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_applications',
        'filter': {'applicationid': applicationId},
      }),
    );

    if (getLoanResponse.statusCode != 200) {
      throw Exception('Could not fetch loan application');
    }

    final getLoanData = jsonDecode(getLoanResponse.body);
    if (getLoanData['status'] != 'success' || getLoanData['data'] is! List || (getLoanData['data'] as List).isEmpty) {
      throw Exception('Loan application not found');
    }

    final currentLoan = (getLoanData['data'] as List).first;
    final requestAmount = (currentLoan['requestamount'] ?? 0.0).toDouble();
    final requestTerm = currentLoan['requestterm'] ?? 12;
    final currentPaidAmount = (currentLoan['paidamount'] ?? 0.0).toDouble();
    final currentPaidInstallments = currentLoan['paidinstallments'] ?? 0;
    
    // Calculate per-installment amounts
    final singleInstallmentAmount = amount / installmentCount;
    final singlePrincipal = singleInstallmentAmount * 0.85;
    final singleInterest = singleInstallmentAmount * 0.15;
    
    // Get existing payment history or create empty array
    List<dynamic> paymentHistory = List<dynamic>.from(currentLoan['paymenthistory'] ?? []);
    
    // 2. Create payment records based on payment type
    if (paymentType == 'full_payoff') {
      // FULL PAYOFF: Create one combined record and mark remaining installments
      final remainingInstallments = requestTerm - currentPaidInstallments;
      
      final payoffRecord = {
        'installmentno': installmentNo,
        'installmentend': requestTerm, // Shows range like "งวดที่ 68-96"
        'duedate': now.toIso8601String(),
        'paiddate': now.toIso8601String(),
        'principalamount': amount * 0.90, // More principal for payoff
        'interestamount': amount * 0.10,
        'totalamount': amount,
        'status': 'paid',
        'paymentmethod': paymentMethod,
        'receiptno': paymentId,
        'paymenttype': 'payoff', // Badge: ปิดยอดกู้
        'note': 'ปิดยอดกู้ทั้งหมด $remainingInstallments งวด',
      };
      paymentHistory.add(payoffRecord);
      
      // Create payment record in loan_payments collection
      await http.post(
        Uri.parse('$_baseUrl/create'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'collection': 'loan_payments',
          'data': {
            'paymentid': paymentId,
            'applicationid': applicationId,
            'memberid': memberId,
            'installmentno': installmentNo,
            'installmentend': requestTerm,
            'amount': amount,
            'paymentmethod': paymentMethod,
            'paymenttype': 'full_payoff',
            'status': 'completed',
            'createdat': now.toIso8601String(),
          },
        }),
      );
      
      // Update loan as CLOSED
      await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'collection': 'loan_applications',
          'filter': {'applicationid': applicationId},
          'data': {
            'paymenthistory': paymentHistory,
            'paidamount': requestAmount, // Fully paid
            'paidinstallments': requestTerm, // All installments paid
            'remainingamount': 0.0,
            'status': 'closed', // Mark as closed
            'closedat': now.toIso8601String(),
          },
        }),
      );
      
    } else {
      // NORMAL or ADVANCE: Create separate records for each installment
      for (int i = 0; i < installmentCount; i++) {
        final currentInstallmentNo = installmentNo + i;
        final receiptNo = installmentCount > 1 
            ? '$paymentId-${i + 1}' 
            : paymentId;
        
        final paymentRecord = {
          'installmentno': currentInstallmentNo,
          'duedate': now.add(Duration(days: 30 * i)).toIso8601String(),
          'paiddate': now.toIso8601String(),
          'principalamount': singlePrincipal,
          'interestamount': singleInterest,
          'totalamount': singleInstallmentAmount,
          'status': 'paid',
          'paymentmethod': paymentMethod,
          'receiptno': receiptNo,
          'paymenttype': installmentCount > 1 ? 'advance' : 'normal', // Badge
        };
        paymentHistory.add(paymentRecord);
        
        // Create individual payment record in loan_payments collection
        await http.post(
          Uri.parse('$_baseUrl/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'collection': 'loan_payments',
            'data': {
              'paymentid': receiptNo,
              'applicationid': applicationId,
              'memberid': memberId,
              'installmentno': currentInstallmentNo,
              'amount': singleInstallmentAmount,
              'paymentmethod': paymentMethod,
              'paymenttype': paymentType,
              'status': 'completed',
              'createdat': now.toIso8601String(),
            },
          }),
        );
      }
      
      // Calculate new values
      final newPaidAmount = currentPaidAmount + amount;
      final newPaidInstallments = currentPaidInstallments + installmentCount;
      final newRemainingAmount = requestAmount - newPaidAmount;
      
      // Update loan application
      await http.post(
        Uri.parse('$_baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'collection': 'loan_applications',
          'filter': {'applicationid': applicationId},
          'data': {
            'paymenthistory': paymentHistory,
            'paidamount': newPaidAmount,
            'paidinstallments': newPaidInstallments,
            'remainingamount': newRemainingAmount,
          },
        }),
      );
    }

    return {
      'status': 'success',
      'paymentId': paymentId,
      'paymentType': paymentType,
      'installmentCount': installmentCount,
    };
  }

  /// Get payments for a loan application
  static Future<Map<String, dynamic>> getPayments(String applicationId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_payments',
        'filter': {'applicationid': applicationId},
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get payments: ${response.body}');
    }
  }

  /// Create or update a loan product (for officers)
  /// Uses /update endpoint with upsert: true for proper upsert behavior
  static Future<Map<String, dynamic>> createOrUpdateLoanProduct(Map<String, dynamic> data) async {
    final productId = data['productid'];
    
    final response = await http.post(
      Uri.parse('$_baseUrl/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_products',
        'filter': {'productid': productId}, // Filter by productid
        'data': data,
        'upsert': true, // Create if not exists, update if exists
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save loan product: ${response.body}');
    }
  }

  /// Delete a loan product
  static Future<Map<String, dynamic>> deleteLoanProduct(String productId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/delete'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_products',
        'filter': {'productid': productId},
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to delete loan product: ${response.body}');
    }
  }

  static Future<Map<String, dynamic>> submitAdditionalDocuments(String applicationId, List<Map<String, dynamic>> newDocs) async {
    // 1. Fetch current to get existing
    final getResponse = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_applications',
        'filter': {'applicationid': applicationId},
      }),
    );

    List<dynamic> existingDocs = [];
    if (getResponse.statusCode == 200) {
      final json = jsonDecode(getResponse.body);
      if (json['status'] == 'success' && json['data'] is List && (json['data'] as List).isNotEmpty) {
        final loan = (json['data'] as List).first;
        existingDocs = loan['additional_documents'] ?? [];
      }
    }

    // 2. Append new docs
    final updatedDocs = [...existingDocs, ...newDocs];

    // 3. Update
    final response = await http.post(
      Uri.parse('$_baseUrl/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'loan_applications',
        'filter': {'applicationid': applicationId},
        'data': {
          'additional_documents': updatedDocs,
          'status': 'pending', // Reset status to pending for review
        },
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to submit documents: ${response.body}');
    }
  }
}
