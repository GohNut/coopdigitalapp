import '../../../auth/domain/user_role.dart';
import '../../domain/dividend_repository.dart';
import '../../domain/models/dividend_model.dart';
import '../../../../services/dynamic_dividend_api.dart';

/// Implementation ของ DividendRepository ที่ใช้ API จริง
class DividendRepositoryImpl implements DividendRepository {
  
  String get _memberId => CurrentUser.id;

  @override
  Future<DividendRate> getCurrentDividendRate() async {
    try {
      final data = await DynamicDividendApiService.getDividendRates();
      return DividendRate.fromJson(data);
    } catch (e) {
      // Return default rate on error
      return DividendRate(
        year: DateTime.now().year,
        rate: 5.5,
        announcedDate: DateTime.now(),
      );
    }
  }

  @override
  Future<DividendSummary> calculateDividend(int year) async {
    try {
      final data = await DynamicDividendApiService.calculateDividend(_memberId, year);
      return DividendSummary.fromJson(data);
    } catch (e) {
      return DividendSummary.empty(year);
    }
  }

  @override
  Future<List<DividendHistory>> getDividendHistory() async {
    try {
      final data = await DynamicDividendApiService.getDividendHistory(_memberId);
      return data.map((json) => DividendHistory.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> requestPayment({
    required int year,
    required double amount,
    required double rate,
    required String paymentMethod,
    String? depositAccountId,
  }) async {
    try {
      await DynamicDividendApiService.requestDividendPayment(
        memberId: _memberId,
        year: year,
        amount: amount,
        rate: rate,
        paymentMethod: paymentMethod,
        depositAccountId: depositAccountId,
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}
