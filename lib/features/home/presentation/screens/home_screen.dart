import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/profile_image_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/service_menu_grid.dart';
import '../widgets/wallet_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<WalletCardState> _walletCardKey = GlobalKey<WalletCardState>();

  @override
  void initState() {
    super.initState();
    // Refresh data when entering this screen (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshAllData();
      }
    });
  }

  void _refreshAllData() {
    // Refresh all deposit-related providers
    ref.invalidate(depositAccountsAsyncProvider);
    ref.invalidate(totalDepositExcludingLoanAsyncProvider);
    ref.invalidate(loanAccountBalanceAsyncProvider);
    
    // Note: We don't invalidate notificationProvider here because it causes
    // LateInitializationError. The notification provider will update itself
    // when new notifications arrive via API.
    
    // Note: Profile image provider doesn't need invalidation as it's updated
    // only when user uploads a new image
    
    // Trigger wallet card to refresh loan and share data
    _walletCardKey.currentState?.refreshAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Column(
              children: [
                const HomeHeader(),
                const QuickActionsGrid(),
              ],
            ),
            Transform.translate(
              offset: const Offset(0, -30),
              child: WalletCard(key: _walletCardKey),
            ),
             Transform.translate(
              offset: const Offset(0, -30),
              child: const ServiceMenuGrid(),
            ),
          ],
        ),
      ),
    );
  }
}
