import '../../../../services/dynamic_share_api.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/share_repository.dart';
import '../../domain/models/share_model.dart';
import '../../domain/models/share_transaction.dart';
import '../../domain/models/share_type.dart';

/// Implementation ของ ShareRepository ที่เชื่อมต่อกับ API จริง
class ShareRepositoryImpl implements ShareRepository {
  @override
  Future<ShareModel> getShareInfo() async {
    try {
      final data = await DynamicShareApiService.getShareInfo(CurrentUser.id);
      
      return ShareModel(
        totalValue: (data['totalvalue'] ?? 0.0).toDouble(),
        totalUnits: data['totalunits'] ?? 0,
        monthlyRate: (data['monthlyrate'] ?? 0.0).toDouble(),
        dividendRate: (data['dividendrate'] ?? 5.0).toDouble(),
        shareParValue: (data['shareparvalue'] ?? 50.0).toDouble(),
        minShareHolding: data['minshareholding'] ?? 100,
      );
    } catch (e) {
      print('Error loading share info: $e');
      // ถ้า error ให้คืนค่าเริ่มต้น
      return const ShareModel(
        totalValue: 0.0,
        totalUnits: 0,
        monthlyRate: 0.0,
        dividendRate: 5.0,
        shareParValue: 50.0,
        minShareHolding: 100,
      );
    }
  }

  @override
  Future<void> buyShare({
    required int units,
    required double amount,
    required String paymentMethod,
    required String paymentSourceId,
  }) async {
    await DynamicShareApiService.buyShare(
      memberId: CurrentUser.id,
      units: units,
      amount: amount,
      paymentMethod: paymentMethod,
      paymentSourceId: paymentSourceId,
    );
  }

  @override
  Future<List<ShareTransaction>> getShareHistory() async {
    try {
      final response = await DynamicShareApiService.getShareHistory(CurrentUser.id);
      
      if (response['status'] == 'success' && response['data'] is List) {
        final List<dynamic> data = response['data'];
        return data.map((json) {
          // แปลง type string เป็น enum
          ShareTransactionType type;
          switch (json['type']) {
            case 'buy':
            case 'extra_buy':
              type = ShareTransactionType.extraBuy;
              break;
            case 'monthly_buy':
              type = ShareTransactionType.monthlyBuy;
              break;
            case 'dividend':
              type = ShareTransactionType.dividend;
              break;
            default:
              type = ShareTransactionType.extraBuy;
          }

          return ShareTransaction(
            id: json['transactionid'] ?? '',
            date: DateTime.parse(json['createdat'] ?? DateTime.now().toIso8601String()),
            type: type,
            amount: (json['amount'] ?? 0.0).toDouble(),
            units: json['units'] ?? 0,
          );
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error loading share history: $e');
      return [];
    }
  }

  @override
  Future<bool> checkSellEligibility() async {
    // ตรวจสอบว่าถือหุ้นอย่างน้อย minShareHolding หรือไม่
    final shareInfo = await getShareInfo();
    return shareInfo.totalUnits >= shareInfo.minShareHolding;
  }

  @override
  Future<bool> changeMonthlySubscription(double amount) async {
    // TODO: Implement API call to change monthly subscription
    // ยังไม่ได้เชื่อมต่อกับ API จริง
    print('changeMonthlySubscription called with amount: $amount');
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    return true; // Return success for now
  }

  @override
  Future<List<ShareType>> getShareTypes() async {
    try {
      final list = await DynamicShareApiService.getShareTypes();
      return list.map((json) => ShareType.fromJson(json)).toList();
    } catch (e) {
      print('Error getting share types: $e');
      return [];
    }
  }

  @override
  Future<void> createShareType(ShareType shareType) async {
    await DynamicShareApiService.createShareType(shareType.toJson());
  }

  @override
  Future<void> updateShareType(ShareType shareType) async {
    await DynamicShareApiService.updateShareType(shareType.id, shareType.toJson());
  }

  @override
  Future<void> deleteShareType(String id) async {
    await DynamicShareApiService.deleteShareType(id);
  }
}
