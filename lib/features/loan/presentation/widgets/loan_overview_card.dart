import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class LoanOverviewCard extends StatelessWidget {
  final double totalOutstanding;
  final double totalLimit;

  const LoanOverviewCard({
    super.key,
    required this.totalOutstanding,
    required this.totalLimit,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalLimit > 0 ? totalOutstanding / totalLimit : 0.0;
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 2);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ยอดหนี้คงเหลือ',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currencyFormat.format(totalOutstanding),
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'วงเงินกู้ทั้งหมด',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(totalLimit),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: AppColors.background,
                          color: AppColors.error,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ใช้ไป',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
