import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/promptpay_qr_generator.dart';
import '../../../../core/utils/image_saver/image_saver.dart';
import '../../../wallet/domain/top_up_service.dart';

class ShareQrPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> args;

  const ShareQrPaymentScreen({super.key, required this.args});

  @override
  State<ShareQrPaymentScreen> createState() => _ShareQrPaymentScreenState();
}

class _ShareQrPaymentScreenState extends State<ShareQrPaymentScreen> {
  Future<Map<String, dynamic>>? _qrFuture;
  Timer? _timer;
  int _timeLeft = 900; // 15 minutes in seconds
  bool _isSavingImage = false;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final amount = widget.args['netTotal'] as double;
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

  Future<void> _saveImage() async {
    if (_isSavingImage) return;
    
    setState(() => _isSavingImage = true);
    
    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Save to gallery
      final imageSaver = getImageSaver();
      await imageSaver.saveImage(
        pngBytes,
        'share_qr_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ บันทึกรูปภาพเรียบร้อยแล้ว'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingImage = false);
    }
  }

  void _copyRef(String refNo) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('คัดลอกรหัสอ้างอิงแล้ว')),
    );
  }

  void _proceedToConfirmation() {
    // ไปหน้ายืนยัน
    final nextArgs = Map<String, dynamic>.from(widget.args);
    nextArgs['paymentMethod'] = 'qr';
    nextArgs['paymentSourceId'] = '';
    context.push('/share/buy/confirm', extra: nextArgs);
  }

  @override
  Widget build(BuildContext context) {
    final amount = widget.args['netTotal'] as double;
    final units = widget.args['units'] as int;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text('QR ชำระเงินซื้อหุ้น', style: TextStyle(color: Colors.white)),
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
                        'ซื้อหุ้นสหกรณ์',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$units หุ้น',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        NumberFormat('#,##0.00').format(amount),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // QR Code จริงจาก PromptPay Generator
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          width: 250,
                          height: 250,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: PrettyQrView.data(
                            data: PromptPayQrGenerator.generate(amount: amount),
                            decoration: const PrettyQrDecoration(
                              shape: PrettyQrSmoothSymbol(
                                color: Colors.black,
                              ),
                            ),
                          ),
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
                            'QR นี้จะหมดอายุใน $_formattedTime นาที',
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSavingImage ? null : _saveImage,
                        icon: _isSavingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(LucideIcons.download),
                        label: Text(_isSavingImage ? 'กำลังบันทึก...' : 'บันทึกรูป'),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _proceedToConfirmation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('ชำระเงินแล้ว ดำเนินการต่อ', 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'เมื่อโอนเงินเรียบร้อยแล้ว ให้กดปุ่ม "ชำระเงินแล้ว ดำเนินการต่อ" เพื่อยืนยันการซื้อหุ้น',
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
