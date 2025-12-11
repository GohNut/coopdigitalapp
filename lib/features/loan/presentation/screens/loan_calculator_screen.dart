import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_product_model.dart';
import '../../domain/loan_request_args.dart';
import '../widgets/loan_overview_card.dart'; // Reusing styles if needed, or creating fresh

class LoanCalculatorScreen extends StatefulWidget {
  final String productId;

  const LoanCalculatorScreen({super.key, required this.productId});

  @override
  State<LoanCalculatorScreen> createState() => _LoanCalculatorScreenState();
}

class _LoanCalculatorScreenState extends State<LoanCalculatorScreen> {
  late LoanProduct product;
  double _amount = 10000;
  int _months = 12;

  // Calculation results
  double _monthlyPayment = 0;
  double _totalInterest = 0;
  double _totalPayment = 0;

  @override
  void initState() {
    super.initState();
    // In a real app, use provider/repo to get product by ID.
    // Here we find it from mock data.
    product = LoanProduct.mockProducts.firstWhere(
      (p) => p.id == widget.productId,
      orElse: () => LoanProduct.mockProducts[0],
    );
    _amount = product.maxAmount / 2; // Default to half max
    if (_amount < 1000) _amount = 1000;
    
    _calculate();
  }

  void _calculate() {
    // Flat Rate Formula
    // Interest = Principal * Rate * Years
    double years = _months / 12;
    _totalInterest = _amount * (product.interestRate / 100) * years;
    _totalPayment = _amount + _totalInterest;
    _monthlyPayment = _totalPayment / _months;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('คำนวณวงเงินกู้'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info Header
             Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.calculator, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'ดอกเบี้ย ${product.interestRate}% ต่อปี',
                       style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Amount Input
            Text(
              'วงเงินที่ต้องการขอกู้',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: NumberFormat("#,##0").format(_amount)),
              readOnly: true, // For demo, making it read-only to rely on slider
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                prefixText: '฿ ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _amount,
              min: 1000,
              max: product.maxAmount,
              divisions: 100,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() {
                  _amount = value;
                  _calculate();
                });
              },
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ต่ำสุด: 1,000'),
                Text('สูงสุด: ${NumberFormat.compact().format(product.maxAmount)}'),
              ],
            ),

            const SizedBox(height: 32),

            // Duration Selector
            Text(
              'ระยะเวลาผ่อนชำระ (เดือน)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [6, 12, 18, 24, 36, 48, 60]
                  .where((m) => m <= product.maxMonths)
                  .map((m) => ChoiceChip(
                        label: Text('$m งวด'),
                        selected: _months == m,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _months = m;
                              _calculate();
                            });
                          }
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: _months == m ? Colors.white : AppColors.textPrimary,
                        ),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 32),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildSummaryRow(context, 'ค่างวดต่อเดือน', NumberFormat.currency(symbol: '฿').format(_monthlyPayment), isHighlight: true),
                  const Divider(height: 32),
                  _buildSummaryRow(context, 'ดอกเบี้ยรวมโดยประมาณ', NumberFormat.currency(symbol: '฿').format(_totalInterest)),
                  const SizedBox(height: 16),
                  _buildSummaryRow(context, 'ยอดชำระคืนทั้งหมด', NumberFormat.currency(symbol: '฿').format(_totalPayment)),
                ],
              ),
            ),
             const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/loan/info', extra: LoanRequestArgs(
                  product: product,
                  amount: _amount,
                  months: _months,
                  monthlyPayment: _monthlyPayment,
                  totalInterest: _totalInterest,
                  totalPayment: _totalPayment,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'ถัดไป',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: isHighlight
              ? Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  )
              : Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
