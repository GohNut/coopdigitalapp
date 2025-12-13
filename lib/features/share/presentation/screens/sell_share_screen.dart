import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/repositories/mock_share_repository.dart';

class SellShareScreen extends StatefulWidget {
  const SellShareScreen({super.key});

  @override
  State<SellShareScreen> createState() => _SellShareScreenState();
}

class _SellShareScreenState extends State<SellShareScreen> {
  final _unitsController = TextEditingController();
  final _repository = MockShareRepository();
  bool _isLoading = false;

  int _units = 0;
  final double _pricePerUnit = 50.0;
  final double _feeRate = 0.0011; // 0.11%
  int _maxSellableUnits = 2400; // Mock: Owns 2500, Min 100 -> Sellable 2400

  @override
  void initState() {
    super.initState();
    _unitsController.addListener(_calculate);
  }

  @override
  void dispose() {
    _unitsController.removeListener(_calculate);
    _unitsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final input = _unitsController.text;
    if (input.isEmpty) {
      setState(() => _units = 0);
      return;
    }
    setState(() => _units = int.tryParse(input) ?? 0);
  }

  Future<void> _submit() async {
    if (_units <= 0 || _units > _maxSellableUnits) return;

    // 1. PIN Verification
    final isVerified = await context.push<bool>('/pin');
    if (isVerified != true) return;

    setState(() => _isLoading = true);

    // Process Sell
    await _repository.sellShares(_units * _pricePerUnit);
    
    if (mounted) {
      context.go('/share/sell/success');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final grossAmount = _units * _pricePerUnit;
    final deduction = grossAmount * _feeRate;
    final netAmount = grossAmount - deduction;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('โอนหุ้น'),
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
            // Share Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                   const Icon(LucideIcons.pieChart, color: AppColors.primary),
                   const SizedBox(width: 12),
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       const Text('หุ้นที่สามารถโอนได้', style: TextStyle(color: Colors.grey, fontSize: 12)),
                       Text('$_maxSellableUnits หุ้น', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     ],
                   )
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text("ระบุจำนวนหุ้นที่ต้องการโอน", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _unitsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                suffixText: 'หุ้น',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                   borderRadius: BorderRadius.circular(16),
                   borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
             if (_units > _maxSellableUnits)
               const Padding(
                 padding: EdgeInsets.only(top: 8, left: 8),
                 child: Text("เกินจำนวนที่สามารถโอนได้", style: TextStyle(color: Colors.red, fontSize: 12)),
               ),

            const SizedBox(height: 24),

            // Calculation Details
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildRow('ราคาต่อหุ้น', '${currencyFormat.format(_pricePerUnit)} บาท'),
                  const SizedBox(height: 12),
                  _buildRow('รวมเงินหุ้น (Gross)', '${currencyFormat.format(grossAmount)} บาท'),
                  const SizedBox(height: 12),
                  _buildRow('หักค่าธรรมเนียม (0.11%)', '-${currencyFormat.format(deduction)} บาท', color: Colors.red),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ยอดรับสุทธิ (Net)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${currencyFormat.format(netAmount)} บาท', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.pink)),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            // Receiving Account Info
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.blue.shade50,
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: Colors.blue.shade100),
               ),
               child: Row(
                 children: [
                   const Icon(LucideIcons.wallet, color: Colors.blue),
                   const SizedBox(width: 12),
                   const Expanded(child: Text("เงินจะเข้าสู่บัญชี: วอลเล็ทสหกรณ์", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))),
                 ],
               ),
             ),
            
            const SizedBox(height: 48),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: (_units <= 0 || _units > _maxSellableUnits || _isLoading) ? null : () {
                   // Show Confirmation Dialog before submitting
                   showDialog(
                     context: context,
                     builder: (ctx) => AlertDialog(
                       title: const Text('ยืนยันการโอนหุ้น'),
                       content: Text('คุณต้องการโอนหุ้นจำนวน $_units หุ้น \nได้รับเงินสุทธิ ${currencyFormat.format(netAmount)} บาท?'),
                       actions: [
                         TextButton(onPressed: () => ctx.pop(), child: const Text('ยกเลิก')),
                         TextButton(onPressed: () {
                           ctx.pop();
                           _submit();
                         }, child: const Text('ยืนยัน', style: TextStyle(fontWeight: FontWeight.bold))),
                       ],
                     )
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('แจ้งโอนหุ้น', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: color ?? Colors.black)),
      ],
    );
  }
}
