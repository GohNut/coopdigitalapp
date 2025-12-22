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

class DepositAccountDetailScreen extends ConsumerStatefulWidget {
  final String accountId;

  const DepositAccountDetailScreen({super.key, required this.accountId});

  @override
  ConsumerState<DepositAccountDetailScreen> createState() => _DepositAccountDetailScreenState();
}

class _DepositAccountDetailScreenState extends ConsumerState<DepositAccountDetailScreen> {
  late DateTime _selectedMonth;
  
  @override
  void initState() {
    super.initState();
    // เริ่มต้นที่เดือนปัจจุบัน
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(depositAccountByIdProvider(widget.accountId));
    final allTransactions = ref.watch(depositTransactionsProvider(widget.accountId));
    final isBalanceVisible = ref.watch(balanceVisibilityProvider);
    final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '');

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ไม่พบบัญชี')),
        body: const Center(child: Text('ไม่พบข้อมูลบัญชี')),
      );
    }

    // Filter transactions by selected month
    final transactions = allTransactions.where((txn) {
      return txn.dateTime.year == _selectedMonth.year &&
             txn.dateTime.month == _selectedMonth.month;
    }).toList();

    final cardColor = Color(account.accountType.colorCode);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Header Section
          SliverToBoxAdapter(
            child: _buildHeaderSection(
              context,
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
          // Month Selector
          SliverToBoxAdapter(
            child: _buildMonthSelector(context),
          ),
          // Transaction Header
          SliverToBoxAdapter(
            child: _buildTransactionHeader(context, transactions.length),
          ),
          // Transaction List
          if (transactions.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.inbox,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'ไม่พบรายการเดินบัญชีในเดือนนี้',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
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
                    child: Text(
                      account.accountName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            // Account Info
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                children: [
                  // Account Type Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      account.accountType.displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Account Number
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: account.accountNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('คัดลอกเลขบัญชีแล้ว')),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          account.accountNumber,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          LucideIcons.copy,
                          size: 16,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          isBalanceVisible
                              ? currencyFormat.format(account.balance)
                              : '••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
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
                  const SizedBox(height: 12),
                  // Interest Rate
                  Text(
                    'ดอกเบี้ย ${account.interestRate}% ต่อปี',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
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
              icon: LucideIcons.arrowDownLeft,
              label: 'ฝากเงิน',
              color: AppColors.success,
              onTap: () => context.push('/wallet/topup'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.arrowUpRight,
              label: 'ถอนเงิน',
              color: AppColors.primary,
              onTap: () => context.push('/wallet/withdraw'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context) {
    final monthFormat = DateFormat('MMMM yyyy', 'th');
    final now = DateTime.now();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.chevronLeft, size: 20),
            ),
          ),
          // Month Display
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => _showMonthPicker(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.calendar,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          monthFormat.format(_selectedMonth),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Next Month Button (disabled if current month)
          IconButton(
            onPressed: _selectedMonth.year >= now.year && _selectedMonth.month >= now.month
                ? null
                : () {
                    setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    });
                  },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _selectedMonth.year >= now.year && _selectedMonth.month >= now.month
                    ? Colors.grey.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                LucideIcons.chevronRight,
                size: 20,
                color: _selectedMonth.year >= now.year && _selectedMonth.month >= now.month
                    ? Colors.grey.shade300
                    : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMonthPicker(BuildContext context) async {
    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _YearMonthPickerDialog(
        initialDate: _selectedMonth,
        firstDate: DateTime(2020),
        lastDate: DateTime.now(),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedMonth = DateTime(result.year, result.month);
      });
    }
  }

  Widget _buildTransactionHeader(BuildContext context, int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'ความเคลื่อนไหว',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count รายการ',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<DepositTransaction> transactions,
    NumberFormat currencyFormat,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final txn = transactions[index];
            return _TransactionItem(
              transaction: txn,
              currencyFormat: currencyFormat,
            );
          },
          childCount: transactions.length,
        ),
      ),
    );
  }
}

/// Action Button
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? AppColors.primary;
    
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      shadowColor: Colors.black12,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: buttonColor, size: 22),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: buttonColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transaction Item
class _TransactionItem extends StatelessWidget {
  final DepositTransaction transaction;
  final NumberFormat currencyFormat;

  const _TransactionItem({
    required this.transaction,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = transaction.status == TransactionStatus.pending;
    final isCredit = transaction.type.isCredit;
    final color = isPending ? Colors.grey : (isCredit ? AppColors.success : AppColors.error);
    final dateFormat = DateFormat('dd MMM', 'th');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Transaction Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isPending ? LucideIcons.clock : _getTransactionIcon(transaction.type),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Transaction Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPending ? 'รอตรวจสอบ' : transaction.type.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isPending ? Colors.grey : AppColors.textPrimary,
                  ),
                ),
                if (transaction.description != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.description!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Amount & Time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isCredit ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                '${dateFormat.format(transaction.dateTime)} ${timeFormat.format(transaction.dateTime)}',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.deposit:
        return LucideIcons.arrowDownLeft;
      case TransactionType.withdrawal:
        return LucideIcons.arrowUpRight;
      case TransactionType.payment:
        return LucideIcons.scanLine;
      case TransactionType.transferIn:
        return LucideIcons.arrowDownLeft;
      case TransactionType.transferOut:
        return LucideIcons.arrowUpRight;
      case TransactionType.interest:
        return LucideIcons.trendingUp;
      case TransactionType.fee:
        return LucideIcons.minus;
    }
  }
}

/// Year-Month Picker Dialog
class _YearMonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _YearMonthPickerDialog({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  late int _year;
  late int _month;

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.year;
    _month = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      'มกราคม', 'กุมภาพันธ์', 'มีนาคม', 'เมษายน',
      'พฤษภาคม', 'มิถุนายน', 'กรกฎาคม', 'สิงหาคม',
      'กันยายน', 'ตุลาคม', 'พฤศจิกายน', 'ธันวาคม'
    ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              'เลือกเดือน',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // Year Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _year > widget.firstDate.year
                      ? () => setState(() => _year--)
                      : null,
                  icon: const Icon(LucideIcons.chevronLeft),
                ),
                Text(
                  '${_year + 543}', // Display as Buddhist Year
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: _year < widget.lastDate.year
                      ? () => setState(() => _year++)
                      : null,
                  icon: const Icon(LucideIcons.chevronRight),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Month Grid
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(12, (index) {
                final monthIndex = index + 1;
                final isSelected = _month == monthIndex;
                
                final isDisabled = (_year == widget.lastDate.year && monthIndex > widget.lastDate.month) ||
                                 (_year == widget.firstDate.year && monthIndex < widget.firstDate.month);
                
                return InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          setState(() {
                            _month = monthIndex;
                          });
                        },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 80) / 3, // 3 columns
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      months[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDisabled ? Colors.grey.shade300 : AppColors.textPrimary),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'ยกเลิก',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, DateTime(_year, _month));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('ตกลง'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
