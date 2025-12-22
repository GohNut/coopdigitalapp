import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_colors.dart';

/// แสดง Dialog เมื่อต้องการยืนยันตัวตน KYC
/// 
/// Returns true ถ้าผู้ใช้กด "ยืนยันตัวตน" และถูกนำไปหน้า KYC
/// Returns false ถ้าผู้ใช้กด "ภายหลัง"
Future<bool> showKYCRequiredDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.shieldAlert,
                size: 36,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            const Text(
              'กรุณายืนยันตัวตน',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              'เพื่อความปลอดภัยในการทำธุรกรรม\nกรุณายืนยันตัวตน (KYC) ก่อนดำเนินการ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),

            // Primary Button - ยืนยันตัวตน
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(ctx, true),
                icon: const Icon(LucideIcons.fingerprint, size: 20),
                label: const Text(
                  'ยืนยันตัวตน',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Secondary Button - ภายหลัง
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'ภายหลัง',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  // ถ้าเลือก "ยืนยันตัวตน" -> นำไปหน้า KYC
  if (result == true && context.mounted) {
    context.push('/kyc');
    return true;
  }
  
  return false;
}

/// ตรวจสอบว่า error message เกี่ยวข้องกับ KYC หรือไม่
bool isKYCError(dynamic error) {
  final errorStr = error.toString().toLowerCase();
  return errorStr.contains('kyc') || 
         errorStr.contains('verification required');
}
