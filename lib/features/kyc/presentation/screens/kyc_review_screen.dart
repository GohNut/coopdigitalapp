import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/kyc_provider.dart';
import '../../data/kyc_service.dart';
import '../../../notification/domain/notification_model.dart';
import '../../../notification/presentation/providers/notification_provider.dart';
import '../../../../core/utils/notification_helper.dart';
import '../../../auth/domain/user_role.dart';

class KYCReviewScreen extends ConsumerStatefulWidget {
  const KYCReviewScreen({super.key});

  @override
  ConsumerState<KYCReviewScreen> createState() => _KYCReviewScreenState();
}

class _KYCReviewScreenState extends ConsumerState<KYCReviewScreen> {
  bool _isSubmitting = false;
  bool _isLoading = true;
  
  // Store image bytes for display
  Uint8List? _idCardBytes;
  Uint8List? _bankBookBytes;
  Uint8List? _selfieBytes;
  
  // Bank data from JSON
  Map<String, dynamic> _banksData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final state = ref.read(kycProvider);
    
    try {
      // Load images
      if (state.idCardImage != null) {
        _idCardBytes = await state.idCardImage!.readAsBytes();
      }
      if (state.bankBookImage != null) {
        _bankBookBytes = await state.bankBookImage!.readAsBytes();
      }
      if (state.selfieImage != null) {
        _selfieBytes = await state.selfieImage!.readAsBytes();
      }
      
      // Load bank data from JSON
      final jsonString = await rootBundle.loadString('assets/bank_logos/banks-logo.json');
      _banksData = json.decode(jsonString);
    } catch (e) {
      debugPrint('Error loading data: $e');
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  String _getBankName(String? bankId) {
    if (bankId == null) return '-';
    if (_banksData.containsKey(bankId)) {
      return _banksData[bankId]['name'] ?? bankId;
    }
    return bankId;
  }

  Future<void> _submit() async {
    final state = ref.read(kycProvider);
    if (state.idCardImage == null || state.bankBookImage == null || state.selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อมูลไม่ครบถ้วน กรุณาถ่ายรูปให้ครบทุกขั้นตอน')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await KYCService.submitKYC(
        idCardImage: state.idCardImage!,
        bankBookImage: state.bankBookImage!,
        selfieImage: state.selfieImage!,
        bankId: state.bankId!,
        bankAccountNo: state.bankAccountNo!,
      );

      if (mounted) {
        // Clear state
        ref.read(kycProvider.notifier).reset();

        // Add persistent notification
        ref.read(notificationProvider.notifier).addNotification(
          NotificationModel.now(
            title: 'ส่งคำขอยืนยันตัวตนแล้ว',
            message: 'การส่งเรื่องยืนยันตัวตนสำเร็จแล้ว อยู่ในสถานะรอการยืนยันจากเจ้าหน้าที่',
            type: NotificationType.warning,
          ),
        );

        // Send notification to officers (Step 2)
        NotificationHelper.notifyOfficers(
          ref: ref,
          title: 'มีคำขอยืนยันตัวตนใหม่ (KYC)',
          message: 'สมาชิก ${CurrentUser.name} ได้ส่งคำขอยืนยันตัวตนใหม่ กรุณาตรวจสอบและอนุมัติ',
          type: 'info',
          route: '/officer/kyc-detail/${CurrentUser.id}',
        );
        
        // Navigate to Success
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('ส่งข้อมูลเรียบร้อย'),
              ],
            ),
            content: const Text('เจ้าหน้าที่จะทำการตรวจสอบข้อมูลภายใน 1-2 วันทำการ คุณจะได้รับการแจ้งเตือนเมื่อการตรวจสอบเสร็จสิ้น'),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop(); // Close dialog
                  context.go('/home'); // Go home
                },
                child: const Text('ตกลง'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kycProvider);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ตรวจสอบข้อมูล'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตรวจสอบข้อมูล'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. บัตรประชาชน'),
            if (_idCardBytes != null)
              _buildImagePreview(_idCardBytes!, 'บัตรประชาชน'),
            
            const SizedBox(height: 24),
            _buildSectionHeader('2. ข้อมูลบัญชีธนาคาร'),
            
            // Bank info with logo
            if (state.bankId != null)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/bank_logos/${state.bankId}.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.account_balance, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getBankName(state.bankId),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'เลขบัญชี: ${state.bankAccountNo ?? '-'}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            if (_bankBookBytes != null)
              _buildImagePreview(_bankBookBytes!, 'สมุดบัญชี'),

            const SizedBox(height: 24),
            _buildSectionHeader('3. รูปถ่ายคู่บัตร (Selfie)'),
            if (_selfieBytes != null)
              _buildImagePreview(_selfieBytes!, 'Selfie'),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('ยืนยันและส่งข้อมูล', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
    );
  }

  Widget _buildImagePreview(Uint8List bytes, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          Image.memory(
            bytes,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(8),
              child: Text(label, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
            ),
          ),
        ],
      ),
    );
  }
}
