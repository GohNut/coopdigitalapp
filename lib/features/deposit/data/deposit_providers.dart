import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/dynamic_deposit_api.dart';
import '../../auth/domain/user_role.dart';
import '../domain/deposit_account.dart';
import '../domain/deposit_transaction.dart';

// ============================================================================
// ASYNC PROVIDERS - เชื่อม MongoDB API
// ============================================================================

/// Provider สำหรับดึงบัญชีทั้งหมดจาก API
final depositAccountsAsyncProvider = FutureProvider<List<DepositAccount>>((ref) async {
  final memberId = CurrentUser.id;
  final accountsData = await DynamicDepositApiService.getAccounts(memberId);
  
  return accountsData.map((data) => DepositAccount(
    id: data['accountid'] ?? '',
    accountNumber: data['accountnumber'] ?? '',
    accountName: data['accountname'] ?? '',
    accountType: _parseAccountType(data['accounttype']),
    balance: (data['balance'] ?? 0.0).toDouble(),
    interestRate: (data['interestrate'] ?? 0.0).toDouble(),
    accruedInterest: (data['accruedinterest'] ?? 0.0).toDouble(),
    openedDate: DateTime.tryParse(data['openeddate'] ?? '') ?? DateTime.now(),
  )).toList();
});

/// Provider สำหรับดึง transactions จาก API
final depositTransactionsAsyncProvider = FutureProvider.family<List<DepositTransaction>, String>((ref, accountId) async {
  final transactionsData = await DynamicDepositApiService.getTransactions(accountId);
  
  return transactionsData.map((data) => DepositTransaction(
    id: data['transactionid'] ?? '',
    accountId: data['accountid'] ?? '',
    type: _parseTransactionType(data['type']),
    amount: (data['amount'] ?? 0.0).toDouble(),
    balanceAfter: (data['balanceafter'] ?? 0.0).toDouble(),
    dateTime: DateTime.tryParse(data['datetime'] ?? '') ?? DateTime.now(),
    description: data['description'],
    referenceNo: data['referenceno'],
  )).toList()
    ..sort((a, b) => b.dateTime.compareTo(a.dateTime)); // Sort newest first
});

/// Provider สำหรับยอดเงินฝากรวม (async)
final totalDepositBalanceAsyncProvider = FutureProvider<double>((ref) async {
  final accountsAsync = await ref.watch(depositAccountsAsyncProvider.future);
  double total = 0.0;
  for (final account in accountsAsync) {
    total += account.balance;
  }
  return total;
});

/// Provider สำหรับดึงบัญชีตาม ID (async)
final depositAccountByIdAsyncProvider = FutureProvider.family<DepositAccount?, String>((ref, accountId) async {
  final data = await DynamicDepositApiService.getAccountById(accountId);
  if (data == null) return null;
  
  return DepositAccount(
    id: data['accountid'] ?? '',
    accountNumber: data['accountnumber'] ?? '',
    accountName: data['accountname'] ?? '',
    accountType: _parseAccountType(data['accounttype']),
    balance: (data['balance'] ?? 0.0).toDouble(),
    interestRate: (data['interestrate'] ?? 0.0).toDouble(),
    accruedInterest: (data['accruedinterest'] ?? 0.0).toDouble(),
    openedDate: DateTime.tryParse(data['openeddate'] ?? '') ?? DateTime.now(),
  );
});

// ============================================================================
// SYNC PROVIDERS (Backward compatibility with existing UI)
// ============================================================================

