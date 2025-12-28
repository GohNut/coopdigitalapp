import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/financial_refresh_provider.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../providers/profile_image_provider.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/service_menu_grid.dart';
import '../widgets/wallet_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/utils/responsive_text.dart';
import '../../../../core/utils/responsive_spacing.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<WalletCardState> _walletCardKey = GlobalKey<WalletCardState>();
  late Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
    // Refresh data when entering this screen (after first frame)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshAllData();
      }
    });
  }

  void _refreshAllData() {
    // Use centralized financial refresh provider
    ref.read(financialRefreshProvider.notifier).refreshAll();
    
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
            Padding(
              padding: const EdgeInsets.only(bottom: 100), // เพิ่ม padding เพื่อไม่ให้โดน FAB บัง
              child: FutureBuilder<PackageInfo>(
                future: _packageInfoFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text(
                      'Version ${snapshot.data!.version} (Build ${snapshot.data!.buildNumber})',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12, // ขนาดเท่ากับไอคอนยืนยันตัวตน
                        color: Colors.grey.shade500,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
