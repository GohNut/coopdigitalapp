import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../services/slip_service.dart';

class PaymentSuccessScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const PaymentSuccessScreen({super.key, required this.args});

  @override
  State<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends State<PaymentSuccessScreen> {
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
    final amount = widget.args['amount'] as double;
    final timestamp = DateTime.parse(widget.args['timestamp']);
    final sourceName = widget.args['source_name'] ?? '';
    final sourceType = widget.args['source_type'];
    final sourceDisplay = sourceType == 'deposit' 
        ? 'บัญชีเงินฝาก: $sourceName' 
        : sourceType == 'loan'
            ? 'วงเงินสินเชื่อ: $sourceName'
            : sourceName;

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
                  NumberFormat('#,##0.00').format(amount),
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
                
                const SizedBox(height: 40),
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
                ],

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
      ),
    );
  }
}
