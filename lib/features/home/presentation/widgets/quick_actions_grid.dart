import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/kyc_required_dialog.dart';
import '../../../auth/domain/user_role.dart';

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
              () => _handleAction(context, '/wallet/topup'),
            ),
            _buildActionItem(
              context,
              LucideIcons.arrowUpFromLine,
              'ถอน',
              () => _handleAction(context, '/wallet/withdraw'),
            ),
            _buildActionItem(
              context, 
              LucideIcons.arrowRightLeft, 
              'โอน', 
              () => _handleAction(context, '/transfer'),
            ),
            _buildActionItem(
              context,
              LucideIcons.scanLine,
              'จ่าย/รับ',
              () => _handleAction(context, '/payment/source'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String route) async {
    if (CurrentUser.kycStatus != 'verified' && CurrentUser.kycStatus != 'approved') {
      await showKYCRequiredDialog(context);
      return;
    }
    if (context.mounted) {
      context.push(route);
    }
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
