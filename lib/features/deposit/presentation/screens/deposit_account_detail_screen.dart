import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/deposit_providers.dart';
import '../../domain/deposit_account.dart';
import '../../domain/deposit_transaction.dart';
import '../widgets/transaction_filter_sheet.dart';
import '../widgets/transaction_list_item.dart';

class DepositAccountDetailScreen extends ConsumerWidget {
  final String accountId;

  const DepositAccountDetailScreen({super.key, required this.accountId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(depositAccountByIdProvider(accountId));
    final transactions = ref.watch(filteredTransactionsProvider(accountId));
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final filter = ref.watch(transactionFilterProvider);
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบบัญชี')),
        body: const Center(child: Text('ไม่พบข้อมูลบัญชี')),
      );
    }

    final cardColor = Color(account.accountType.colorCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: _buildHeaderSection(
              context,
              ref,
              account,
              cardColor,
              currencyFormat,
              isBalanceVisible,
            ),
          ),
          // Action Buttons
          SliverToBoxAdapter(
            child: _buildActionButtons(context),
          ),
          // Transaction Header with Filter
          SliverToBoxAdapter(
            child: _buildTransactionHeader(context, ref, filter),
          ),
          // Transaction List
          if (transactions.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Text(
                  'ไม่พบรายการเดินบัญชี',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            _buildTransactionList(context, transactions, currencyFormat),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(
    BuildContext context,
    WidgetRef ref,
    DepositAccount account,
    Color cardColor,
    NumberFormat currencyFormat,
    bool isBalanceVisible,
  ) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cardColor, cardColor.withOpacity(0.8)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          account.accountName,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            account.accountType.displayName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Balance Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  // Account Number with Copy
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: account.fullAccountNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('คัดลอกเลขที่บัญชีแล้ว'),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            account.fullAccountNumber,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.copy, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Balance with Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isBalanceVisible ? currencyFormat.format(account.balance) : '฿ ••••••••',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 40,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          ref.read(balanceVisibilityProvider.notifier).toggle();
                        },
                        icon: Icon(
                          isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Interest Info Cards
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: LucideIcons.trendingUp,
                          label: 'ดอกเบี้ยสะสมปีนี้',
                          value: isBalanceVisible
                              ? currencyFormat.format(account.accruedInterest)
                              : '฿ ••••',
                          valueColor: Colors.lightGreenAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: LucideIcons.percent,
                          label: 'อัตราดอกเบี้ย',
                          value: '${account.interestRate.toStringAsFixed(2)}% ต่อปี',
                          valueColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.arrowUpRight,
              label: 'โอนเงิน',
              onTap: () => context.push('/transfer'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.banknote,
              label: 'ถอนเงิน',
              onTap: () => context.push('/wallet/withdraw'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.fileText,
              label: 'Statement',
              onTap: () {
                // TODO: Navigate to E-Statement
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ฟีเจอร์ E-Statement จะพร้อมใช้งานเร็วๆ นี้')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHeader(BuildContext context, WidgetRef ref, TransactionFilter filter) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'รายการเดินบัญชี',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          TextButton.icon(
            onPressed: () => _showFilterSheet(context, ref),
            icon: Icon(
              LucideIcons.filter,
              size: 18,
              color: filter.hasFilter ? AppColors.primary : AppColors.textSecondary,
            ),
            label: Text(
              filter.hasFilter ? 'กำลังกรอง' : 'กรอง',
              style: TextStyle(
                color: filter.hasFilter ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TransactionFilterSheet(),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<DepositTransaction> transactions,
    NumberFormat currencyFormat,
  ) {
    // Group transactions by month
    final groupedTransactions = <String, List<DepositTransaction>>{};
    final monthFormat = DateFormat('MMMM yyyy', 'th');

    for (final txn in transactions) {
      final monthKey = monthFormat.format(txn.dateTime);
      groupedTransactions.putIfAbsent(monthKey, () => []).add(txn);
    }

    final sortedMonths = groupedTransactions.keys.toList();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final monthKey = sortedMonths[index];
          final monthTransactions = groupedTransactions[monthKey]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Month Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  monthKey,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Transactions for this month
              ...monthTransactions.map((txn) => TransactionListItem(
                transaction: txn,
                currencyFormat: currencyFormat,
              )),
            ],
          );
        },
        childCount: sortedMonths.length,
      ),
    );
  }
}

/// Info card widget for interest info
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Action button widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
