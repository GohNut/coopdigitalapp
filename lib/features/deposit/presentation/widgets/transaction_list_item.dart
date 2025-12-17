import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/deposit_transaction.dart';

/// Widget สำหรับแสดงรายการเดินบัญชีแต่ละรายการ
/// ออกแบบให้เหมือน "บรรทัดในสมุดคู่ฝาก"
class TransactionListItem extends StatelessWidget {
  final DepositTransaction transaction;
  final NumberFormat currencyFormat;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type.isCredit;
    final amountColor = isCredit ? AppColors.success : AppColors.error;
    final amountPrefix = isCredit ? '+' : '-';
    final dateFormat = DateFormat('d MMM', 'th');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main Row: Icon + Description + Amount
          Row(
            children: [
              // Transaction Type Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getTransactionIcon(transaction.type),
                  color: amountColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Description & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description ?? transaction.type.displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateFormat.format(transaction.dateTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeFormat.format(transaction.dateTime),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix ${currencyFormat.format(transaction.amount)}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: amountColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),

          // Balance After Line (สมุดคู่ฝากแบบดิจิทัล)
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ยอดคงเหลือ',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  currencyFormat.format(transaction.balanceAfter),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
      case TransactionType.transferIn:
        return LucideIcons.arrowDownLeft;
      case TransactionType.transferOut:
        return LucideIcons.arrowUpRight;
      case TransactionType.interest:
        return LucideIcons.sparkles;
      case TransactionType.fee:
        return LucideIcons.receipt;
      case TransactionType.payment:
        return LucideIcons.qrCode;
    }
  }
}
