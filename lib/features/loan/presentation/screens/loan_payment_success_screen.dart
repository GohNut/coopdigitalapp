import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/financial_refresh_provider.dart';
import '../../../payment/services/slip_service.dart';

class LoanPaymentSuccessScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const LoanPaymentSuccessScreen({super.key, required this.args});

  @override
  ConsumerState<LoanPaymentSuccessScreen> createState() => _LoanPaymentSuccessScreenState();
}

class _LoanPaymentSuccessScreenState extends ConsumerState<LoanPaymentSuccessScreen> {
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
    final currencyFormat = NumberFormat.currency(symbol: '฿', decimalDigits: 0);
    final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');
    
    final amount = widget.args['amount'] as double;
    final timestamp = DateTime.parse(widget.args['timestamp']);
    final paymentType = widget.args['paymentType'] as String;
    final installmentNo = widget.args['installmentNo'] as int;
    final paymentId = widget.args['transaction_id'] ?? 'PAY-${DateTime.now().millisecondsSinceEpoch}';
    final hasSlipInfo = widget.args['slip_info'] != null;

    String paymentTypeText;
    switch (paymentType) {
      case 'advance':
        paymentTypeText = 'ชำระล่วงหน้า';
        break;
      case 'full_payoff':
        paymentTypeText = 'ปิดยอดกู้';
        break;
      default:
        paymentTypeText = 'ชำระงวดปกติ';
    }

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
                // Success Icon with Animation
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            LucideIcons.checkCircle,
                            color: AppColors.success,
                            size: 64,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'ชำระเงินสำเร็จ!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.success,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'การชำระค่างวดเสร็จสมบูรณ์',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 32),

                // Amount
                Text(
                  currencyFormat.format(amount),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: 32),

                // Details Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('เลขอ้างอิง', paymentId),
                      const Divider(height: 24),
                      _buildDetailRow('ประเภท', paymentTypeText),
                      const Divider(height: 24),
                      _buildDetailRow('งวดที่', 'งวดที่ $installmentNo'),
                      const Divider(height: 24),
                      _buildDetailRow('วันที่ชำระ', dateFormat.format(timestamp)),
                      const Divider(height: 24),
                      _buildDetailRow('ช่องทาง', 'หักจากสมุดบัญชี'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                
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

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await ref.read(financialRefreshProvider.notifier).refreshAll();
                          if (mounted) context.go('/loan');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: const Text('กลับหน้าสินเชื่อ', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
