import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/deposit/data/deposit_providers.dart';
import '../../features/payment/data/payment_providers.dart';
import '../../features/notification/presentation/providers/notification_provider.dart';
import '../../features/home/presentation/widgets/wallet_card.dart';

/// Provider สำหรับควบคุมการ Refresh ข้อมูลทางการเงินทั้งหมดจากจุดเดียว
/// 
/// ระบบนี้จะทำการ invalidate providers ที่เกี่ยวข้องกับข้อมูลทางการเงิน
/// เพื่อให้ข้อมูลที่แสดงผลเป็นปัจจุบันที่สุดเสมอ
class FinancialRefreshNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Refresh ข้อมูลทางการเงินทั้งหมด
  /// 
  /// ฟังก์ชันนี้จะทำการ invalidate providers ต่างๆ และรอให้โหลดข้อมูลใหม่เสร็จ
  /// เพื่อให้สามารถแสดง Loading indicator ได้
  Future<void> refreshAll() async {
    state = const AsyncLoading();
    
    try {
      // 1. Invalidate deposit-related providers
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositExcludingLoanAsyncProvider);
      ref.invalidate(loanAccountBalanceAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      
      // 1.1 Invalidate payment sources (สำคัญ! เพื่อให้ยอดในเมนูจ่าย/รับอัปเดต)
      ref.invalidate(paymentSourcesProvider);
      
      // 2. Refresh notifications (ใช้ refresh() แทน invalidate เพื่อหลีกเลี่ยง LateInitializationError)
      await ref.read(notificationProvider.notifier).refresh();
      
      // 3. รอให้ deposit accounts โหลดเสร็จ (เป็น provider หลักที่ใช้ตรวจสอบ)
      await ref.read(depositAccountsAsyncProvider.future);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Refresh เฉพาะข้อมูล Deposit และ Loan (ใช้สำหรับหน้าที่เกี่ยวข้อง)
  Future<void> refreshDepositAndLoan() async {
    state = const AsyncLoading();
    
    try {
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositExcludingLoanAsyncProvider);
      ref.invalidate(loanAccountBalanceAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      
      // Invalidate payment sources (สำคัญ! เพื่อให้ยอดในเมนูจ่าย/รับอัปเดต)
      ref.invalidate(paymentSourcesProvider);
      
      await ref.read(depositAccountsAsyncProvider.future);
      
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Refresh เฉพาะ transactions ของบัญชีที่ระบุ
  Future<void> refreshTransactions(String accountId) async {
    ref.invalidate(depositTransactionsAsyncProvider(accountId));
    ref.invalidate(depositAccountByIdAsyncProvider(accountId));
    await ref.read(depositTransactionsAsyncProvider(accountId).future);
  }
}

/// Provider สำหรับ Financial Refresh Notifier
final financialRefreshProvider = AsyncNotifierProvider<FinancialRefreshNotifier, void>(
  FinancialRefreshNotifier.new,
);
