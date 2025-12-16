import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import 'share_payment_method_screen.dart';

class BuyExtraShareScreen extends StatefulWidget {
  const BuyExtraShareScreen({super.key});

  @override
  State<BuyExtraShareScreen> createState() => _BuyExtraShareScreenState();
}

class _BuyExtraShareScreenState extends State<BuyExtraShareScreen> {
  final _unitsController = TextEditingController(text: '10'); // Default 10 units
  final _formKey = GlobalKey<FormState>();
  
  double _pricePerUnit = 50.0;
  int _units = 10;

  @override
  void initState() {
    super.initState();
    _unitsController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _unitsController.removeListener(_calculateTotal);
    _unitsController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final input = _unitsController.text;
    if (input.isEmpty) {
      setState(() => _units = 0);
      return;
    }
    setState(() {
      _units = int.tryParse(input) ?? 0;
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    // Navigate to Step 2: Payment
    final totalBody = _units * _pricePerUnit;

    context.go('/share/buy/payment', extra: {
      'units': _units,
      'pricePerUnit': _pricePerUnit,
      'totalBody': totalBody,
      'netTotal': totalBody, // ไม่มี VAT สำหรับหุ้นสหกรณ์
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0.00", "th_TH");
    final totalBody = _units * _pricePerUnit;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('ซื้อหุ้นเพิ่ม (1/4)'), // Step Indicator
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => context.go('/share'), // Safe back
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               // 1. Share Type Dropdown (Mock)
               const Text("ประเภทหุ้น", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
               const SizedBox(height: 8),
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.grey.shade300),
                 ),
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<String>(
                     value: 'ordinary',
                     isExpanded: true,
                     items: const [
                       DropdownMenuItem(value: 'ordinary', child: Text('หุ้นสามัญ (Ordinary Share)')),
                     ], 
                     onChanged: (val) {},
                   ),
                 ),
               ),
               const SizedBox(height: 24),

               // 2. Unit Input
               const Text("จำนวนหุ้นที่ต้องการซื้อ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
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
                 validator: (value) {
                    if (value == null || value.isEmpty) return 'กรุณาระบุจำนวน';
                    final n = int.tryParse(value) ?? 0;
                    if (n <= 0) return 'ต้องมากกว่า 0';
                    if (n > 50) return 'สูงสุดไม่เกิน 50 หุ้น';
                    return null;
                 },
               ),
               if (_units > 50)
                 const Padding(
                   padding: EdgeInsets.only(top: 8, left: 8),
                   child: Text("สูงสุดไม่เกิน 50 หุ้นต่อครั้ง", style: TextStyle(color: Colors.red, fontSize: 12)),
                 ),
               
               const SizedBox(height: 24),

               // 3. Calculation Card
               Container(
                 padding: const EdgeInsets.all(20),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(16),
                   border: Border.all(color: Colors.grey.shade200),
                 ),
                 child: Column(
                   children: [
                     _buildSummaryRow('ราคาต่อหน่วย', '${currencyFormat.format(_pricePerUnit)} บาท'),
                     const Divider(height: 24),
                     _buildSummaryRow('ราคารวม ($_units หุ้น)', '${currencyFormat.format(totalBody)} บาท'),
                     const Divider(height: 24),
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text('ยอดชำระสุทธิ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                         Text(
                           '${currencyFormat.format(totalBody)} บาท',
                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                           overflow: TextOverflow.ellipsis,
                         ),
                       ],
                     )
                   ],
                 ),
               ),

               const SizedBox(height: 48),
               
               SizedBox(
                 height: 56,
                 child: ElevatedButton(
                   onPressed: _submit,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     shape: RoundedRectangleBorder(
                       borderRadius: BorderRadius.circular(16),
                     ),
                     elevation: 0,
                   ),
                   child: const Text('ถัดไป (เลือกช่องทางชำระเงิน)', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isVat = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isVat ? Colors.orange : Colors.grey.shade700)),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: isVat ? Colors.orange : Colors.black), overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
