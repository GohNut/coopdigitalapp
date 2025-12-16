import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class BuyShareSuccessScreen extends StatelessWidget {
  const BuyShareSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                 padding: const EdgeInsets.all(24),
                 decoration: BoxDecoration(
                   color: Colors.green.shade50,
                   shape: BoxShape.circle,
                 ),
                 child: const Icon(LucideIcons.check, color: Colors.green, size: 64),
               ),
               const SizedBox(height: 32),
               const Text(
                 'สั่งซื้อสำเร็จแล้ว',
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
               ),
               const SizedBox(height: 16),
               const Text(
                 'ระบบได้รับคำสั่งซื้อหุ้นของคุณแล้ว\nรายการจะแสดงในประวัติเร็วๆนี้',
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 16, color: Colors.grey),
               ),
               const SizedBox(height: 48),
               Row(
                 children: [
                   Expanded(
                     child: ElevatedButton(
                       onPressed: () => context.go('/share/buy'),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: AppColors.primary,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                         elevation: 0,
                         padding: const EdgeInsets.symmetric(vertical: 18),
                       ),
                       child: const Text('ซื้อเพิ่ม', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                     ),
                   ),
                   const SizedBox(width: 12),
                   Expanded(
                     child: OutlinedButton(
                       onPressed: () => context.go('/home'),
                       style: OutlinedButton.styleFrom(
                         foregroundColor: AppColors.primary,
                         side: const BorderSide(color: AppColors.primary, width: 2),
                         padding: const EdgeInsets.symmetric(vertical: 18),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                       child: const Text('กลับหน้าหลัก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     ),
                   ),
                 ],
               ),
            ],
          ),
        ),
      ),
    );
  }
}
