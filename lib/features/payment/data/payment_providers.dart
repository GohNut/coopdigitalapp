import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/dynamic_deposit_api.dart';
import '../../../services/dynamic_loan_api.dart';
import '../../auth/domain/user_role.dart';
import '../../deposit/domain/deposit_account.dart';
import '../../deposit/data/deposit_providers.dart'; // Added import
import '../../loan/domain/loan_application_model.dart';
import '../domain/payment_source_model.dart';

// ============================================================================
// PAYMENT SOURCES PROVIDER - ดึงแหล่งเงินทั้งหมดที่ใช้จ่ายได้
// ============================================================================

/// Provider สำหรับดึงแหล่งเงินที่ใช้จ่ายได้ทั้งหมด
final paymentSourcesProvider = FutureProvider<List<PaymentSource>>((ref) async {
  final sources = <PaymentSource>[];
  final memberId = CurrentUser.id;
  if (memberId.isEmpty) return sources;

  // 1. ดึงบัญชีเงินฝากทั้งหมด
  try {
    final depositsData = await DynamicDepositApiService.getAccounts(memberId);
    for (final data in depositsData) {
      final balance = (data['balance'] ?? 0.0).toDouble();
      // แสดงบัญชีทั้งหมดที่มี แม้จะมียอดเป็น 0 (เพื่อให้ผู้ใช้เห็นว่ามีบัญชีแล้ว)
      // การตรวจสอบยอดเงินไม่พอ จะไปเช็คตอนทำรายการจ่าย
      if (balance >= 0) {
        sources.add(PaymentSource(
          type: PaymentSourceType.deposit,
          sourceId: data['accountid'] ?? '',
          sourceName: data['accountname'] ?? 'บัญชีเงินฝาก',
          accountNumber: data['accountnumber'],
          balance: balance,
          additionalInfo: _getAccountTypeDisplay(data['accounttype']),
        ));
      }
    }
  } catch (e) {
    print('Error fetching deposit accounts: $e');
  }

  // 2. ปิดการดึงวงเงินสินเชื่อตามที่ผู้ใช้ร้องขอ (สินเชื่อไม่ใช่วงเงินที่นำมาจ่ายได้)
  /*
  try {
    final loansResponse = await DynamicLoanApiService.getLoans({
      'memberid': memberId,
      'status': 'approved',
    });
    
    if (loansResponse['status'] == 'success' && loansResponse['data'] is List) {
      final loansData = loansResponse['data'] as List;
      for (final data in loansData) {
        final loan = LoanApplication.fromJson(data);
        final remainingAmount = loan.loanDetails.remainingAmount;
        
        if (remainingAmount > 0) {
          sources.add(PaymentSource(
            type: PaymentSourceType.loan,
            sourceId: loan.applicationId,
            sourceName: loan.productName,
            balance: remainingAmount,
            additionalInfo: 'สัญญา ${loan.applicationId}',
          ));
        }
      }
    }
  } catch (e) {
    print('Error fetching loan applications: $e');
  }
  */

  return sources;
});

/// Helper: แปลง account type เป็นข้อความแสดงผล
String _getAccountTypeDisplay(String? type) {
  switch (type?.toLowerCase()) {
    case 'savings':
      return 'ออมทรัพย์';
    case 'fixed':
      return 'ประจำ';
    case 'special':
      return 'พิเศษ';
    default:
      return 'ออมทรัพย์';
  }
}

// ============================================================================
// SELECTED SOURCE PROVIDER - เก็บแหล่งเงินที่เลือก
// ============================================================================

/// Notifier สำหรับเก็บ source ที่เลือก
class SelectedPaymentSourceNotifier extends Notifier<PaymentSource?> {
  @override
  PaymentSource? build() => null;

  void select(PaymentSource source) {
    state = source;
  }

  void clear() {
    state = null;
  }
}

final selectedPaymentSourceProvider = NotifierProvider<SelectedPaymentSourceNotifier, PaymentSource?>(
  SelectedPaymentSourceNotifier.new,
);

// ============================================================================
// PAYMENT ACTION PROVIDER - สำหรับทำรายการจ่ายเงิน
// ============================================================================

/// Notifier สำหรับทำรายการจ่ายเงิน
class PaymentActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// ทำรายการจ่ายเงิน
  Future<Map<String, dynamic>> pay({
    required PaymentSource source,
    required String merchantId,
    required String merchantName,
    required double amount,
    bool isInternal = false,
  }) async {
    state = const AsyncLoading();

    try {
      // ตรวจสอบยอดเงินก่อน
      if (amount > source.balance) {
        throw Exception('ยอดเงินไม่เพียงพอ');
      }

      if (source.type == PaymentSourceType.deposit) {
        // หักเงินจากบัญชีเงินฝาก
        if (isInternal) {
          final response = await DynamicDepositApiService.internalTransfer(
            sourceAccountId: source.sourceId,
            destAccountId: merchantId,
            amount: amount,
            description: 'โอนเงินให้ $merchantName',
          );
          
          final result = {
            'transaction_id': response['transaction_id'] ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}',
            'status': 'SUCCESS',
            'amount': amount,
            'source_type': source.type.name,
            'source_name': source.sourceName,
            'merchant_id': merchantId,
            'merchant_name': merchantName,
            'timestamp': DateTime.now().toIso8601String(),
            'slip_info': response['slip_info'], 
          };

          // Refresh deposit providers
          ref.invalidate(depositAccountsAsyncProvider);
          ref.invalidate(depositTransactionsAsyncProvider(source.sourceId));
          ref.invalidate(depositAccountByIdAsyncProvider(source.sourceId));
          ref.invalidate(totalDepositBalanceAsyncProvider);
          ref.invalidate(paymentSourcesProvider);

          state = const AsyncData(null);
          return result;
        } else {
          // จ่ายบิล/ร้านค้าทั่วไป
          await DynamicDepositApiService.payment(
            accountId: source.sourceId,
            amount: amount,
            currentBalance: source.balance,
            description: 'จ่ายเงินให้ $merchantName',
            merchantId: merchantId,
          );
          
          ref.invalidate(depositAccountsAsyncProvider);
          ref.invalidate(depositTransactionsAsyncProvider(source.sourceId));
          ref.invalidate(depositAccountByIdAsyncProvider(source.sourceId));
          ref.invalidate(totalDepositBalanceAsyncProvider);
          ref.invalidate(paymentSourcesProvider);
        }
      } else {
        // หักจากวงเงินสินเชื่อ - บันทึกเป็น payment
        await DynamicLoanApiService.recordPayment(
          applicationId: source.sourceId,
          memberId: CurrentUser.id,
          installmentNo: 0,
          amount: amount,
          paymentMethod: 'qr_payment',
          paymentType: 'spending',
        );
      }

      final result = {
        'transaction_id': 'PAY-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'SUCCESS',
        'amount': amount,
        'source_type': source.type.name,
        'source_name': source.sourceName,
        'merchant_id': merchantId,
        'merchant_name': merchantName,
        'timestamp': DateTime.now().toIso8601String(),
      };

      state = const AsyncData(null);
      return result;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final paymentActionProvider = AsyncNotifierProvider<PaymentActionNotifier, void>(
  PaymentActionNotifier.new,
);
