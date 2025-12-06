import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/payment_service.dart';

class PaymentInputScreen extends StatefulWidget {
  final Map<String, dynamic> merchant;

  const PaymentInputScreen({super.key, required this.merchant});

  @override
  State<PaymentInputScreen> createState() => _PaymentInputScreenState();
}

class _PaymentInputScreenState extends State<PaymentInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  String _sourceType = 'CASH'; // CASH or CREDIT
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.merchant['amount'] != null) {
      _amountController.text = widget.merchant['amount'].toString();
    }
  }

  Future<void> _processPayment() async {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุยอดเงิน')));
      return;
    }

    // PIN
    final pinSuccess = await context.push<bool>('/pin');
    if (pinSuccess != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await paymentServiceProvider.pay(
        merchantId: widget.merchant['merchant_id'],
        amount: amount,
        sourceType: _sourceType,
      );

      if (mounted) {
        context.push('/payment/success', extra: result);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ชำระเงิน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Merchant Info
            Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(LucideIcons.store, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 12),
                Text(widget.merchant['merchant_name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(widget.merchant['merchant_id'], style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 32),
            
            // Amount
            TextField(
              controller: _amountController,
              enabled: widget.merchant['amount'] == null, // Disable if fixed amount
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                prefixText: '฿ ',
                prefixStyle: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            
            const SizedBox(height: 32),
            const Align(alignment: Alignment.centerLeft, child: Text('เลือกวิธีการชำระเงิน', style: TextStyle(color: AppColors.textSecondary))),
            const SizedBox(height: 12),
            
            // Source Selection
            _buildSourceOption(
              value: 'CASH',
              title: 'เงินสด (Cash Wallet)',
              subtitle: 'ยอดคงเหลือ ฿ 10,000.00',
              icon: LucideIcons.wallet,
            ),
            const SizedBox(height: 12),
            _buildSourceOption(
              value: 'CREDIT',
              title: 'วงเงินกู้ (Credit Line)',
              subtitle: 'วงเงินคงเหลือ ฿ 5,000.00',
              icon: LucideIcons.creditCard,
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ยืนยันชำระเงิน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _sourceType == value;
    return InkWell(
      onTap: () => setState(() => _sourceType = value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.1), blurRadius: 8)] : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) 
              const Icon(Icons.check_circle, color: AppColors.primary)
            else
              const Icon(Icons.circle_outlined, color: Colors.grey)
          ],
        ),
      ),
    );
  }
}
