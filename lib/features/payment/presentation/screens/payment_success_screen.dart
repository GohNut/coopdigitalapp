import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> args;

  const PaymentSuccessScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final amount = args['amount'] as double;
    final timestamp = DateTime.parse(args['timestamp']);
    final sourceName = args['source_name'] ?? '';
    final sourceType = args['source_type'];
    final sourceDisplay = sourceType == 'deposit' 
        ? 'บัญชีเงินฝาก: $sourceName' 
        : sourceType == 'loan'
            ? 'วงเงินสินเชื่อ: $sourceName'
            : sourceName;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 60, color: Colors.green),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ชำระเงินสำเร็จ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('d MMM yyyy, HH:mm').format(timestamp),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 40),
                Text(
                  '${NumberFormat('#,##0.00').format(amount)}',
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'ชำระด้วย $sourceDisplay', 
                  style: const TextStyle(color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 60),
                const SizedBox(height: 60),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/scan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('จ่ายอีกครั้ง', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/home'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('กลับหน้าหลัก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
