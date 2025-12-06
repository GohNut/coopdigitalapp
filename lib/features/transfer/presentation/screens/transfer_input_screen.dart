import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/transfer_service.dart';

class TransferInputScreen extends StatefulWidget {
  final Map<String, dynamic> member;

  const TransferInputScreen({super.key, required this.member});

  @override
  State<TransferInputScreen> createState() => _TransferInputScreenState();
}

class _TransferInputScreenState extends State<TransferInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onReview() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ยอดโอนขั้นต่ำ 1.00 บาท')));
      return;
    }

    // Show Confirmation Bottom Sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildConfirmationSheet(amount),
    );
  }

  Widget _buildConfirmationSheet(double amount) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'ตรวจสอบข้อมูล',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildDetailRow('จาก', 'กระเป๋าเงิน (Cash Wallet)'),
          const SizedBox(height: 12),
          _buildDetailRow('ไปยัง', widget.member['display_name']),
          const SizedBox(height: 12),
          _buildDetailRow('จำนวนเงิน', '฿ ${NumberFormat('#,##0.00').format(amount)}', isBold: true),
          if (_noteController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDetailRow('บันทึกช่วยจำ', _noteController.text),
          ],
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _processTransfer(amount);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('ยืนยันการโอน', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
              fontSize: isBold ? 18 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _processTransfer(double amount) async {
    // 1. PIN Check
    final pinSuccess = await context.push<bool>('/pin');
    if (pinSuccess != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await transferServiceProvider.transfer(
        targetMemberId: widget.member['member_id'],
        amount: amount,
        note: _noteController.text,
      );

      if (mounted) {
        // Go to Success Screen
        context.go('/transfer/success', extra: {
          ...result,
          'target_name': widget.member['display_name'],
          'note': _noteController.text,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ระบุจำนวนเงิน'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Target Member Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(widget.member['avatar_url']),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.member['display_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(widget.member['member_id'], style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Amount Input
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              decoration: const InputDecoration(
                hintText: '0.00',
                border: InputBorder.none,
                prefixText: '฿ ',
                prefixStyle: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ),
            const Text('ยอดเงินในกระเป๋า: ฿ 10,000.00', style: TextStyle(color: AppColors.textSecondary)),
            
            const SizedBox(height: 32),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: 'บันทึกช่วยจำ (ถ้ามี)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.edit_note, color: AppColors.textSecondary),
              ),
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ถัดไป', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
