import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/financial_refresh_provider.dart';

import 'package:intl/intl.dart';
import '../../../../features/payment/services/slip_service.dart';

class BuyShareSuccessScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const BuyShareSuccessScreen({super.key, required this.args});

  @override
  ConsumerState<BuyShareSuccessScreen> createState() => _BuyShareSuccessScreenState();
}

class _BuyShareSuccessScreenState extends ConsumerState<BuyShareSuccessScreen> {
  bool _isSaving = false;
  bool _hasSaved = false;

  @override
  void initState() {
    super.initState();
    // Auto-save slip if slip_info is present
    if (widget.args['slip_info'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAutoSave();
      });
    }
  }

  Future<void> _handleAutoSave() async {
    if (_hasSaved) return;
    
    setState(() {
      _isSaving = true;
    });

    final success = await SlipService.saveSlipToGallery(context, widget.args['slip_info']);
    
    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasSaved = success;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('บันทึกสลิปลงอัลบั้มรูปแล้ว'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.args['amount'] as double? ?? 0.0;
    final units = widget.args['units'] as int? ?? 0;
    final timestampStr = widget.args['timestamp'] as String? ?? DateTime.now().toIso8601String();
    final timestamp = DateTime.parse(timestampStr);
    final hasSlipInfo = widget.args['slip_info'] != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: Colors.green.shade50,
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(LucideIcons.check, color: Colors.green, size: 64),
               ),
               const SizedBox(height: 32),
               const Text(
                 'สั่งซื้อสำเร็จแล้ว',
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
               ),
               const SizedBox(height: 8),
               Text(
                 DateFormat('d MMM yyyy, HH:mm').format(timestamp),
                 style: const TextStyle(color: AppColors.textSecondary),
               ),
               
               const SizedBox(height: 40),
               Text(
                 NumberFormat('#,##0.00').format(amount),
                 style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
               ),
               const Text('บาท', style: TextStyle(color: AppColors.textSecondary)),
               
               const SizedBox(height: 16),
               Text(
                 'จำนวนหุ้นที่ซื้อ: ${NumberFormat('#,##0').format(units)} หุ้น',
                 style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
               ),

               const SizedBox(height: 40),
               
               // Slip Saving Status
               if (hasSlipInfo) ...[
                 if (_isSaving)
                   const Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                       SizedBox(width: 8),
                       Text('กำลังบันทึกสลิป...', style: TextStyle(color: AppColors.textSecondary)),
                     ],
                   )
                 else if (_hasSaved)
                   const Row(
                     mainAxisAlignment: MainAxisAlignment.center,
                     children: [
                       Icon(Icons.check_circle, color: AppColors.success, size: 20),
                       SizedBox(width: 8),
                       Text('บันทึกสลิปลงอัลบั้มแล้ว', style: TextStyle(color: AppColors.success)),
                     ],
                   )
                 else
                   TextButton.icon(
                     onPressed: _handleAutoSave,
                     icon: const Icon(Icons.save_alt),
                     label: const Text('บันทึกสลิปลงเครื่อง'),
                   ),
                 const SizedBox(height: 32),
               ],

               Row(
                 children: [
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () async {
                         await ref.read(financialRefreshProvider.notifier).refreshAll();
                         if (mounted) context.replace('/share/buy');
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppColors.primary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         elevation: 0,
                         padding: const EdgeInsets.symmetric(vertical: 18),
                       ),
                       child: const Text('ซื้อเพิ่ม', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () async {
                         await ref.read(financialRefreshProvider.notifier).refreshAll();
                         if (mounted) context.go('/home');
                       },
                       style: OutlinedButton.styleFrom(
                         foregroundColor: AppColors.primary,
                         side: const BorderSide(color: AppColors.primary, width: 2),
                         padding: const EdgeInsets.symmetric(vertical: 18),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                       child: const Text('กลับหน้าหลัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