/// Provider เดิม (Backward compatibility) - ใช้ AsyncValue
final depositAccountsProvider = Provider<List<DepositAccount>>((ref) {
  final asyncValue = ref.watch(depositAccountsAsyncProvider);
  return asyncValue.when(
    data: (accounts) => accounts,
    loading: () => [],
    error: (_, __) => [],
  );
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

/// Provider สำหรับรายการเดินบัญชี (Sync wrapper)
final depositTransactionsProvider = Provider.family<List<DepositTransaction>, String>((ref, accountId) {
  final asyncValue = ref.watch(depositTransactionsAsyncProvider(accountId));
  return asyncValue.when(
    data: (transactions) => transactions,
    loading: () => [],
    error: (_, __) => [],
  );
});

// ============================================================================
// NOTIFIERS (for creating accounts)
// ============================================================================

/// Notifier สำหรับสร้างบัญชีใหม่
class CreateAccountNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String> createAccount({
    required String accountName,
    required AccountType accountType,
    required double interestRate,
    int? fixedTermMonths,
  }) async {
    state = const AsyncLoading();
    
    try {
      // Generate account number
      final now = DateTime.now();
      final prefix = accountType == AccountType.savings ? '101' 
          : accountType == AccountType.fixed ? '102' 
          : '103';
      final accountNumber = '$prefix-${now.month}-${now.microsecond.toString().padLeft(5, '0')}-${now.second % 10}';

      final result = await DynamicDepositApiService.createAccount(
        memberId: CurrentUser.id,
        accountNumber: accountNumber,
        accountName: accountName,
        accountType: accountType.name,
        interestRate: interestRate,
        fixedTermMonths: fixedTermMonths,
      );

      // Refresh accounts list
      ref.invalidate(depositAccountsAsyncProvider);
      
      state = const AsyncData(null);
      return result['accountid'] ?? '';
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final createAccountProvider = AsyncNotifierProvider<CreateAccountNotifier, void>(
  CreateAccountNotifier.new,
);

// ============================================================================
// UI STATE PROVIDERS
// ============================================================================

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

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

AccountType _parseAccountType(String? type) {
  switch (type?.toLowerCase()) {
    case 'savings':
      return AccountType.savings;
    case 'fixed':
      return AccountType.fixed;
    case 'special':
      return AccountType.special;
    default:
      return AccountType.savings;
  }
}

TransactionType _parseTransactionType(String? type) {
  switch (type?.toLowerCase()) {
    case 'deposit':
      return TransactionType.deposit;
    case 'withdrawal':
      return TransactionType.withdrawal;
    case 'transferin':
    case 'transfer_in': // Added case for transfer_in
      return TransactionType.transferIn;
    case 'transferout':
    case 'transfer_out': // Added case for transfer_out
      return TransactionType.transferOut;
    case 'interest':
      return TransactionType.interest;
    case 'fee':
      return TransactionType.fee;
    default:
      return TransactionType.deposit;
  }
}

// ============================================================================
// ACTION NOTIFIERS (Deposit/Withdraw)
// ============================================================================

/// Notifier สำหรับทำรายการฝากเงิน
class DepositActionNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> deposit({
    required String accountId,
    required double amount,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. Get current account info to ensure we have latest balance
      final accountData = await DynamicDepositApiService.getAccountById(accountId);
      if (accountData == null) {
        throw Exception('ไม่พบข้อมูลบัญชี');
      }
      final currentBalance = (accountData['balance'] ?? 0.0).toDouble();

      // 2. Perform deposit
      await DynamicDepositApiService.deposit(
        accountId: accountId,
        amount: amount,
        currentBalance: currentBalance,
        description: description,
      );

      // 3. Refresh providers
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      ref.invalidate(depositAccountByIdAsyncProvider(accountId));
      ref.invalidate(totalDepositBalanceAsyncProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> withdraw({
    required String accountId,
    required double amount,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      // 1. Get current account info to ensure we have latest balance
      final accountData = await DynamicDepositApiService.getAccountById(accountId);
      if (accountData == null) {
        throw Exception('ไม่พบข้อมูลบัญชี');
      }
      final currentBalance = (accountData['balance'] ?? 0.0).toDouble();

      if (currentBalance < amount) {
        throw Exception('ยอดเงินในบัญชีไม่เพียงพอ (มี: ${currentBalance.toStringAsFixed(2)}, ถอน: ${amount.toStringAsFixed(2)})');
      }

      // 2. Perform withdrawal
      await DynamicDepositApiService.withdraw(
        accountId: accountId,
        amount: amount,
        currentBalance: currentBalance,
        description: description,
      );

      // 3. Refresh providers
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      ref.invalidate(depositAccountByIdAsyncProvider(accountId));
      ref.invalidate(totalDepositBalanceAsyncProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> transfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amount,
    String? description,
  }) async {
    state = const AsyncLoading();
    try {
      // Logic checked in API service too, but good to validate here if needed

      await DynamicDepositApiService.transfer(
        sourceAccountId: sourceAccountId,
        destinationAccountId: destinationAccountId,
        amount: amount,
        description: description,
      );

      // Refresh providers
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(sourceAccountId));
      ref.invalidate(depositAccountByIdAsyncProvider(sourceAccountId));
      
      // Also refresh destination? Often not needed if it's another user, 
      // but if transferring to self (another account), it would be nice.
      // We can iterate invalidation if known, but for now basic invalidation is fine.
      ref.invalidate(totalDepositBalanceAsyncProvider);

      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final depositActionProvider = AsyncNotifierProvider<DepositActionNotifier, void>(
  DepositActionNotifier.new,
);
