import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/kyc/presentation/providers/kyc_provider.dart';
import '../../../../core/theme/app_colors.dart';

class KYCIntroScreen extends ConsumerStatefulWidget {
  const KYCIntroScreen({super.key});

  @override
  ConsumerState<KYCIntroScreen> createState() => _KYCIntroScreenState();
}

class _KYCIntroScreenState extends ConsumerState<KYCIntroScreen> {
  @override
  void initState() {
    super.initState();
    // Load current status when entering the screen
    Future.microtask(() => ref.read(kycProvider.notifier).loadKYCStatus());
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);
    final status = kycState.kycStatus;
    final isPending = status == 'pending';
    final isVerified = status == 'verified' || status == 'approved';
    final isRejected = status == 'rejected';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันตัวตน (KYC)'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Spacer(),
            // Icon or Illustration
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isVerified 
                    ? AppColors.primary.withOpacity(0.1) 
                    : isPending 
                        ? Colors.grey.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVerified 
                    ? LucideIcons.badgeCheck 
                    : isPending 
                        ? LucideIcons.checkCircle 
                        : LucideIcons.shieldCheck, 
                size: 80, 
                color: isVerified 
                    ? AppColors.primary 
                    : isPending 
                        ? Colors.grey 
                        : AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'ยืนยันตัวตนเพื่อความปลอดภัย',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (isRejected && kycState.rejectReason != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertCircle, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'ถูกปฏิเสธ: ${kycState.rejectReason}',
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              isPending 
                  ? 'กำลังรอการตรวจสอบ' 
                  : isVerified 
                      ? 'ยืนยันตัวตนสำเร็จแล้ว' 
                      : 'กรุณาเตรียมบัตรประชาชนและสมุดบัญชีธนาคารของคุณให้พร้อม เพื่อใช้ในการยืนยันตัวตน',
              style: TextStyle(
                fontSize: 16, 
                color: isPending || isVerified ? AppColors.primary : Colors.grey,
                fontWeight: isPending || isVerified ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            _buildStep(context, '1', 'ถ่ายรูปบัตรประชาชน', 'ตรวจสอบข้อมูลบัตรประชาชน', isVerified || isPending),
             _buildStep(context, '2', 'ถ่ายรูปหน้าสมุดบัญชี', 'ระบุบัญชีสำหรับรับเงินปันผล', isVerified || isPending),
             _buildStep(context, '3', 'ถ่ายรูปคู่กับบัตร', 'ยืนยันว่าเป็นเจ้าของบัตรจริง', isVerified || isPending),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (isPending || isVerified) 
                    ? null 
                    : () {
                        context.push('/kyc/step1');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (isPending || isVerified) ? Colors.grey : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isPending 
                      ? 'อยู่ระหว่างการตรวจสอบ' 
                      : isVerified 
                          ? 'ยืนยันตัวตนเรียบร้อยแล้ว' 
                          : 'เริ่มการยืนยันตัวตน', 
                  style: const TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String number, String title, String subtitle, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.grey : AppColors.secondary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isCompleted 
                ? const Icon(LucideIcons.check, color: Colors.white, size: 20)
                : Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: isCompleted ? Colors.grey : Colors.black,
                  ),
                ),
                Text(
                  subtitle, 
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
