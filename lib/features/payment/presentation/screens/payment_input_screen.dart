import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/currency_input_formatter.dart';
import '../../../../core/widgets/kyc_required_dialog.dart';
import '../../data/payment_providers.dart';
import '../../domain/payment_source_model.dart';

class PaymentInputScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;

  const PaymentInputScreen({super.key, required this.args});

  @override
  ConsumerState<PaymentInputScreen> createState() => _PaymentInputScreenState();
}

class _PaymentInputScreenState extends ConsumerState<PaymentInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  bool _isLoading = false;

  PaymentSource? get _selectedSource => widget.args['selectedSource'] as PaymentSource?;
  String get _merchantId => widget.args['merchant_id'] ?? '';
  String get _merchantName => widget.args['merchant_name'] ?? 'ร้านค้า';
  double? get _fixedAmount => widget.args['amount'] as double?;
  bool get _isInternal => widget.args['is_internal'] ?? false;

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() => setState(() {}));
    if (_fixedAmount != null) {
      _amountController.text = NumberFormat('#,##0.00').format(_fixedAmount);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    final source = _selectedSource;
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ไม่พบบัญชีที่เลือก กรุณาเลือกใหม่')),
      );
      context.go('/payment/source');
      return;
    }

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาระบุยอดเงิน')),
      );
      return;
    }

    if (amount > source.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ยอดเงินไม่เพียงพอ (คงเหลือ ${source.displayBalance})')),
      );
      return;
    }

    // PIN Verification
    final pinSuccess = await context.push<bool>('/pin');
    if (pinSuccess != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(paymentActionProvider.notifier).pay(
        source: source,
        merchantId: _merchantId,
        merchantName: _merchantName,
        amount: amount,
        isInternal: _isInternal,
      );

      if (mounted) {
        // Clear selected source
        ref.read(selectedPaymentSourceProvider.notifier).clear();
        context.go('/payment/success', extra: result);
      }
    } catch (e) {
      if (mounted) {
        // ตรวจจับ KYC error และแสดง Dialog แทน SnackBar
        if (isKYCError(e)) {
          await showKYCRequiredDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = _selectedSource;
    
    if (source == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/payment/source');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 24),
              const Text(
                'กำลังดำเนินการ...',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'กรุณารอสักครู่',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'ชำระเงิน',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Merchant Info Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(LucideIcons.store, size: 40, color: AppColors.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _merchantName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _merchantId,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Amount Input
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'จำนวนเงิน',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    enabled: _fixedAmount == null,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: _fixedAmount == null
                        ? [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                            CurrencyInputFormatter(),
                          ]
                        : [],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      hintText: _amountFocusNode.hasFocus ? null : '0.00',
                      hintStyle: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[300],
                      ),
                      border: InputBorder.none,
                      prefixText: '',
                      prefixStyle: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (_fixedAmount != null)
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ยอดเงินถูกกำหนดจาก QR Code',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Source Card (Read-only)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: source.type.color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: source.type.color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: source.type.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(source.type.icon, color: source.type.color, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'จ่ายจาก',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          source.sourceName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'ยอดคงเหลือ ${source.displayBalance}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: source.type.color,
                    size: 28,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.checkCircle, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'ยืนยันชำระเงิน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
