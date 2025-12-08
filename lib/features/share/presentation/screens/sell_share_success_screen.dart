import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';

class SellShareSuccessScreen extends StatelessWidget {
  const SellShareSuccessScreen({super.key});

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
                 'โอนหุ้นสำเร็จแล้ว',
                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
               ),
               const SizedBox(height: 16),
               
               // Improved SLA Message Highlight
               Container(
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 decoration: BoxDecoration(
                   color: Colors.blue.shade50,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.blue.shade200),
                 ),
                 child: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     const Icon(LucideIcons.clock, size: 20, color: Colors.blue),
                     const SizedBox(width: 8),
                     const Text(
                       'เงินเข้าบัญชีท่านภายใน 2 ชั่วโมง', 
                       style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)
                     ),
                   ],
                 ),
               ),
               
               const SizedBox(height: 48),
               SizedBox(
                 width: double.infinity,
                 height: 56,
                 child: ElevatedButton(
                   onPressed: () => context.go('/share'), // Return to dashboard
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppColors.primary,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     elevation: 0,
                   ),
                   child: const Text('กลับสู่หน้าหลัก', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }
}
