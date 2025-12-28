import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';

class SlipWidget extends StatelessWidget {
  final Map<String, dynamic> slipInfo;

  const SlipWidget({super.key, required this.slipInfo});

  @override
  Widget build(BuildContext context) {
    // Extract data from slipInfo
    final transactionRef = slipInfo['transaction_ref'] ?? '';
    final transactionDate = slipInfo['transaction_date'] != null 
        ? DateTime.parse(slipInfo['transaction_date'].toString()) 
        : DateTime.now();
    final amount = (slipInfo['amount'] ?? 0.0).toDouble();
    final qrPayload = slipInfo['qr_payload'] ?? '';

    final sender = slipInfo['sender'] ?? {};
    final receiver = slipInfo['receiver'] ?? {};

    return Container(
      width: 350,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Logo & Result
          Row(
            children: [
              ClipOval(
                child: Image.asset(
                  'assets/pic/logoCoop.jpg',
                  width: 45,
                  height: 45,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'สหกรณ์ รสพ.',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.check_circle, color: AppColors.success, size: 32),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'โอนเงินสำเร็จ',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${DateFormat('dd MMM', 'th').format(transactionDate.toLocal())} ${transactionDate.year + 543}, ${DateFormat('HH:mm').format(transactionDate.toLocal())}',
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          
          // Amount
          Text(
            '${NumberFormat('#,##0.00').format(amount)} บาท',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),

          // Sender
          _buildAccountInfo(
            label: 'จาก',
            name: sender['name'] ?? '',
            accountNo: sender['account_no_masked'] ?? '',
            bankName: sender['bank_name'] ?? 'Coop Saving',
            isSender: true,
          ),
          
          const SizedBox(height: 16),
          
          // Receiver
          _buildAccountInfo(
            label: 'ไปยัง',
            name: receiver['name'] ?? '',
            accountNo: receiver['account_no_masked'] ?? '',
            bankName: receiver['bank_name'] ?? '',
            isSender: false,
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1, color: AppColors.divider),
          ),

          // Transaction Ref
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เลขที่อ้างอิง',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  transactionRef,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo({
    required String label,
    required String name,
    required String accountNo,
    required String bankName,
    required bool isSender,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 40,
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              Text(
                accountNo,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
