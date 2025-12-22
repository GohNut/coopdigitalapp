import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';

/// API Service สำหรับจัดการเงินปันผลสหกรณ์
class DynamicDividendApiService {
  /// ดึงอัตราปันผลล่าสุด
  static Future<Map<String, dynamic>> getDividendRates() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'dividend_rates',
        'filter': {},
      }),
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      if (result['status'] == 'success' && result['data'] is List && (result['data'] as List).isNotEmpty) {
        // เรียงตามปีล่าสุด
        final rates = result['data'] as List;
        rates.sort((a, b) => (b['year'] ?? 0).compareTo(a['year'] ?? 0));
        return rates.first;
      }
      // ถ้าไม่มีข้อมูล ให้สร้าง default
      return _createDefaultDividendRate();
    } else {
      throw Exception('Failed to get dividend rates: ${response.body}');
    }
  }

  /// สร้างอัตราปันผล default
  static Future<Map<String, dynamic>> _createDefaultDividendRate() async {
    final now = DateTime.now();
    final data = {
      'year': now.year,
      'rate': 5.5,  // อัตราปันผลเริ่มต้น 5.5%
      'announceddate': now.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'dividend_rates',
        'data': data,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      return data; // Return default even if save fails
    }
  }

  /// คำนวณปันผลของสมาชิก
  static Future<Map<String, dynamic>> calculateDividend(String memberId, int year) async {
    // 1. ดึงอัตราปันผลของปี
    final rateResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'dividend_rates',
        'filter': {'year': year},
      }),
    );

    double rate = 5.5; // default
    if (rateResponse.statusCode == 200) {
      final rateResult = jsonDecode(rateResponse.body);
      if (rateResult['status'] == 'success' && rateResult['data'] is List && (rateResult['data'] as List).isNotEmpty) {
        rate = ((rateResult['data'] as List).first['rate'] ?? 5.5).toDouble();
      }
    }

    // 2. ดึงข้อมูลหุ้นของสมาชิก
    final shareResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'share_accounts',
        'filter': {'memberid': memberId},
      }),
    );

    double averageShares = 0;
    double totalValue = 0;
    if (shareResponse.statusCode == 200) {
      final shareResult = jsonDecode(shareResponse.body);
      if (shareResult['status'] == 'success' && shareResult['data'] is List && (shareResult['data'] as List).isNotEmpty) {
        final shareData = (shareResult['data'] as List).first;
        totalValue = (shareData['totalvalue'] ?? 0.0).toDouble();
        // คำนวณหุ้นเฉลี่ย (สำหรับ MVP ใช้หุ้นปัจจุบัน)
        averageShares = totalValue;
      }
    }

    // 3. คำนวณปันผล
    final dividendAmount = averageShares * (rate / 100);

    // 4. ตรวจสอบว่ารับปันผลไปแล้วหรือยัง
    final historyResponse = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'dividend_payments',
        'filter': {'memberid': memberId, 'year': year},
      }),
    );

    String status = 'pending';
    if (historyResponse.statusCode == 200) {
      final historyResult = jsonDecode(historyResponse.body);
      if (historyResult['status'] == 'success' && historyResult['data'] is List && (historyResult['data'] as List).isNotEmpty) {
        status = 'paid';
      }
    }

    return {
      'rate': rate,
      'totalamount': dividendAmount,
      'year': year,
      'status': status,
      'averageshares': averageShares,
    };
  }

  /// ดึงประวัติรับปันผล
  static Future<List<Map<String, dynamic>>> getDividendHistory(String memberId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/get'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'dividend_payments',
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
      throw Exception('Failed to get dividend history: ${response.body}');
    }
  }

  /// ยื่นขอรับปันผล
  static Future<Map<String, dynamic>> requestDividendPayment({
    required String memberId,
    required int year,
    required double amount,
    required double rate,
    required String paymentMethod, // 'account' or 'share'
    String? depositAccountId,
  }) async {
    final now = DateTime.now();
    final paymentId = 'div_${now.millisecondsSinceEpoch}';

    final data = {
      'paymentid': paymentId,
      'memberid': memberId,
      'year': year,
      'amount': amount,
      'rate': rate,
      'paymentmethod': paymentMethod,
      'paymentdate': now.toIso8601String(),
      'depositaccountid': depositAccountId,
      'status': 'completed',
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/create'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'collection': 'dividend_payments',
        'data': data,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {...data, 'success': true};
    } else {
      throw Exception('Failed to request dividend payment: ${response.body}');
    }
  }
}
