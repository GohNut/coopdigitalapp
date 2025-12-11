import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/home_header.dart';
import '../widgets/quick_actions_grid.dart';
import '../widgets/service_menu_grid.dart';
import '../widgets/wallet_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              child: const WalletCard(),
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
