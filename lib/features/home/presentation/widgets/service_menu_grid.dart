import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/user_role.dart';
import '../../../loan/presentation/screens/officer_dashboard_screen.dart';

class ServiceMenuGrid extends StatelessWidget {
  const ServiceMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'บริการทางการเงิน',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),

          // ========== 2 Main Services ==========
          Row(
            children: [
              Expanded(
                child: _buildLargeServiceCard(
                  context,
                  icon: LucideIcons.trendingUp,
                  label: 'หุ้นสหกรณ์',
                  subtitle: 'ซื้อ-ขายหุ้น ปันผล',
                  color: const Color(0xFF2563EB), // Deep Blue
                  onTap: () => context.push('/share'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildLargeServiceCard(
                  context,
                  icon: LucideIcons.banknote,
                  label: 'สินเชื่อเงินกู้',
                  subtitle: 'ยื่นกู้ ตรวจสอบสถานะ',
                  color: const Color(0xFF10B981), // Green
                  onTap: () => context.push('/loan'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ========== Other Services ==========
          Text(
            'บริการอื่นๆ',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              _buildSmallMenuItem(context, LucideIcons.heartHandshake, 'สวัสดิการ', Colors.pink),
              _buildSmallMenuItem(context, LucideIcons.barChart3, 'ปันผล', Colors.purple),
              _buildSmallMenuItem(context, LucideIcons.fileText, 'เอกสาร', Colors.blueGrey),
              _buildSmallMenuItem(context, LucideIcons.headphones, 'ช่วยเหลือ', Colors.teal),
              // Show approval menu only for officers
              if (CurrentUser.isOfficerOrApprover)
                _buildSmallMenuItem(context, LucideIcons.fileCheck, 'อนุมัติ', AppColors.primary, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerDashboardScreen()));
                }),
            ],
          ),
        ],
      ),
    );
  }

  /// Large card for main services (หุ้น, สินเชื่อ)
  Widget _buildLargeServiceCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
             borderRadius: BorderRadius.circular(20),
             border: Border.all(color: color.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              // Label
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small icon-style menu for secondary services
  Widget _buildSmallMenuItem(BuildContext context, IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
