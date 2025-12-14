import '../domain/models/share_model.dart';
import '../domain/models/share_transaction.dart';

/// Abstract interface สำหรับ Share Repository
/// กำหนดเมธอดที่จำเป็นสำหรับการจัดการหุ้นสหกรณ์
abstract class ShareRepository {
  /// ดึงข้อมูลหุ้นของสมาชิก
  Future<ShareModel> getShareInfo();

  /// ซื้อหุ้นเพิ่ม
  Future<void> buyShare({
    required int units,
    required double amount,
    required String paymentMethod,
    required String paymentSourceId,
  });

  /// ดึงประวัติการทำรายการหุ้น
  Future<List<ShareTransaction>> getShareHistory();

  /// ตรวจสอบว่าสามารถขายหุ้นได้หรือไม่ (ใช้สำหรับอนาคต)
  Future<bool> checkSellEligibility();

  /// เปลี่ยนยอดส่งรายเดือน (ยังไม่ได้ implement)
  Future<bool> changeMonthlySubscription(double amount);
}
