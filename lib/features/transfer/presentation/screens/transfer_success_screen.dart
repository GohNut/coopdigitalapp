import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/financial_refresh_provider.dart';

class TransferSuccessScreen extends ConsumerWidget {
  final Map<String, dynamic> args;

  const TransferSuccessScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = args['amount'] as double;
    final targetName = args['target_name'] as String;
    final txnId = args['transaction_id'] as String;
    final timestamp = DateTime.parse(args['timestamp'] as String);
    final note = args['note'] as String?;
    final repeatText = args['repeat_text'] as String? ?? 'ทำรายการอีกครั้ง';
    final repeatRoute = args['repeat_route'] as String? ?? '/home';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primary,
        body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 64),
              const SizedBox(height: 16),
              const Text(
                'โอนเงินสำเร็จ',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('d MMM yyyy, HH:mm').format(timestamp),
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 32),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    // Mock Slip Header
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                         border: Border(bottom: BorderSide(color: AppColors.divider))
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/pic/logoCoop.jpg',
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(child: Text('สหกรณ์ออมทรัพย์...')),
                        ],
                      ),
                    ),
                    Padding(
                       padding: const EdgeInsets.all(24),
                       child: Column(
                         children: [
                           _buildDetailRow('จาก', args['from_name'] as String? ?? 'Wallet ของคุณ'),
                           const SizedBox(height: 16),
                           _buildDetailRow('ไปยัง', targetName),
                           const SizedBox(height: 16),
                           _buildDetailRow('เลขที่รายการ', txnId),
                           const SizedBox(height: 24),
                           const Divider(),
                           const SizedBox(height: 24),
                           Row(
                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                             children: [
                               const Text('จำนวนเงิน'),
                               Text(
                                 '${NumberFormat('#,##0.00').format(amount)}',
                                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ],
                           ),
                           if (note != null && note.isNotEmpty) ...[
                             const SizedBox(height: 16),
                             Container(
                               padding: const EdgeInsets.all(12),
                               decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                               child: Row(
                                 children: [
                                   const Icon(Icons.edit_note, size: 16, color: AppColors.textSecondary),
                                   const SizedBox(width: 8),
                                   Text(note, style: const TextStyle(color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                                 ],
                               ),
                             )
                           ]
                         ],
                       ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await ref.read(financialRefreshProvider.notifier).refreshAll();
                        if (context.mounted) context.go(repeatRoute);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(repeatText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await ref.read(financialRefreshProvider.notifier).refreshAll();
                        if (context.mounted) context.go('/home');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('กลับหน้าหลัก', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
