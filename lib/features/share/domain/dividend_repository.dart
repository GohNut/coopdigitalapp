import '../domain/models/dividend_model.dart';

/// Abstract repository สำหรับจัดการเงินปันผล
abstract class DividendRepository {
  /// ดึงอัตราปันผลปัจจุบัน
  Future<DividendRate> getCurrentDividendRate();

  /// คำนวณปันผลของสมาชิกสำหรับปีที่กำหนด
  Future<DividendSummary> calculateDividend(int year);

  /// ดึงประวัติการรับปันผล
  Future<List<DividendHistory>> getDividendHistory();

  /// ยื่นขอรับปันผล
  Future<bool> requestPayment({
    required int year,
    required double amount,
    required double rate,
    required String paymentMethod, // 'account' or 'share'
    String? depositAccountId,
  });
}
