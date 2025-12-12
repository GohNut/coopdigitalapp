import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/loan_request_args.dart';
import '../../data/loan_repository_impl.dart';

class LoanReviewScreen extends StatelessWidget {
  final LoanRequestArgs args;

  const LoanReviewScreen({super.key, required this.args});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ตรวจสอบข้อมูล'),
        centerTitle: true,
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
                _buildStepLine(true),
                _buildStepIndicator(3, 'เอกสาร', true),
                _buildStepLine(true),
                _buildStepIndicator(4, 'ยืนยัน', true),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Summary Card - Loan Details
            _buildSectionCard(
              context,
              title: 'รายละเอียดสินเชื่อ',
              icon: Icons.account_balance,
              children: [
                _buildSummaryRow(context, 'ประเภทสินเชื่อ', args.product.name),
                _buildSummaryRow(context, 'วงเงินขอกู้', NumberFormat.currency(symbol: '฿').format(args.amount), isHighlight: true),
                _buildSummaryRow(context, 'ระยะเวลาผ่อน', '${args.months} งวด'),
                _buildSummaryRow(context, 'อัตราดอกเบี้ย', '${args.product.interestRate}% ต่อปี'),
                _buildSummaryRow(context, 'ผ่อนชำระต่องวด', NumberFormat.currency(symbol: '฿').format(args.monthlyPayment), isHighlight: true),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Objective & Guarantor
            _buildSectionCard(
              context,
              title: 'ข้อมูลการกู้',
              icon: Icons.description,
              children: [
                _buildSummaryRow(context, 'วัตถุประสงค์', args.objective ?? 'ไม่ได้ระบุ'),
                if (args.product.requireGuarantor)
                  _buildSummaryRow(context, 'ผู้ค้ำประกัน', args.guarantorMemberId ?? 'ไม่ได้ระบุ')
                else
                  _buildSummaryRow(context, 'ผู้ค้ำประกัน', 'ไม่ต้องใช้'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Documents
            _buildSectionCard(
              context,
              title: 'เอกสารแนบ',
              icon: Icons.folder,
              children: [
                if (args.idCardFileName != null)
                  _buildDocumentRow(context, 'สำเนาบัตรประชาชน', args.idCardFileName!),
                if (args.salarySlipFileName != null)
                  _buildDocumentRow(context, 'สลิปเงินเดือน', args.salarySlipFileName!),
                if (args.otherFileName != null)
                  _buildDocumentRow(context, 'เอกสารอื่นๆ', args.otherFileName!),
                if (args.idCardFileName == null && args.salarySlipFileName == null && args.otherFileName == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ไม่มีเอกสารแนบ',
                      style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bank Account
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.account_balance, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'บัญชีรับเงินกู้',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'บัญชีออมทรัพย์ xxx-x-xx456-7',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // SLA Warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'การพิจารณาอนุมัติใช้เวลาประมาณ 3-5 วันทำการ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.warning),
                    ),
                  ),
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
              onPressed: () async {
                final result = await context.push<bool>('/loan/pin');
                if (result == true && context.mounted) {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator()),
                  );

                  try {
                    final repository = LoanRepositoryImpl();
                    await repository.submitApplication(
                      productId: args.product.id,
                      amount: args.amount,
                      months: args.months,
                      guarantorId: args.guarantorMemberId,
                      objective: args.objective,
                    );
                    
                    if (context.mounted) {
                      Navigator.pop(context); // Dismiss loading
                      context.go('/loan/success');
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Dismiss loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'ยืนยันส่งคำขอ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentRow(BuildContext context, String label, String fileName) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                Text(fileName, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
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
