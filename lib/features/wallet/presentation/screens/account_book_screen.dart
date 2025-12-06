import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AccountBookScreen extends StatelessWidget {
  const AccountBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สมุดบัญชี'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.book, size: 64, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'สมุดบัญชีของคุณ',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('แสดงรายการบัญชีเงินฝากทั้งหมด'),
          ],
        ),
      ),
    );
  }
}
