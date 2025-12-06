import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class WalletCard extends StatefulWidget {
  const WalletCard({super.key});

  @override
  State<WalletCard> createState() => _WalletCardState();
}

class _WalletCardState extends State<WalletCard> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildBalanceRow(
              context,
              title: 'กระเป๋าเงิน',
              amount: '฿ 10,000.00',
              isVisible: _isVisible,
              isPrimary: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            _buildBalanceRow(
              context,
              title: 'วงเงินคงเหลือ',
              amount: '฿ 750.00',
              isVisible: _isVisible,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(
    BuildContext context, {
    required String title,
    required String amount,
    required bool isVisible,
    required bool isPrimary,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isPrimary ? LucideIcons.wallet : LucideIcons.creditCard,
                  size: 16,
                  color: isPrimary ? AppColors.secondary : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isVisible ? amount : '••••••',
              style: isPrimary
                  ? Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 28,
                        color: AppColors.primary,
                      )
                  : Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
            ),
          ],
        ),
        if (isPrimary)
          IconButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            icon: Icon(
              isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
              color: AppColors.textSecondary,
            ),
          ),
          if(!isPrimary)
             ElevatedButton(
                onPressed: () => context.push('/wallet/topup'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('เติมเงิน', style: TextStyle(fontSize: 12)),
             )
      ],
    );
  }
}
