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
      margin: const EdgeInsets.symmetric(horizontal: 24),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCompactBalanceRow(
              context,
              icon: LucideIcons.wallet,
              iconColor: AppColors.secondary,
              title: 'บัญชีออมทรัพย์',
              amount: '฿ 750,000.00',
              isVisible: _isVisible,
              showVisibilityToggle: true,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: AppColors.divider),
            ),
            Row(
              children: [
                Expanded(
                  child: _buildCompactBalanceRow(
                    context,
                    icon: LucideIcons.pieChart,
                    iconColor: AppColors.success,
                    title: 'มูลค่าหุ้นรวม',
                    amount: '฿ 125,000.00',
                    isVisible: _isVisible,
                    showVisibilityToggle: false,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: _buildCompactBalanceRow(
                    context,
                    icon: LucideIcons.creditCard,
                    iconColor: AppColors.warning,
                    title: 'วงเงินกู้คงเหลือ',
                    amount: '฿ 350,000.00',
                    isVisible: _isVisible,
                    showVisibilityToggle: false,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactBalanceRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String amount,
    required bool isVisible,
    required bool showVisibilityToggle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 14,
                    color: iconColor,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                isVisible ? amount : '••••••',
                style: showVisibilityToggle
                    ? Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        )
                    : Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
              ),
            ],
          ),
        ),
        if (showVisibilityToggle)
          IconButton(
            onPressed: () {
              setState(() {
                _isVisible = !_isVisible;
              });
            },
            icon: Icon(
              isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
              color: AppColors.secondary,
              size: 20,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
