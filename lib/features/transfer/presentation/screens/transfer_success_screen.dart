import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class TransferSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> args;

  const TransferSuccessScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    final amount = args['amount'] as double;
    final targetName = args['target_name'] as String;
    final txnId = args['transaction_id'] as String;
    final timestamp = DateTime.parse(args['timestamp'] as String);
    final note = args['note'] as String?;

    return Scaffold(
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
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                            child: const Icon(LucideIcons.arrowRightLeft, color: AppColors.primary),
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
                           _buildDetailRow('จาก', 'Wallet ของคุณ'),
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
                                 '฿ ${NumberFormat('#,##0.00').format(amount)}',
                                 style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
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
                                   Text(note, style: const TextStyle(color: AppColors.textSecondary)),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('กลับสู่หน้าหลัก', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              )
            ],
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
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
