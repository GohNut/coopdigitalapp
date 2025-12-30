import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/domain/deposit_account.dart';

class QrReceiveWidget extends StatelessWidget {
  final DepositAccount account;
  final String? amount;

  const QrReceiveWidget({
    super.key,
    required this.account,
    this.amount,
  });

  String _generateReceiveQrData() {
    final cleanAmount = amount?.replaceAll(',', '') ?? '';
    String url = 'coop://pay?account_id=${account.id}&name=${Uri.encodeComponent(account.accountName)}';
    if (cleanAmount.isNotEmpty) url += '&amount=$cleanAmount';
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'สแกนเพื่อจ่ายเงิน',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            height: 200,
            child: PrettyQrView.data(
              data: _generateReceiveQrData(),
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            account.accountName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
          Text(
            'เลขที่บัญชี: ${account.accountNumber}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (amount != null && amount!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ยอดเงิน: $amount บาท',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
