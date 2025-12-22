import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'dynamic_notification_api.dart'; // Assuming this exists or will be reused
import 'dynamic_deposit_api.dart'; // Reusing some helper methods if needed, or just copying logic

/// API Service deals with withdrawals (Connected to MongoDB)
class DynamicWithdrawalApiService {
  
  /// ดึงข้อมูลบัญชี (reuse logic from Deposit API essentially)
  static Future<Map<String, dynamic>?> getAccountById(String accountId) async {
    // Re-implementing locally to avoid circular dependency if Deposit API imports this
    // or just using DynamicDepositApiService if it's safe. 
    // To be safe and clean, I will just call the endpoint directly here.
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_accounts',
        'filter': {'accountid': accountId},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List && (result['data'] as List).isNotEmpty) {
        return (result['data'] as List).first;
      }
      return null;
    } else {
      throw Exception('Failed to get account: ${response.body}');
    }
  }

  static Future<void> updateAccountBalance({
    required String accountId,
    required double newBalance,
  }) async {
     final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_accounts',
        'filter': {'accountid': accountId},
        'data': {'balance': newBalance},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update account balance: ${response.body}');
    }
  }

  /// สร้างรายการถอนเงิน (สถานะ Pending) และหักเงินทันที
  static Future<void> createWithdrawalRequest({
    required String accountId,
    required double amount,
    required String bankName,
    required String bankAccountNo,
    String? remark, // e.g. details
  }) async {
    final now = DateTime.now();

    // 1. ตรวจสอบยอดเงิน
    final account = await getAccountById(accountId);
    if (account == null) throw Exception('ไม่พบข้อมูลบัญชี');

    final currentBalance = (account['balance'] ?? 0.0).toDouble();
    if (amount > currentBalance) {
      throw Exception('ยอดเงินในบัญชีไม่เพียงพอ');
    }

    // 2. หักเงินทันที
    final newBalance = currentBalance - amount;

    // 3. สร้าง Transaction (Pending)
    final data = {
      'transactionid': 'txn_${now.millisecondsSinceEpoch}',
      'accountid': accountId,
      'type': 'withdrawal',
      'amount': amount,
      'balanceafter': newBalance,
      'datetime': now.toIso8601String(),
      'description': 'ถอนเงินเข้า $bankName $bankAccountNo (รอดำเนินการ)',
      'referenceno': bankAccountNo, // Use bank account no as ref
      'status': 'pending',
      'remark': remark,
      'destination_bank': bankName,
      'destination_account': bankAccountNo,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'data': data,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
       // If transaction creation failed, ideally we shouldn't have updated balance yet.
       // But here we haven't updated balance yet.
      throw Exception('Failed to create withdrawal request: ${response.body}');
    }

    // 4. Update Account Balance ONLY after transaction record is created successfully
    await updateAccountBalance(accountId: accountId, newBalance: newBalance);
  }
  
  // Note: Skipping other methods as they seem to have been updated in previous tool calls 
  // but I must be careful. The user error log shows errors at line 93, 114... which are inside methods.
  // I am replacing the top part of the file to fix import and variable.
  // And also fixing specific usages in methods covered by this range.


  /// ดึงรายการถอนเงินที่รอตรวจสอบ (Pending)
  static Future<List<Map<String, dynamic>>> getPendingWithdrawals() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {
            'status': 'pending',
            'type': 'withdrawal'
        },
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get pending withdrawals: ${response.body}');
    }
  }

  /// อนุมัติการถอนเงิน
  static Future<void> approveWithdrawal(String transactionId) async {
    // 1. Get Transaction
    final txResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'transactionid': transactionId},
      }),
    );
     if (txResponse.statusCode != 200) throw Exception('Failed to fetch transaction details');
    final txResult = jsonDecode(txResponse.body);
    final txList = txResult['data'] as List;
    if (txList.isEmpty) throw Exception('Transaction not found');
    final transaction = txList.first;

    if (transaction['status'] != 'pending') throw Exception('Transaction is not pending');

    // 2. Update Status to Completed
    // We already deducted the money, so just update status and description
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'transactionid': transactionId},
        'data': {
          'status': 'completed',
          'description': 'ถอนเงินสำเร็จ (อนุมัติแล้ว)',
          // 'approved_at': DateTime.now().toIso8601String(), // Optional
        },
      }),
    );

    // 3. Notification
     try {
       final account = await getAccountById(transaction['accountid']);
      if (account != null && account['memberid'] != null) {
        await DynamicNotificationApiService.createNotification(
          memberId: account['memberid'],
          title: 'รายการถอนเงินสำเร็จ',
          message: 'คำขอถอนเงินของคุณได้รับการอนุมัติแล้ว',
          type: 'success',
        );
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

    /// ปฏิเสธการถอนเงิน (คืนเงิน)
  static Future<void> rejectWithdrawal(String transactionId, {String? reason}) async {
    // 1. Get Transaction
    final txResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'transactionid': transactionId},
      }),
    );
    if (txResponse.statusCode != 200) throw Exception('Failed to fetch transaction details');
    final txResult = jsonDecode(txResponse.body);
    final txList = txResult['data'] as List;
    if (txList.isEmpty) throw Exception('Transaction not found');
    final transaction = txList.first;

    if (transaction['status'] != 'pending') throw Exception('Transaction is not pending');

    final accountId = transaction['accountid'];
    final amount = (transaction['amount'] ?? 0.0).toDouble();

    // 2. Mark Withdrawal as Rejected
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'transactionid': transactionId},
        'data': {
          'status': 'rejected',
          'description': 'รายการถอนเงินถูกปฏิเสธ - ${reason ?? "ไม่ระบุเหตุผล"}',
        },
      }),
    );

    // 3. Refund (Create Deposit Transaction)
    final account = await getAccountById(accountId);
    if (account == null) throw Exception('Account not found');
    final currentBalance = (account['balance'] ?? 0.0).toDouble();
    final newBalance = currentBalance + amount;

    final refundData = {
      'transactionid': 'txn_refund_${DateTime.now().millisecondsSinceEpoch}',
      'accountid': accountId,
      'type': 'deposit', // Refund -> Deposit
      'amount': amount,
      'balanceafter': newBalance,
      'datetime': DateTime.now().toIso8601String(),
      'description': 'คืนเงิน (ถอนเงินถูกปฏิเสธ)',
      'status': 'completed', 
    };

    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'data': refundData,
      }),
    );

    // 4. Update Account Balance (Add money back)
    await updateAccountBalance(accountId: accountId, newBalance: newBalance);

    // 5. Notification
    try {
      if (account['memberid'] != null) {
        await DynamicNotificationApiService.createNotification(
          memberId: account['memberid'],
          title: 'รายการถอนเงินถูกปฏิเสธ',
          message: 'คำขอถอนเงินของคุณถูกปฏิเสธและคืนเงินเข้าบัญชี: ${reason ?? ""}',
          type: 'error',
        );
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

}
