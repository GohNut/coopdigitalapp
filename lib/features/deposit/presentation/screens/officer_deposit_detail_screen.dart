import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../services/dynamic_deposit_api.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../notification/domain/notification_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../core/widgets/full_screen_image_viewer.dart';

class OfficerDepositDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> deposit;

  const OfficerDepositDetailScreen({super.key, required this.deposit});

  @override
  ConsumerState<OfficerDepositDetailScreen> createState() => _OfficerDepositDetailScreenState();
}

class _OfficerDepositDetailScreenState extends ConsumerState<OfficerDepositDetailScreen> {
  bool _isProcessing = false;
  final currencyFormat = NumberFormat.currency(locale: 'th_TH', symbol: '฿');
  final dateFormat = DateFormat('dd MMM yyyy HH:mm', 'th');

  Future<void> _approve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ยืนยันการอนุมัติ'),
        content: const Text('ยอดเงินจะถูกโอนเข้าบัญชีสมาชิกทันที'),
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
      final txnId = widget.deposit['transactionid'];
      final accountId = widget.deposit['accountid']; // Get accountId for invalidation
      await DynamicDepositApiService.approveDeposit(txnId);
      
      // Invalidate all related providers to refresh member's UI
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('อนุมัติเรียบร้อยแล้ว')));

        // Add notification for member
        ref.read(notificationProvider.notifier).addNotification(
          NotificationModel.now(
            title: 'การฝากเงินสำเร็จ',
            message: 'ยอดเงินฝากจำนวน ${currencyFormat.format((widget.deposit['amount'] ?? 0.0).toDouble())} เข้าบัญชีของคุณเรียบร้อยแล้ว',
            type: NotificationType.success,
          ),
        );
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
            const Text('ระบบจะสร้างรายการฝากเข้าและถอนออกเพื่อบันทึกประวัติ'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'เหตุผลการปฏิเสธ',
                hintText: 'เช่น สลิปไม่ถูกต้อง'
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
      final txnId = widget.deposit['transactionid'];
      final accountId = widget.deposit['accountid']; // Get accountId for invalidation
      await DynamicDepositApiService.rejectDeposit(txnId, reason: reasonController.text);
      
      // Invalidate all related providers to refresh member's UI
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      
      if (mounted) {
        Navigator.pop(context, true); // Return true to refresh list
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ปฏิเสธรายการเรียบร้อยแล้ว')));

        // Add notification for member
        ref.read(notificationProvider.notifier).addNotification(
          NotificationModel.now(
            title: 'การฝากเงินไม่สำเร็จ',
            message: 'รายการฝากเงินจำนวน ${currencyFormat.format((widget.deposit['amount'] ?? 0.0).toDouble())} ถูกปฏิเสธ: ${reasonController.text}',
            type: NotificationType.error,
          ),
        );
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
    final amount = (widget.deposit['amount'] ?? 0.0).toDouble();
    final date = DateTime.tryParse(widget.deposit['datetime'] ?? '') ?? DateTime.now();
    final slipPath = widget.deposit['slip_image'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียดการฝาก')),
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
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('ยอดเงินฝาก', style: TextStyle(color: Colors.white70, fontSize: 16)),
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

            const Text('หลักฐานการโอนเงิน (Slip)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (slipPath != null && slipPath.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: kIsWeb 
                   ? GestureDetector(
                       onTap: () => Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => FullScreenImageViewer(
                             imagePath: slipPath,
                             isNetwork: true,
                             title: 'สลิปโอนเงิน',
                           ),
                         ),
                       ),
                       child: Hero(
                         tag: slipPath,
                         child: Image.network(
                             slipPath,
                             width: double.infinity,
                             fit: BoxFit.cover,
                             loadingBuilder: (ctx, child, loading) {
                               if (loading == null) return child;
                               return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                             },
                             errorBuilder: (ctx, err, stack) => Container(
                               height: 200,
                               color: Colors.grey[200],
                               child: const Center(child: Text('ไม่สามารถโหลดรูปภาพได้')),
                             ),
                           ),
                       ),
                     )
                   : GestureDetector(
                       onTap: () => Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => FullScreenImageViewer(
                             imagePath: slipPath,
                             isNetwork: false,
                             title: 'สลิปโอนเงิน',
                           ),
                         ),
                       ),
                       child: Hero(
                         tag: slipPath,
                         child: Image.file(
                             File(slipPath),
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                               height: 200,
                               color: Colors.grey[200],
                               child: const Center(child: Text('ไฟล์รูปภาพไม่ถูกต้อง')),
                             ),
                           ),
                       ),
                     ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('ไม่มีรูปสลิปแนบมา')),
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
}
