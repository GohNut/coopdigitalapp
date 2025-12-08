import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/deposit_account.dart';
import '../domain/deposit_transaction.dart';

/// Provider สำหรับข้อมูลบัญชีเงินฝากทั้งหมดของสมาชิก
final depositAccountsProvider = Provider<List<DepositAccount>>((ref) {
  // Mock Data - จะเปลี่ยนเป็น API call จริงในอนาคต
  return [
    DepositAccount(
      id: 'acc_001',
      accountNumber: '101-2-12345-6',
      accountName: 'เงินฝากออมทรัพย์',
      accountType: AccountType.savings,
      balance: 150000.00,
      interestRate: 1.50,
      accruedInterest: 1875.00,
      openedDate: DateTime(2020, 3, 15),
    ),
    DepositAccount(
      id: 'acc_002',
      accountNumber: '102-3-67890-1',
      accountName: 'เงินฝากประจำ 12 เดือน',
      accountType: AccountType.fixed,
      balance: 500000.00,
      interestRate: 2.50,
      accruedInterest: 10416.67,
      openedDate: DateTime(2023, 1, 10),
    ),
    DepositAccount(
      id: 'acc_003',
      accountNumber: '103-4-11111-2',
      accountName: 'เงินฝากออมทรัพย์พิเศษ',
      accountType: AccountType.special,
      balance: 75000.00,
      interestRate: 2.00,
      accruedInterest: 1250.00,
      openedDate: DateTime(2022, 6, 20),
    ),
  ];
});

/// Provider สำหรับยอดเงินฝากรวมทุกบัญชี
final totalDepositBalanceProvider = Provider<double>((ref) {
  final accounts = ref.watch(depositAccountsProvider);
  return accounts.fold(0.0, (sum, account) => sum + account.balance);
});

/// Provider สำหรับรายละเอียดบัญชีตาม ID
final depositAccountByIdProvider = Provider.family<DepositAccount?, String>((ref, accountId) {
  final accounts = ref.watch(depositAccountsProvider);
  try {
    return accounts.firstWhere((a) => a.id == accountId);
  } catch (_) {
    return null;
  }
});

/// Provider สำหรับรายการเดินบัญชี (Mock Data)
final depositTransactionsProvider = Provider.family<List<DepositTransaction>, String>((ref, accountId) {
  // Mock transactions - จะเปลี่ยนเป็น API call จริงในอนาคต
  final now = DateTime.now();
  
  if (accountId == 'acc_001') {
    return [
      DepositTransaction(
        id: 'txn_001',
        accountId: accountId,
        type: TransactionType.deposit,
        amount: 5000.00,
        balanceAfter: 150000.00,
        dateTime: DateTime(now.year, now.month, 5, 14, 30),
        description: 'ฝากเงิน ณ สำนักงาน',
      ),
      DepositTransaction(
        id: 'txn_002',
        accountId: accountId,
        type: TransactionType.withdrawal,
        amount: 2000.00,
        balanceAfter: 145000.00,
        dateTime: DateTime(now.year, now.month, 3, 10, 15),
        description: 'ถอนเงิน ATM',
      ),
      DepositTransaction(
        id: 'txn_003',
        accountId: accountId,
        type: TransactionType.transferIn,
        amount: 10000.00,
        balanceAfter: 147000.00,
        dateTime: DateTime(now.year, now.month - 1, 28, 16, 45),
        description: 'รับโอนจาก นายสมชาย',
      ),
      DepositTransaction(
        id: 'txn_004',
        accountId: accountId,
        type: TransactionType.interest,
        amount: 187.50,
        balanceAfter: 137000.00,
        dateTime: DateTime(now.year, now.month - 1, 25, 0, 0),
        description: 'ดอกเบี้ยเงินฝาก',
      ),
      DepositTransaction(
        id: 'txn_005',
        accountId: accountId,
        type: TransactionType.transferOut,
        amount: 3000.00,
        balanceAfter: 136812.50,
        dateTime: DateTime(now.year, now.month - 1, 20, 9, 30),
        description: 'โอนไป นางสาวสมหญิง',
      ),
      DepositTransaction(
        id: 'txn_006',
        accountId: accountId,
        type: TransactionType.deposit,
        amount: 15000.00,
        balanceAfter: 139812.50,
        dateTime: DateTime(now.year, now.month - 1, 15, 11, 0),
        description: 'ฝากเงินเดือน',
      ),
      DepositTransaction(
        id: 'txn_007',
        accountId: accountId,
        type: TransactionType.withdrawal,
        amount: 5000.00,
        balanceAfter: 124812.50,
        dateTime: DateTime(now.year, now.month - 2, 28, 14, 20),
        description: 'ถอนเงิน',
      ),
      DepositTransaction(
        id: 'txn_008',
        accountId: accountId,
        type: TransactionType.deposit,
        amount: 8000.00,
        balanceAfter: 129812.50,
        dateTime: DateTime(now.year, now.month - 2, 10, 10, 0),
        description: 'ฝากเงิน',
      ),
    ];
  }
  
  return [];
});

/// Notifier สำหรับการซ่อน/แสดงยอดเงิน
class BalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void toggle() => state = !state;
}

final balanceVisibilityProvider = NotifierProvider<BalanceVisibilityNotifier, bool>(
  BalanceVisibilityNotifier.new,
);

/// State สำหรับ Filter
class TransactionFilter {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<TransactionType>? types;

  const TransactionFilter({
    this.startDate,
    this.endDate,
    this.types,
  });

  TransactionFilter copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<TransactionType>? types,
  }) {
    return TransactionFilter(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      types: types ?? this.types,
    );
  }

  bool get hasFilter => startDate != null || endDate != null || (types != null && types!.isNotEmpty);
}

/// Notifier สำหรับ Filter
class TransactionFilterNotifier extends Notifier<TransactionFilter> {
  @override
  TransactionFilter build() => const TransactionFilter();

  void setFilter(TransactionFilter filter) => state = filter;
  void clear() => state = const TransactionFilter();
}

final transactionFilterProvider = NotifierProvider<TransactionFilterNotifier, TransactionFilter>(
  TransactionFilterNotifier.new,
);

/// Filtered transactions provider
final filteredTransactionsProvider = Provider.family<List<DepositTransaction>, String>((ref, accountId) {
  final transactions = ref.watch(depositTransactionsProvider(accountId));
  final filter = ref.watch(transactionFilterProvider);

  if (!filter.hasFilter) return transactions;

  return transactions.where((txn) {
    // Filter by date range
    if (filter.startDate != null && txn.dateTime.isBefore(filter.startDate!)) {
      return false;
    }
    if (filter.endDate != null && txn.dateTime.isAfter(filter.endDate!.add(const Duration(days: 1)))) {
      return false;
    }
    // Filter by transaction type
    if (filter.types != null && filter.types!.isNotEmpty && !filter.types!.contains(txn.type)) {
      return false;
    }
    return true;
  }).toList();
});
