import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class WithdrawInputScreen extends StatefulWidget {
  const WithdrawInputScreen({super.key});

  @override
  State<WithdrawInputScreen> createState() => _WithdrawInputScreenState();
}

class _WithdrawInputScreenState extends State<WithdrawInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _accountController = TextEditingController(); // In real app, this might be a dropdown of saved accounts
  
  String? _selectedBank;
  final List<Map<String, String>> _banks = [
    {'id': 'KBANK', 'name': 'ธนาคารกสิกรไทย', 'icon': 'assets/images/kbank.png'}, // Placeholder icons
    {'id': 'SCB', 'name': 'ธนาคารไทยพาณิชย์', 'icon': 'assets/images/scb.png'},
    {'id': 'BBL', 'name': 'ธนาคารกรุงเทพ', 'icon': 'assets/images/bbl.png'},
    {'id': 'KTB', 'name': 'ธนาคารกรุงไทย', 'icon': 'assets/images/ktb.png'},
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกธนาคาร')));
      return;
    }
    if (_accountController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาระบุเลขบัญชี')));
      return;
    }
    
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 100) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดถอนขั้นต่ำ 100 บาท')));
      return;
    }

    // Go to Review
    context.push('/wallet/withdraw/confirm', extra: {
      'bankId': _selectedBank,
      'bankName': _banks.firstWhere((b) => b['id'] == _selectedBank)['name'],
      'accountNo': _accountController.text,
      'amount': amount,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ถอนเงิน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('เลือกบัญชีธนาคารปลายทาง', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: _banks.map((bank) {
                  final isSelected = _selectedBank == bank['id'];
                  return RadioListTile<String>(
                    value: bank['id']!,
                    groupValue: _selectedBank,
                    onChanged: (val) => setState(() => _selectedBank = val),
                    title: Text(bank['name']!),
                    secondary: Container(
                      width: 40, 
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      // child: Image.asset(bank['icon']!), // Placeholder
                      child: const Icon(Icons.account_balance, color: Colors.grey),
                    ),
                    activeColor: AppColors.primary,
                    selected: isSelected,
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('เลขที่บัญชี', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
             TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'xxx-x-xxxxx-x',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text('จำนวนเงิน', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              decoration: InputDecoration(
                prefixText: '฿ ',
                hintText: '0.00',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none
                ),
                suffixText: 'บาท'
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('ขั้นต่ำ 100.00 บาท', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _validateAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ตรวจสอบข้อมูล', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
