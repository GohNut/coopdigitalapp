import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_request_args.dart';

class LoanInfoScreen extends StatefulWidget {
  final LoanRequestArgs args;

  const LoanInfoScreen({super.key, required this.args});

  @override
  State<LoanInfoScreen> createState() => _LoanInfoScreenState();
}

class _LoanInfoScreenState extends State<LoanInfoScreen> {
  final TextEditingController _objectiveController = TextEditingController();
  final TextEditingController _guarantorController = TextEditingController();

  @override
  void dispose() {
    _objectiveController.dispose();
    _guarantorController.dispose();
    super.dispose();
  }

  void _goNext() {
    final updatedArgs = widget.args.copyWith(
      objective: _objectiveController.text.isEmpty ? null : _objectiveController.text,
      guarantorMemberId: _guarantorController.text.isEmpty ? null : _guarantorController.text,
    );
    context.push('/loan/document', extra: updatedArgs);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.args.product;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ข้อมูลการกู้'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress indicator
            Row(
              children: [
                _buildStepIndicator(1, 'วงเงิน', true),
                _buildStepLine(true),
                _buildStepIndicator(2, 'ข้อมูล', true),
                _buildStepLine(false),
                _buildStepIndicator(3, 'เอกสาร', false),
                _buildStepLine(false),
                _buildStepIndicator(4, 'ยืนยัน', false),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Objective Input
            Text(
              'วัตถุประสงค์การกู้',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _objectiveController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'เช่น เพื่อการศึกษา, เพื่อซ่อมแซมที่อยู่อาศัย, เพื่อการลงทุน',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // Guarantor Section
            if (product.requireGuarantor) ...[
              Text(
                'เลขสมาชิกผู้ค้ำประกัน',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'สินเชื่อประเภทนี้ต้องมีผู้ค้ำประกัน',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _guarantorController,
                decoration: InputDecoration(
                  hintText: 'ระบุเลขสมาชิกผู้ค้ำประกัน',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ไม่ต้องใช้ผู้ค้ำประกัน',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'สินเชื่อประเภท ${product.name} ไม่ต้องมีผู้ค้ำประกัน',
                            style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

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
              onPressed: _goNext,
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

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey.shade300,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? AppColors.textPrimary : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}
