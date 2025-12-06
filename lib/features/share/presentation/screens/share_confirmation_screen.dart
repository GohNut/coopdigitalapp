import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/mock_share_repository.dart';

class ShareConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const ShareConfirmationScreen({super.key, required this.args});

  @override
  State<ShareConfirmationScreen> createState() => _ShareConfirmationScreenState();
}

class _ShareConfirmationScreenState extends State<ShareConfirmationScreen> {
  final _repository = MockShareRepository();
  bool _isConsent = false;
  bool _isLoading = false;

  Future<void> _submit() async {
    // 1. PIN Verification
    final isVerified = await context.push<bool>('/pin');
    if (isVerified != true) return;

    setState(() => _isLoading = true);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    await _repository.buyExtraShares(widget.args['netTotal']); // Mock logic

    if (mounted) {
       // Go to Step 4: Success, replacing history so user can't go back to confirm
       context.go('/share/buy/success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final unitFormat = NumberFormat("#,##0", "th_TH");
    
    final units = widget.args['units'] as int;
    final price = widget.args['pricePerUnit'] as double;
    final totalBody = widget.args['totalBody'] as double;
    final vat = widget.args['vat'] as double;
    final netTotal = widget.args['netTotal'] as double;
    final method = widget.args['paymentMethod'] as String;

    String methodLabel = 'วอลเล็ทสหกรณ์';
    if (method == 'promptpay') methodLabel = 'QR PromptPay';
    if (method == 'truemoney') methodLabel = 'TrueMoney Wallet';
    if (method == 'creditcard') methodLabel = 'บัตรเครดิต';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ตรวจสอบและยืนยัน (3/4)'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  const Icon(LucideIcons.fileText, size: 48, color: AppColors.primary),
                  const SizedBox(height: 16),
                  const Text('สรุปรายการคำสั่งซื้อ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  
                  _buildRow('จำนวนหุ้น', '${unitFormat.format(units)} หุ้น'),
                  const SizedBox(height: 8),
                  _buildRow('ราคาต่อหน่วย', '${currencyFormat.format(price)} บาท'),
                  const SizedBox(height: 8),
                  _buildRow('ราคารวม', '${currencyFormat.format(totalBody)} บาท'),
                  const SizedBox(height: 8),
                  _buildRow('VAT 7%', '${currencyFormat.format(vat)} บาท', isHighlight: true),
                  const Divider(height: 24),
                  _buildRow('ยอดชำระสุทธิ', '${currencyFormat.format(netTotal)} บาท', isTotal: true),
                  
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.wallet, size: 20, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text('ชำระผ่าน: $methodLabel', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Row(
              children: [
                Checkbox(
                  value: _isConsent, 
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _isConsent = val!)
                ),
                const Expanded(child: Text('ฉันตรวจสอบข้อมูลถูกต้องและยืนยันการชำระเงิน', style: TextStyle(fontSize: 14))),
              ],
            ),
            
            const SizedBox(height: 32),
             SizedBox(
               width: double.infinity,
               height: 56,
               child: ElevatedButton(
                 onPressed: (!_isConsent || _isLoading) ? null : _submit,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: AppColors.primary,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                   elevation: 0,
                 ),
                 child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('ยืนยันการซื้อหุ้น', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(
          color: isHighlight ? Colors.orange : Colors.grey.shade700,
          fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          fontSize: isTotal ? 16 : 14,
        )),
        Text(value, style: TextStyle(
          fontWeight: isTotal || isHighlight ? FontWeight.bold : FontWeight.w600,
          fontSize: isTotal ? 20 : 14,
          color: isTotal ? AppColors.primary : (isHighlight ? Colors.orange : Colors.black),
        )),
      ],
    );
  }
}
