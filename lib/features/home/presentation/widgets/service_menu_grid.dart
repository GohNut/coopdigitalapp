import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class ServiceMenuGrid extends StatelessWidget {
  const ServiceMenuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'บริการทางการเงิน',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _buildMenuItem(context, LucideIcons.trendingUp, 'หุ้น', AppColors.info),
              _buildMenuItem(context, LucideIcons.piggyBank, 'เงินฝาก', AppColors.success),
              _buildMenuItem(context, LucideIcons.wallet, 'กระเป๋าเงิน', AppColors.warning),
              _buildMenuItem(context, LucideIcons.coins, 'สินเชื่อ', AppColors.error),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'บริการอื่นๆ',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
           const SizedBox(height: 16),
           GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _buildMenuItem(context, LucideIcons.heartHandshake, 'สวัสดิการ', Colors.pink),
              _buildMenuItem(context, LucideIcons.barChart3, 'ปันผล', Colors.purple),
              _buildMenuItem(context, LucideIcons.fileText, 'เอกสาร', Colors.blueGrey),
              _buildMenuItem(context, LucideIcons.headphones, 'ช่วยเหลือ', Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String label, Color color) {
    return InkWell(
      onTap: () {
        if (label == 'สินเชื่อ') {
          context.push('/loan');
        }
      },
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
          const SizedBox(height: 6),
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
