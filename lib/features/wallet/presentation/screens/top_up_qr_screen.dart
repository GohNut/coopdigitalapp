import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/kyc_required_dialog.dart';
import '../../../../core/utils/promptpay_qr_generator.dart';
import '../../domain/top_up_service.dart';
import '../../../deposit/data/deposit_providers.dart';
import '../../../../services/dynamic_deposit_api.dart';



class TopUpQrScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> params; // Changed from amount to params

  const TopUpQrScreen({super.key, required this.params});

  @override
  ConsumerState<TopUpQrScreen> createState() => _TopUpQrScreenState();
}

class _TopUpQrScreenState extends ConsumerState<TopUpQrScreen> {
  Future<Map<String, dynamic>>? _qrFuture;
  Timer? _timer;
  int _timeLeft = 900; // 15 minutes in seconds
  XFile? _slipImage;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final amount = (widget.params['amount'] as num).toDouble();
    _qrFuture = topUpServiceProvider.generateQr(amount);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        // Handle timeout (e.g., show dialog or go back)
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = (_timeLeft / 60).floor();
    final seconds = _timeLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _saveImage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกรูปภาพเรียบร้อยแล้ว')),
    );
  }

  void _copyRef(String refNo) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกรหัสอ้างอิงแล้ว')),
    );
  }

  Future<void> _pickSlipImage() async {
    final picker = ImagePicker();
    
    // Show bottom sheet to choose camera or gallery
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'เลือกรูปสลิป',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.camera, color: AppColors.primary),
                ),
                title: const Text('ถ่ายรูป'),
                subtitle: const Text('ถ่ายรูปสลิปจากกล้อง'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(LucideIcons.image, color: AppColors.success),
                ),
                title: const Text('เลือกจากแกลเลอรี่'),
                subtitle: const Text('เลือกรูปสลิปจากอัลบั้ม'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      try {
        final XFile? image = await picker.pickImage(
          source: source,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (image != null) {
          setState(() {
            _slipImage = image;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    }
  }

  Future<void> _submitDeposit(String refNo) async {
    if (_slipImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาแนบสลิปการโอนเงิน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final amount = (widget.params['amount'] as num).toDouble();
      final accountId = widget.params['accountId'] as String;
      
      // Create pending deposit request using real API
      await DynamicDepositApiService.createDepositRequest(
        accountId: accountId,
        amount: amount,
        slipImagePath: _slipImage!.path,
        referenceNo: refNo,
      );
      
      // Invalidate providers to refresh data
      ref.invalidate(depositAccountsAsyncProvider);
      ref.invalidate(totalDepositBalanceAsyncProvider);
      ref.invalidate(depositTransactionsAsyncProvider(accountId));
      
      if (mounted) {
        // Show success dialog
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.clock,
                    color: AppColors.warning,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'รอดำเนินการ',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'รหัสอ้างอิง: $refNo',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'ส่งสลิปเรียบร้อยแล้ว\nรอเจ้าหน้าที่ตรวจสอบและยืนยันการโอน\nเมื่อยืนยันแล้วเงินจะเข้าบัญชีของท่าน',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/home');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('กลับหน้าหลัก'),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // ตรวจจับ KYC error และแสดง Dialog แทน SnackBar
        if (isKYCError(e)) {
          await showKYCRequiredDialog(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('สแกน QR เพื่อจ่าย', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _qrFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'เกิดข้อผิดพลาด: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final data = snapshot.data!;
            final refNo = data['ref_no'] as String;

            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ฝากเงินเข้ากระเป๋า',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat('#,##0.00').format((widget.params['amount'] as num).toDouble()),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // QR Code จริงจาก PromptPay Generator
                      Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: QrImageView(
                          data: PromptPayQrGenerator.generate(
                            amount: (widget.params['amount'] as num).toDouble(),
                          ),
                          version: QrVersions.auto,
                          size: 218,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ข้อมูลบัญชีธนาคาร
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Column(
                          children: [
                            Text(
                              PromptPayQrGenerator.coopBankName,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              PromptPayQrGenerator.coopAccountName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'เลขที่บัญชี: ${PromptPayQrGenerator.coopAccountNumber}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.clock, size: 16, color: AppColors.warning),
                          const SizedBox(width: 8),
                          Text(
                            'QR Code นี้จะหมดอายุใน $_formattedTime นาที',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('รหัสอ้างอิง', style: TextStyle(color: AppColors.textSecondary)),
                          Row(
                            children: [
                              Text(refNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () => _copyRef(refNo),
                                child: const Icon(LucideIcons.copy, size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // บันทึกรูป Button
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveImage,
                        icon: const Icon(LucideIcons.download),
                        label: const Text('บันทึกรูป'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Slip Attachment Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _slipImage != null ? AppColors.success : Colors.white30,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      if (_slipImage != null) ...[
                        // Show attached slip preview
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: kIsWeb
                                  ? Image.network(
                                      _slipImage!.path,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_slipImage!.path),
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _slipImage = null),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    LucideIcons.x,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'แนบสลิปเรียบร้อยแล้ว',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Button to attach slip
                        ElevatedButton.icon(
                          onPressed: _pickSlipImage,
                          icon: const Icon(LucideIcons.paperclip),
                          label: const Text('แนบสลิปการโอนเงิน'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'กรุณาแนบสลิปหลังจากโอนเงินแล้ว',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : () => _submitDeposit(refNo),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'ตกลง - ส่งสลิปรอตรวจสอบ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(height: 16),
                const Text(
                  'เมื่อส่งสลิปแล้ว รอเจ้าหน้าที่ตรวจสอบและยืนยันการโอน\nเมื่อยืนยันแล้วเงินจะเข้าบัญชีของท่าน',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
