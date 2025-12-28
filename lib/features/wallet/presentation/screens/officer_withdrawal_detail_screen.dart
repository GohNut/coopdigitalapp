import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_withdrawal_api.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../notification/domain/notification_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';

class OfficerWithdrawalDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> withdrawal;

  const OfficerWithdrawalDetailScreen({super.key, required this.withdrawal});

  @override
  ConsumerState<OfficerWithdrawalDetailScreen> createState() => _OfficerWithdrawalDetailScreenState();
}

class _OfficerWithdrawalDetailScreenState extends ConsumerState<OfficerWithdrawalDetailScreen> {
  bool _isProcessing = false;
  final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');

  Future<void> _approve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการอนุมัติ'),
        content: const Text('ยืนยันว่าได้ทำการโอนเงินให้สมาชิกแล้ว ระบบจะเปลี่ยนสถานะเป็นสำเร็จ'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white),
            child: const Text('ยืนยัน'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final txnId = widget.withdrawal['transactionid'];
      final accountId = widget.withdrawal['accountid']; 
      await DynamicWithdrawalApiService.approveWithdrawal(txnId);
      
      // Invalidate providers
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      
      // Add notification for member (Step 3)
      final memberId = widget.withdrawal['memberid'] as String?;
      final amount = widget.withdrawal['amount'];
      double amountValue = 0.0;
      if (amount is num) {
        amountValue = amount.toDouble();
      } else if (amount is String) {
        amountValue = double.tryParse(amount) ?? 0.0;
      }
      
      if (memberId != null && memberId.isNotEmpty) {
        ref.read(notificationProvider.notifier).addNotificationToMember(
          memberId: memberId,
          notification: NotificationModel.now(
            title: 'เงินถอนได้รับการอนุมัติ',
            message: 'รายการถอนเงินจำนวน ${currencyFormat.format(amountValue)} ได้รับการอนุมัติและโอนเงินให้คุณเรียบร้อยแล้ว',
            type: NotificationType.success,
          ),
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อนุมัติเรียบร้อยแล้ว')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการปฏิเสธ'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('ระบบจะทำการคืนเงินเข้าบัญชีสมาชิกโดยอัตโนมัติ'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'เหตุผลการปฏิเสธ',
                hintText: 'เช่น ข้อมูลบัญชีไม่ถูกต้อง'
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('ยืนยันปฏิเสธ'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final txnId = widget.withdrawal['transactionid'];
      final accountId = widget.withdrawal['accountid'];
      await DynamicWithdrawalApiService.rejectWithdrawal(txnId, reason: reasonController.text);
      
      // Invalidate providers
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      
      // Add notification for member (Step 3)
      final memberId = widget.withdrawal['memberid'] as String?;
      final amount = widget.withdrawal['amount'];
      double amountValue = 0.0;
      if (amount is num) {
        amountValue = amount.toDouble();
      } else if (amount is String) {
        amountValue = double.tryParse(amount) ?? 0.0;
      }
      
      if (memberId != null && memberId.isNotEmpty) {
        ref.read(notificationProvider.notifier).addNotificationToMember(
          memberId: memberId,
          notification: NotificationModel.now(
            title: 'เงินถอนถูกปฏิเสธ',
            message: 'รายการถอนเงินจำนวน ${currencyFormat.format(amountValue)} ถูกปฏิเสธและคืนเงินเข้าบัญชีแล้ว${reasonController.text.isNotEmpty ? ": ${reasonController.text}" : ""}',
            type: NotificationType.error,
          ),
        );
      }
      
      if (mounted) {
        Navigator.pop(context, true); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปฏิเสธรายการเรียบร้อยแล้ว (คืนเงินสำเร็จ)')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Robust parsing
    double amount = 0.0;
    final rawAmount = widget.withdrawal['amount'];
    if (rawAmount is num) {
      amount = rawAmount.toDouble();
    } else if (rawAmount is String) {
      amount = double.tryParse(rawAmount) ?? 0.0;
    }

    final date = DateTime.tryParse(widget.withdrawal['datetime'] ?? '') ?? DateTime.now();
    final destinationBank = widget.withdrawal['destination_bank'] ?? '-';
    final destinationAccount = widget.withdrawal['destination_account'] ?? '-';
    // final accountId = widget.withdrawal['accountid'] ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดการถอนเงิน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.error, // Red for withdrawal
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('ยอดถอนเงิน', style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormat.format(amount),
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(date),
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('ข้อมูลการโอนเงินปลายทาง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                   _buildRow('ธนาคาร', destinationBank),
                   const Divider(height: 24),
                   _buildRow('เลขที่บัญชี', destinationAccount, isBold: true),
                ],
              ),
            ),

            const SizedBox(height: 32),
            
            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _reject,
                      icon: const Icon(LucideIcons.xCircle),
                      label: const Text('ปฏิเสธ'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        foregroundColor: AppColors.error,
                        side: const BorderSide(color: AppColors.error),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _approve,
                      icon: const Icon(LucideIcons.checkCircle),
                      label: const Text('อนุมัติ'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }
}
