import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionItem(
              context,
              LucideIcons.arrowDownToLine,
              'ฝาก',
              () => context.push('/wallet/topup'),
            ),
            _buildActionItem(
              context,
              LucideIcons.arrowUpFromLine,
              'ถอน',
              () => context.push('/wallet/withdraw'),
            ),
            _buildActionItem(
              context, 
              LucideIcons.arrowRightLeft, 
              'โอน', 
              () => context.push('/transfer'),
            ),
            _buildActionItem(context, LucideIcons.scanLine, 'จ่าย/รับ', () => context.push('/payment/source')),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
