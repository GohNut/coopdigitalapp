import 'dart:convert';
import 'dart:typed_data'; // For Uint8List (web-compatible)
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
import 'dynamic_notification_api.dart';

/// API Service สำหรับจัดการบัญชีเงินฝาก (เชื่อมต่อ MongoDB)
class DynamicDepositApiService {
  
  /// ดึงข้อมูลสมาชิกจากเลขบัตรประชาชน (Member ID)
  static Future<Map<String, dynamic>?> getMember(String citizenId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
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
      Uri.parse('${ApiConfig.baseUrl}/create'),
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
      Uri.parse('${ApiConfig.baseUrl}/create'),
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
      Uri.parse('${ApiConfig.baseUrl}/get'),
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

  /// ดึงบัญชีตาม Account Number
  static Future<Map<String, dynamic>?> getAccountByNumber(String accountNumber) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
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
      Uri.parse('${ApiConfig.baseUrl}/get'),
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
      Uri.parse('${ApiConfig.baseUrl}/create'),
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
      Uri.parse('${ApiConfig.baseUrl}/update'),
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
      Uri.parse('${ApiConfig.baseUrl}/update'),
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

  /// อัปโหลดรูปโปรไฟล์สมาชิก (Web-compatible)
  static Future<Map<String, dynamic>> uploadProfileImage({
    required String memberId,
    required Uint8List imageBytes,
    required String filename,
  }) async {
    // ใช้ endpoint เดียวกับ Backend ที่แก้ไป: v1.POST("/upload-profile-image", ...)
    // ดังนั้น path คือ /api/v1/upload-profile-image
    final uri = Uri.parse('${ApiConfig.baseUrl}/upload-profile-image');
    var request = http.MultipartRequest('POST', uri);
    
    // Add member ID as a field
    request.fields['memberid'] = memberId;
    
    // Add image bytes (web-compatible)
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: filename,
    ));
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      final result = jsonDecode(responseBody);
      return result;
    } else {
      throw Exception('Failed to upload profile image: $responseBody');
    }
  }

  /// ดึง URL รูปโปรไฟล์สมาชิก ผ่าน backend proxy เพื่อหลีกเลี่ยง CORS
  static Future<Map<String, dynamic>?> getProfileImageUrl(String memberId) async {
    try {
      // 1. เรียก API ตรวจสอบข้อมูลรูปภาพ (ใช้ GET endpoint เดิมที่ return JSON)
      // v1.GET("/member/profile-image", ...) -> /api/v1/member/profile-image
      final checkUrl = '${ApiConfig.baseUrl}/member/profile-image?memberid=$memberId';
      final response = await http.get(Uri.parse(checkUrl));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        
        if (result['status'] == 'success') {
           // ได้ข้อมูลรูปภาพมาแล้ว ดึง version
           final version = result['version'];
           
           // สร้าง Proxy URL สำหรับแสดงผล (เพื่อแก้ CORS)
           // v1.GET("/member/profile-image/proxy", ...)
           final proxyUrl = '${ApiConfig.baseUrl}/member/profile-image/proxy?memberid=$memberId&v=$version';
           
           return {
             'url': proxyUrl,
             'version': version,
           };
        }
      }
      return null;
    } catch (e) {
      print('Failed to get profile image: $e');
      return null;
    }
  } 

  /// สร้างรายการฝากเงิน (รอดำเนินการ)พร้อมแนบสลิป
  static Future<void> createDepositRequest({
    required String accountId,
    required double amount,
    required String slipImagePath, // ใน API จริงอาจจะเป็น URL หรือ Base64, ในที่นี้สมมติส่ง path ไปก่อน
    String? referenceNo, // เช่น transaction Id ของ QR
  }) async {
    final now = DateTime.now();
    
    // เราจะสร้าง transaction สถานะ pending
    // ยังไม่ปรับยอดเงินในบัญชี
    
    // ดึง account เพื่อเอา balance ปัจจุบัน (แม้จะยังไม่ปรับยอด แต่เก็บไว้ใน record ได้)
    final account = await getAccountById(accountId);
    if (account == null) throw Exception('ไม่พบข้อมูลบัญชี');
    final currentBalance = (account['balance'] ?? 0.0).toDouble();

    final data = {
      'transactionid': 'txn_${now.millisecondsSinceEpoch}',
      'accountid': accountId,
      'type': 'deposit',
      'amount': amount,
      'balanceafter': currentBalance, // ยอดคงเหลือเท่าเดิมเพราะยังไม่ confirm
      'datetime': now.toIso8601String(),
      'description': 'ฝากเงิน (รอตรวจสอบ)',
      'referenceno': referenceNo,
      'status': 'pending',
      'slip_image': slipImagePath,
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
      throw Exception('Failed to create deposit request: ${response.body}');
    }
  }

  /// ดึงรายการที่สถานะ pending ทั้งหมด (สำหรับเจ้าหน้าที่)
  static Future<List<Map<String, dynamic>>> getPendingDeposits() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'status': 'pending'},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List) {
        return List<Map<String, dynamic>>.from(result['data']);
      }
      return [];
    } else {
      throw Exception('Failed to get pending deposits: ${response.body}');
    }
  }

  /// อนุมัติรายการฝากเงิน
  static Future<void> approveDeposit(String transactionId) async {
    // 1. ดึงรายการ transaction มาเพื่อดู details
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
    
    // 2. ดึง Account เพื่อ update balance
    final account = await getAccountById(accountId);
    if (account == null) throw Exception('Account not found');
    final currentBalance = (account['balance'] ?? 0.0).toDouble();
    final newBalance = currentBalance + amount;
    
    // 3. Update Transaction status -> completed & update balanceAfter
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/update'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'transactionid': transactionId},
        'data': {
          'status': 'completed',
          'description': 'ฝากเงิน (ยืนยันแล้ว)',
          'balanceafter': newBalance, // Update balance snapshot
        },
      }),
    );
    
    // 4. Update Account Balance
    await updateAccountBalance(accountId: accountId, newBalance: newBalance);

    // 5. Create Notification
    try {
      if (account['memberid'] != null) {
        await DynamicNotificationApiService.createNotification(
          memberId: account['memberid'],
          title: 'เงินฝากได้รับอนุมัติ',
          message: 'รายการฝากเงินของคุณได้รับการยืนยันแล้ว สามารถตรวจสอบยอดเงินได้ในบัญชี',
          type: 'success',
        );
      }
    } catch (e) {
      // Ignore notification error to avoid blocking the transaction
      print('Failed to send notification: $e');
    }
  }

  /// ปฏิเสธรายการฝากเงิน
  /// Logic:
  /// 1. ปรับรายการฝากให้เป็น "completed" (เงินเข้า)
  /// 2. สร้างรายการ "withdrawal" (เงินออก) ทันที
  /// เพื่อให้เห็นเส้นทางการเงินตามที่ User process
  static Future<void> rejectDeposit(String transactionId, {String? reason}) async {
    // 1. Approve it first (Deposit In)
    await approveDeposit(transactionId);
    
    // 2. Fetch transaction again to get info for withdrawal
    final txResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'deposit_transactions',
        'filter': {'transactionid': transactionId},
      }),
    );
    final transaction = (jsonDecode(txResponse.body)['data'] as List).first;
    final accountId = transaction['accountid'];
    final amount = (transaction['amount'] ?? 0.0).toDouble();
    
    // 3. Perform Withdrawal (Money Out)
    final account = await getAccountById(accountId);
    final currentBalance = (account!['balance'] ?? 0.0).toDouble();
    
    // เรียก method withdraw ที่มีอยู่แล้ว
    await withdraw(
      accountId: accountId,
      amount: amount,
      currentBalance: currentBalance,
      description: 'ยกเลิกรายการฝาก - ${reason ?? "ข้อมูลไม่ถูกต้อง"}',
    );
    
    // 4. Create Notification
    try {
      if (account['memberid'] != null) {
        await DynamicNotificationApiService.createNotification(
          memberId: account['memberid'],
          title: 'รายการฝากเงินถูกปฏิเสธ',
          message: 'รายการฝากเงินถูกยกเลิกเนื่องจาก: ${reason ?? "ข้อมูลไม่ถูกต้อง"}',
          type: 'error',
        );
      }
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }
}
