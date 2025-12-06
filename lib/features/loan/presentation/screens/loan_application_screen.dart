import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_product_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/repository_providers.dart';

class LoanApplicationScreen extends ConsumerStatefulWidget {
  final String productId;
  const LoanApplicationScreen({super.key, required this.productId});

  @override
  ConsumerState<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends ConsumerState<LoanApplicationScreen> {
  int _currentStep = 0;
  double _requestAmount = 10000;
  int _months = 12;
  
  // Controller สำหรับ TextField
  late TextEditingController _amountController;

  // Mock finding product
  LoanProduct get product => LoanProduct.mockProducts.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => LoanProduct.mockProducts.first,
      );

  @override
  void initState() {
    super.initState();
    // แปลงค่า double เป็น string (ไม่ใส่ comma เพื่อให้พิมพ์ได้)
    _amountController = TextEditingController(text: _requestAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  // ฟังก์ชันอัปเดตเมื่อเลื่อน Slider
  void _updateSlider(double value) {
    setState(() {
      _requestAmount = value;
      // อัปเดตตัวเลขในช่องกรอก ให้ตรงกับ Slider
      _amountController.text = value.toStringAsFixed(0);
    });
  }

  // ฟังก์ชันอัปเดตเมื่อพิมพ์ตัวเลข
  void _updateText(String value) {
    if (value.isEmpty) return;
    
    // แปลง Text เป็น Double
    double? parsedValue = double.tryParse(value);
    
    if (parsedValue != null) {
      // Clamp ไม่ให้ค่าเกิน Min/Max
      if (parsedValue < 5000) parsedValue = 5000;
      if (parsedValue > product.maxAmount) parsedValue = product.maxAmount;

      setState(() {
        _requestAmount = parsedValue!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ยื่นกู้${product.name}')),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep++);
          } else {
             // Submit
             // Call Repository
             _submitApplication();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
           return Padding(
             padding: const EdgeInsets.only(top: 24),
             child: Row(
               children: [
                 Expanded(child: ElevatedButton(onPressed: details.onStepContinue, child: Text(_currentStep == 2 ? 'ยืนยันการกู้' : 'ถัดไป'))),
                 if (_currentStep > 0) ...[
                   const SizedBox(width: 16),
                   Expanded(child: OutlinedButton(onPressed: details.onStepCancel, child: const Text('ย้อนกลับ'))),
                 ]
               ],
             ),
           );
        },
        steps: [
          Step(
            title: const Text('วงเงิน'),
            content: _buildCalculatorStep(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('ข้อมูล'),
            content: _buildInfoStep(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('ยืนยัน'),
            content: _buildReviewStep(),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatorStep() {
    // Simple PMT Calculation: P * r * (1+r)^n / ((1+r)^n - 1)
    // Monthly rate
    final monthlyRate = product.interestRate / 100 / 12;
    final installment = (_requestAmount * monthlyRate * pow(1 + monthlyRate, _months)) / (pow(1 + monthlyRate, _months) - 1);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('วงเงินที่ต้องการขอกู้', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        
        // TextField + Slider แบบ Two-way binding
        Row(
          children: [
            // ส่วนของ Slider
            Expanded(
              child: Slider(
                value: _requestAmount,
                min: 5000,
                max: product.maxAmount,
                divisions: ((product.maxAmount - 5000) / 1000).round(),
                label: _requestAmount.round().toString(),
                onChanged: _updateSlider,
              ),
            ),
            
            const SizedBox(width: 16),

            // ส่วนของช่องกรอกตัวเลข
            SizedBox(
              width: 140, // เพิ่มความกว้างนิดหน่อย
              child: TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9]')), // อนุญาตเฉพาะตัวเลข 0-9
                ],
                decoration: InputDecoration(
                  prefixText: '฿ ',
                  prefixStyle: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  isDense: true,
                ),
                onChanged: _updateText,
              ),
            ),
          ],
        ),
        
        // Min/Max labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('฿5,000', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('฿${NumberFormat("#,##0").format(product.maxAmount)}', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // แสดงยอดที่เลือก
        Center(
          child: Text(
            'วงเงิน ฿${NumberFormat("#,##0").format(_requestAmount)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        Text('จำนวนงวดผ่อนชำระ', style: Theme.of(context).textTheme.titleMedium),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [12, 24, 36, 48, 60, 72, 84, 120, 180, 240, 300, 360]
              .where((m) => m <= product.maxMonths)
              .map((m) => ChoiceChip(
                    label: Text(m >= 12 ? '${m ~/ 12} ปี${m % 12 > 0 ? ' ${m % 12} เดือน' : ''}' : '$m งวด'),
                    selected: _months == m,
                    onSelected: (selected) {
                      if (selected) setState(() => _months = m);
                    },
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ผ่อนชำระงวดละ (ประมาณ)'),
              Text(
                '฿ ${NumberFormat("#,##0.00").format(installment)}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildInfoStep() {
    return Column(
      children: [
        TextFormField(
          initialValue: 'วัตถุประสงค์การกู้',
          decoration: const InputDecoration(labelText: 'วัตถุประสงค์'),
        ),
        const SizedBox(height: 16),
        if (product.requireGuarantor)
           TextFormField(
            decoration: const InputDecoration(
              labelText: 'ระบุเลขสมาชิกผู้ค้ำประกัน',
              suffixIcon: Icon(Icons.search),
            ),
          ),
           if (!product.requireGuarantor)
           const Text('สินเชื่อนี้ไม่ต้องใช้คนค้ำประกัน', style: TextStyle(color: Colors.green)),
      ],
    );
  }

  Widget _buildReviewStep() {
     return Card(
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
           children: [
             ListTile(title: const Text('ประเภทเงินกู้'), trailing: Text(product.name)),
             ListTile(title: const Text('ยอดขอกู้'), trailing: Text('${NumberFormat("#,##0").format(_requestAmount)} บ.')),
             ListTile(title: const Text('จำนวนงวด'), trailing: Text('$_months งวด')),
             const Divider(),
             const Text('กรุณาตรวจสอบข้อมูลก่อนกดยืนยัน'),
           ],
         ),
       ),
     );
  }
  
  double pow(double x, int exponent) {
    // Simple pow for dart
    double result = 1;
    for (int i = 0; i < exponent; i++) {
        result *= x;
    }
    return result;
  }
  
  Future<void> _submitApplication() async {
    try {
      // Show loading (optional)
      
      await ref.read(loanRepositoryProvider).submitApplication(
        productId: product.id,
        amount: _requestAmount,
        months: _months,
        // TODO: Get actual input values
        objective: 'เพื่อการใช้จ่าย', 
      );
      
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('ส่งคำขอสำเร็จ'),
          content: const Text('ระบบได้รับคำขอของท่านแล้ว (บันทึกลง Firebase)'),
          actions: [TextButton(onPressed: () {
             Navigator.pop(ctx); // Close dialog
             Navigator.pop(context); // Back to home
          }, child: const Text('ตกลง'))],
        )
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
    }
  }
}
