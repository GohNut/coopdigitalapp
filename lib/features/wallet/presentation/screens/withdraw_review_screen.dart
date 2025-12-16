import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/withdraw_service.dart';

class WithdrawReviewScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const WithdrawReviewScreen({super.key, required this.args});

  @override
  State<WithdrawReviewScreen> createState() => _WithdrawReviewScreenState();
}

class _WithdrawReviewScreenState extends State<WithdrawReviewScreen> {
  bool _isLoading = false;

  Future<void> _processWithdrawal() async {
    // 1. Verify PIN
    final pinSuccess = await context.push<bool>('/pin');
    
    if (pinSuccess == true) {
      // 2. Process Withdrawal
      setState(() => _isLoading = true);
      
      try {
        await withdrawServiceProvider.withdraw(
          bankId: widget.args['bankId'],
          accountNo: widget.args['accountNo'],
          amount: widget.args['amount'],
        );

        if (mounted) {
          // 3. Show Success
          // For now, show a dialog or snackbar and go back to home
          // Ideal: Go to a Success Slip Screen
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              title: const Icon(Icons.check_circle, color: Colors.green, size: 64),
              content: const Text(
                'ทำรายการถอนเงินสำเร็จ\nเงินจะเข้าบัญชีภายใน 1-2 วันทำการ',
                textAlign: TextAlign.center,
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/home');
                  },
                  child: const Text('ตกลง'),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.args['amount'] as double;
    final bankName = widget.args['bankName'] as String;
    final accountNo = widget.args['accountNo'] as String;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ตรวจสอบข้อมูล'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('ยอดถอนเงิน', style: TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text(
                    '${NumberFormat('#,##0.00').format(amount)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildDetailRow('ธนาคาร', bankName),
                  const SizedBox(height: 12),
                  _buildDetailRow('เลขที่บัญชี', accountNo),
                  const SizedBox(height: 12),
                  _buildDetailRow('ค่าธรรมเนียม', '0.00'),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'ยอดหักบัญชี', 
                    '${NumberFormat('#,##0.00').format(amount)}',
                    isBold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('ยืนยันทำรายการ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: AppColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
