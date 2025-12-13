import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class LoanPaymentHistoryScreen extends StatelessWidget {
  const LoanPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ประวัติการชำระ'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(LucideIcons.download),
            tooltip: 'Download Statement',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Summary Header
             Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ยอดชำระทั้งหมด', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(symbol: '฿', decimalDigits: 2).format(15250),
                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                   Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('ครั้งล่าสุด', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      const Text(
                        '25 Nov 2024',
                         style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Grouped Transactions
            _buildMonthGroup(context, 'พฤศจิกายน 2024', [
              {'date': '25 Nov', 'total': 5200, 'principal': 4800, 'interest': 400},
            ]),
            _buildMonthGroup(context, 'ตุลาคม 2024', [
              {'date': '25 Oct', 'total': 5200, 'principal': 4780, 'interest': 420},
            ]),
            _buildMonthGroup(context, 'กันยายน 2024', [
              {'date': '25 Sep', 'total': 5200, 'principal': 4760, 'interest': 440},
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthGroup(BuildContext context, String monthTitle, List<Map<String, dynamic>> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            monthTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(
            children: transactions.map((t) => _buildTransactionTile(context, t)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(BuildContext context, Map<String, dynamic> t) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.arrowUpRight, color: AppColors.success),
          ),
          title: Text('ชำระค่างวด', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(t['date'] as String, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text('ต้น ${NumberFormat('#,##0').format(t['principal'])}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Text('ดอก ${NumberFormat('#,##0').format(t['interest'])}', style: const TextStyle(fontSize: 12, color: AppColors.error)),
                ],
              ),
            ],
          ),
           trailing: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
               Text(
                 '- ฿${NumberFormat('#,##0').format(t['total'])}', 
                 style: const TextStyle(
                   color: AppColors.textPrimary, 
                   fontWeight: FontWeight.bold,
                   fontSize: 16
                  ),
               ),
               const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: const Text('E-Slip', style: TextStyle(fontSize: 10)),
                )
             ],
           ),
        ),
        const Divider(height: 1, indent: 80),
      ],
    );
  }
}
