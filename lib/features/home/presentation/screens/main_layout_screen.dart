import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/token_provider.dart';

class MainLayoutScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      floatingActionButton: Container(
        height: 72, 
        width: 72,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.secondary, AppColors.primary],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            context.push('/scan');
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(LucideIcons.scanLine, color: Colors.white, size: 32),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 10,
        height: 70,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left Button: Account Book
            Expanded(
              child: _buildBottomBarItem(
                context,
                ref,
                index: 0,
                icon: LucideIcons.book,
                label: 'สมุดบัญชี',
              ),
            ),
            // Middle Spacer for FAB
            const SizedBox(width: 80),
            // Right Button: iLife (Home)
            Expanded(
              child: _buildBottomBarItem(
                context,
                ref,
                index: 1,
                icon: LucideIcons.layoutGrid,
                label: 'iLife',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBarItem(BuildContext context, WidgetRef ref, {
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final color = isSelected ? AppColors.primary : Colors.grey;

    return InkWell(
      onTap: () async {
        if (index == 1) {
          // ใช้ token จาก provider แทน Firebase token
          final storedToken = ref.read(tokenProvider);
          final token = storedToken ?? 'XXXX'; // ถ้าไม่มี token ใช้ค่า default

          try {
            final url = Uri.parse(
                'https://care.ilife.co.th/cus/page1?lang=th&token=$token');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          } catch (e) {
            debugPrint('Error launching iLife URL: $e');
          }
        } else {
          navigationShell.goBranch(index);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
