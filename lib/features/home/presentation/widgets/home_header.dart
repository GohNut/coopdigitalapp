import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../auth/domain/user_role.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../providers/profile_image_provider.dart';
import '../../../../core/providers/token_provider.dart';
import '../../../../core/utils/external_navigation.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);
    // Watch profile image URL changes - use provider value or fallback to CurrentUser
    final providerImageUrl = ref.watch(profileImageUrlProvider);
    final profileImageUrl = providerImageUrl ?? CurrentUser.profileImageUrl;
    final topPadding = MediaQuery.of(context).padding.top;
    
    return Container(
      padding: EdgeInsets.only(top: topPadding + 16, left: 24, right: 24, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: profileImageUrl != null && profileImageUrl.isNotEmpty
                      ? CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage(profileImageUrl),
                          backgroundColor: Colors.white,
                          onBackgroundImageError: (_, __) {},
                        )
                      : const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(LucideIcons.user, color: AppColors.primary, size: 24),
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'สวัสดี 👋',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CurrentUser.name,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (CurrentUser.kycStatus == 'verified') ...[
                          const SizedBox(width: 6),
                          const Icon(LucideIcons.badgeCheck, color: Colors.green, size: 20),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              // ปุ่มกลับไป iLife App (ถ้ามี Token)
              if (ref.watch(tokenProvider) != null) ...[
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => ExternalNavigation.backToILife(),
                    icon: const Icon(LucideIcons.arrowLeftCircle, color: AppColors.primary),
                    tooltip: 'กลับไป iLife',
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () => _showLogoutConfirmation(context, ref),
                  icon: const Icon(LucideIcons.logOut, color: AppColors.error),
                  tooltip: 'ออกจากระบบ',
                ),
              ),
              const SizedBox(width: 8),
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(LucideIcons.bell, color: AppColors.textSecondary),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: unreadCount > 0 
                      ? Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        )
                      : const SizedBox.shrink(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text('คุณต้องการออกจากระบบใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Logout Logic
              ref.invalidate(depositAccountsAsyncProvider);
              ref.invalidate(totalDepositBalanceAsyncProvider);
              ref.read(tokenProvider.notifier).clearToken(); // Clear token provider
              CurrentUser.setUser(
                newName: '',
                newId: '',
                newRole: UserRole.member,
                newIsMember: false,
              );
              context.go('/login');
            },
            child: const Text('ยืนยัน', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
