import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class SharePaymentMethodScreen extends StatefulWidget {
  final Map<String, dynamic> args; // Passed from Step 1

  const SharePaymentMethodScreen({super.key, required this.args});

  @override
  State<SharePaymentMethodScreen> createState() => _SharePaymentMethodScreenState();
}

class _SharePaymentMethodScreenState extends State<SharePaymentMethodScreen> {
  String _selectedMethod = 'wallet';
  // Mock wallet balance
  final double _walletBalance = 5300.00; 

  @override
  Widget build(BuildContext context) {
    final netTotal = widget.args['netTotal'] as double;
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('เลือกช่องทางชำระเงิน (2/4)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
             // Header: Amount to Pay
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppColors.primary,
                 borderRadius: BorderRadius.circular(16),
               ),
               child: Column(
                 children: [
                   const Text('ยอดชำระสุทธิ', style: TextStyle(color: Colors.white70)),
                   const SizedBox(height: 8),
                   Text('฿${currencyFormat.format(netTotal)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
             const SizedBox(height: 32),
             
             const Text("เลือกช่องทาง", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
             const SizedBox(height: 16),

             _buildOption('wallet', 'วอลเล็ทสหกรณ์', LucideIcons.wallet, 
                subtitle: 'ยอดคงเหลือ ฿${currencyFormat.format(_walletBalance)}',
                enabled: _walletBalance >= netTotal),
                
             const SizedBox(height: 12),
             _buildOption('promptpay', 'QR PromptPay', LucideIcons.qrCode),
             const SizedBox(height: 12),
             _buildOption('truemoney', 'TrueMoney Wallet', LucideIcons.smartphone),
             const SizedBox(height: 12),
             _buildOption('creditcard', 'บัตรเครดิต / เดบิต', LucideIcons.creditCard),

             const SizedBox(height: 48),

             SizedBox(
               height: 56,
               child: ElevatedButton(
                 onPressed: (_selectedMethod == 'wallet' && _walletBalance < netTotal) ? null : () {
                    // Go to Step 3: Confirmation
                    final nextArgs = Map<String, dynamic>.from(widget.args);
                    nextArgs['paymentMethod'] = _selectedMethod;
                    context.push('/share/buy/confirm', extra: nextArgs);
                 },
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 0,
                 ),
                 child: const Text('ถัดไป (ตรวจสอบข้อมูล)', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String id, String label, IconData icon, {String? subtitle, bool enabled = true}) {
    final isSelected = _selectedMethod == id;
    
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: InkWell(
        onTap: enabled ? () => setState(() => _selectedMethod = id) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.black87, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (subtitle != null)
                      Text(subtitle, style: TextStyle(color: enabled ? Colors.green : Colors.red, fontSize: 13)),
                    if (!enabled)
                      const Text('ยอดเงินไม่เพียงพอ', style: TextStyle(color: Colors.red, fontSize: 11)),
                  ],
                ),
              ),
              if (isSelected) const Icon(LucideIcons.checkCircle, color: AppColors.primary)
            ],
          ),
        ),
      ),
    );
  }
}
