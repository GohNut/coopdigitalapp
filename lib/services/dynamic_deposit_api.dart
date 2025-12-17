import 'dart:convert';
import 'package:http/http.dart' as http;

/// API Service สำหรับจัดการบัญชีเงินฝาก (เชื่อมต่อ MongoDB)
class DynamicDepositApiService {
  static const String _baseUrl = 'https://member.rspcoop.com/api/v1/loan';

  /// ดึงข้อมูลสมาชิกจากเลขบัตรประชาชน (Member ID)
  static Future<Map<String, dynamic>?> getMember(String citizenId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'members',
        'filter': {'memberid': citizenId},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List && (result['data'] as List).isNotEmpty) {
        return (result['data'] as List).first;
      }
      return null;
    } else {
      throw Exception('Failed to get member: ${response.body}');
    }
  }

  /// สร้างสมาชิกใหม่
  static Future<Map<String, dynamic>> createMember({
    required String citizenId, // ใช้เป็น memberid
    required String nameTh,
    required String mobile,
    String? email,
    String? password, // For new registration
    String? pin, // PIN for transactions
    Map<String, dynamic>? additionalData, // For storing occupation, address, etc.
  }) async {
    final now = DateTime.now();
    
    final data = <String, dynamic>{
      'memberid': citizenId,
      'name_th': nameTh,
      'mobile': mobile,
      'role': 'member',
      'created_at': now.toIso8601String(),
    };

    // Add optional fields
    if (email != null && email.isNotEmpty) data['email'] = email;
    if (password != null && password.isNotEmpty) data['password'] = password;
    if (pin != null && pin.isNotEmpty) data['pin'] = pin;
    
    // Merge additional data (occupation, spouse info, etc.)
    if (additionalData != null) {
      data.addAll(additionalData);
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'members',
        'data': data,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return {...result, 'memberid': citizenId};
    } else {
      throw Exception('Failed to create member: ${response.body}');
    }
  }

  /// สร้างบัญชีใหม่
  static Future<Map<String, dynamic>> createAccount({
    required String memberId,
    required String accountNumber,
    required String accountName,
    required String accountType, // savings, fixed, special
    required double interestRate,
    int? fixedTermMonths, // สำหรับบัญชีประจำ
  }) async {
    final now = DateTime.now();
    final accountId = 'acc_${now.millisecondsSinceEpoch}';

    final data = {
      'accountid': accountId,
      'memberid': memberId,
      'accountnumber': accountNumber,
      'accountname': accountName,
      'accounttype': accountType,
      'balance': 0.0,
      'interestrate': interestRate,
      'accruedinterest': 0.0,
      'openeddate': now.toIso8601String(),
      'createdat': now.toIso8601String(),
    };

    if (fixedTermMonths != null) {
      data['fixedtermmonths'] = fixedTermMonths;
      data['maturitydate'] = now.add(Duration(days: fixedTermMonths * 30)).toIso8601String();
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_accounts',
        'data': data,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final result = jsonDecode(response.body);
      return {...result, 'accountid': accountId};
    } else {
      throw Exception('Failed to create account: ${response.body}');
    }
  }

  /// ดึงบัญชีทั้งหมดของสมาชิก
  static Future<List<Map<String, dynamic>>> getAccounts(String memberId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_accounts',
        'filter': {'memberid': memberId},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get accounts: ${response.body}');
    }
  }

  /// ดึงบัญชีตาม ID
  static Future<Map<String, dynamic>?> getAccountById(String accountId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
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

  /// ดึงบัญชีตาม Account Number
  static Future<Map<String, dynamic>?> getAccountByNumber(String accountNumber) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_accounts',
        'filter': {'accountnumber': accountNumber},
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

  /// ดึงรายการเดินบัญชี
  static Future<List<Map<String, dynamic>>> getTransactions(String accountId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'accountid': accountId},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get transactions: ${response.body}');
    }
  }

  /// เพิ่มรายการเดินบัญชี (ฝาก/ถอน/โอน)
  static Future<Map<String, dynamic>> addTransaction({
    required String accountId,
    required String type, // deposit, withdrawal, transferIn, transferOut, interest, fee
    required double amount,
    required double balanceAfter,
    String? description,
    String? referenceNo,
  }) async {
    final now = DateTime.now();
    final transactionId = 'txn_${now.millisecondsSinceEpoch}';

    final data = {
      'transactionid': transactionId,
      'accountid': accountId,
      'type': type,
      'amount': amount,
      'balanceafter': balanceAfter,
      'datetime': now.toIso8601String(),
      'description': description,
      'referenceno': referenceNo,
    };

    final response = await http.post(
      Uri.parse('$_baseUrl/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'data': data,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to add transaction: ${response.body}');
    }
  }

  /// อัพเดทยอดเงินในบัญชี
  static Future<Map<String, dynamic>> updateAccountBalance({
    required String accountId,
    required double newBalance,
    double? accruedInterest,
  }) async {
    final data = <String, dynamic>{
      'balance': newBalance,
    };

    if (accruedInterest != null) {
      data['accruedinterest'] = accruedInterest;
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_accounts',
        'filter': {'accountid': accountId},
        'data': data,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update account balance: ${response.body}');
    }
  }

  /// ฝากเงินเข้าบัญชี (convenience method)
  static Future<void> deposit({
    required String accountId,
    required double amount,
    required double currentBalance,
    String? description,
  }) async {
    final newBalance = currentBalance + amount;

    // 1. เพิ่มรายการเดินบัญชี
    await addTransaction(
      accountId: accountId,
      type: 'deposit',
      amount: amount,
      balanceAfter: newBalance,
      description: description ?? 'ฝากเงิน',
    );

    // 2. อัพเดทยอดเงิน
    await updateAccountBalance(accountId: accountId, newBalance: newBalance);
  }

  /// ถอนเงินจากบัญชี (convenience method)
  static Future<void> withdraw({
    required String accountId,
    required double amount,
    required double currentBalance,
    String? description,
  }) async {
    if (amount > currentBalance) {
      throw Exception('ยอดเงินไม่เพียงพอ');
    }

    final newBalance = currentBalance - amount;

    // 1. เพิ่มรายการเดินบัญชี
    await addTransaction(
      accountId: accountId,
      type: 'withdrawal',
      amount: amount,
      balanceAfter: newBalance,
      description: description ?? 'ถอนเงิน',
    );

    // 2. อัพเดทยอดเงิน
    await updateAccountBalance(accountId: accountId, newBalance: newBalance);
  }

  /// จ่ายเงิน (สำหรับ Scan & Pay) - ใช้ transaction type 'payment'
  static Future<void> payment({
    required String accountId,
    required double amount,
    required double currentBalance,
    String? description,
    String? merchantId,
  }) async {
    if (amount > currentBalance) {
      throw Exception('ยอดเงินไม่เพียงพอ');
    }

    final newBalance = currentBalance - amount;

    // 1. เพิ่มรายการเดินบัญชี (ใช้ type = 'payment')
    await addTransaction(
      accountId: accountId,
      type: 'payment',
      amount: amount,
      balanceAfter: newBalance,
      description: description ?? 'จ่ายเงิน',
      referenceNo: merchantId,
    );

    // 2. อัพเดทยอดเงิน
    await updateAccountBalance(accountId: accountId, newBalance: newBalance);
  }

  /// โอนเงินระหว่างบัญชี (convenience method)
  static Future<void> transfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amount,
    String? description,
  }) async {
    // 1. Get source account balance
    final sourceAccount = await getAccountById(sourceAccountId);
    if (sourceAccount == null) throw Exception('ไม่พบข้อมูลบัญชีต้นทาง');
    final sourceBalance = (sourceAccount['balance'] ?? 0.0).toDouble();

    if (amount > sourceBalance) {
      throw Exception('ยอดเงินในบัญชีไม่เพียงพอ');
    }

    // 2. Get destination account balance
    final destAccount = await getAccountById(destinationAccountId);
    if (destAccount == null) throw Exception('ไม่พบข้อมูลบัญชีปลายทาง');
    final destBalance = (destAccount['balance'] ?? 0.0).toDouble();

    // 3. Withdraw from source
    final newSourceBalance = sourceBalance - amount;
    await addTransaction(
      accountId: sourceAccountId,
      type: 'transfer_out',
      amount: amount,
      balanceAfter: newSourceBalance,
      description: 'โอนออกไปบัญชี ${destAccount['accountname']}',
      referenceNo: destinationAccountId,
    );
    await updateAccountBalance(accountId: sourceAccountId, newBalance: newSourceBalance);

    // 4. Deposit to destination
    final newDestBalance = destBalance + amount;
    await addTransaction(
      accountId: destinationAccountId,
      type: 'transfer_in',
      amount: amount,
      balanceAfter: newDestBalance,
      description: 'โอนเข้าจากบัญชี ${sourceAccount['accountname']}',
      referenceNo: sourceAccountId,
    );
    await updateAccountBalance(accountId: destinationAccountId, newBalance: newDestBalance);
  }

  /// อัพเดทข้อมูลสมาชิก
  static Future<void> updateMember({
    required String memberId,
    Map<String, dynamic>? data,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'members',
        'filter': {'memberid': memberId},
        'data': data,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update member: ${response.body}');
    }
  }
}
