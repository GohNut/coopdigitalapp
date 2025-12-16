import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import 'dart:math' as math;

class WealthCalculatorDialog extends StatefulWidget {
  const WealthCalculatorDialog({super.key});

  @override
  State<WealthCalculatorDialog> createState() => _WealthCalculatorDialogState();
}

class _WealthCalculatorDialogState extends State<WealthCalculatorDialog> {
  double _monthlyDeposit = 1000;
  int _years = 5;
  double _dividendRate = 5.0; // 5%

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "th_TH");
    
    // Simple Future Value Calculation
    final r = (_dividendRate / 100) / 12;
    final n = _years * 12;
    final futureValue = _monthlyDeposit * (((math.pow(1 + r, n) - 1) / r)) * (1 + r);
    final totalDeposit = _monthlyDeposit * n;
    final totalInterest = futureValue - totalDeposit;


    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.calculator, color: AppColors.primary),
                const SizedBox(width: 12),
                const Text(
                  'เครื่องคำนวณความมั่งคั่ง',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(LucideIcons.x, color: Colors.grey),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Sliders
            _buildSlider(
              'ฝากรายเดือน', 
              '${currencyFormat.format(_monthlyDeposit)} บาท', 
              _monthlyDeposit, 500, 10000, 500,
              (val) => setState(() => _monthlyDeposit = val),
            ),
             const SizedBox(height: 16),
            _buildSlider(
              'ระยะเวลา', 
              '$_years ปี', 
              _years.toDouble(), 1, 30, 1,
              (val) => setState(() => _years = val.toInt()),
            ),
             const SizedBox(height: 16),
            _buildSlider(
              'ปันผลคาดการณ์', 
              '${_dividendRate.toStringAsFixed(1)}%', 
              _dividendRate, 1, 10, 0.5,
              (val) => setState(() => _dividendRate = val),
            ),
            
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                   const Text('เงินจะมีมูลค่ารวม', style: TextStyle(color: Colors.white70)),
                   const SizedBox(height: 4),
                   Text(
                     '${currencyFormat.format(futureValue)}',
                     style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                   ),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('เงินต้น: ${currencyFormat.format(totalDeposit)}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                       Text('กำไร: ${currencyFormat.format(totalInterest)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
                     ],
                   )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider(String label, String valueLabel, double value, double min, double max, double divisions, Function(double) onChanged) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(valueLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) / divisions).round(),
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

