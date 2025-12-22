import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/kyc_provider.dart';

class KYCStep3SelfieScreen extends ConsumerStatefulWidget {
  const KYCStep3SelfieScreen({super.key});

  @override
  ConsumerState<KYCStep3SelfieScreen> createState() => _KYCStep3SelfieScreenState();
}

class _KYCStep3SelfieScreenState extends ConsumerState<KYCStep3SelfieScreen> {
  XFile? _capturedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;

  Future<void> _takePicture() async {
    if (_isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front, // ใช้กล้องหน้า
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _capturedImage = image;
          _imageBytes = bytes;
          _isProcessing = false;
        });
      } else {
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      debugPrint('Error capturing image: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ไม่สามารถเปิดกล้องได้: $e')),
        );
      }
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _imageBytes = null;
    });
  }

  void _nextStep() {
    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาถ่ายรูปคู่บัตรประชาชน')),
      );
      return;
    }
    
    // Save to Provider
    ref.read(kycProvider.notifier).setSelfieImage(_capturedImage!);
    
    context.push('/kyc/review');
  }

  void _showSampleImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ตัวอย่างภาพที่ถูกต้อง'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.user, size: 48, color: Colors.grey[600]),
                  const SizedBox(height: 8),
                  Text('ใบหน้า + บัตรประชาชน', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '• เห็นใบหน้าชัดเจน\n• ถือบัตรประชาชนให้อ่านข้อความได้\n• ไม่สวมหมวกหรือแว่นตาดำ',
              style: TextStyle(height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('ตกลง')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ถ่ายรูปคู่บัตรประชาชน'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _showSampleImage,
            icon: const Icon(LucideIcons.info, color: Colors.white, size: 16),
            label: const Text('ดูตัวอย่าง', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: const Row(
                children: [
                  Icon(LucideIcons.alertCircle, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ถ่ายรูป Selfie พร้อมถือบัตรประชาชน\nให้เห็นใบหน้าและข้อมูลบนบัตรชัดเจน',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Image Preview or Capture Button
            const Text('รูปถ่ายคู่บัตรประชาชน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            
            GestureDetector(
              onTap: _capturedImage == null ? _takePicture : null,
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  border: Border.all(color: _capturedImage != null ? AppColors.primary : Colors.grey, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : _imageBytes != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                                      SizedBox(width: 4),
                                      Text('พร้อมใช้งาน', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Face + Card Icons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(LucideIcons.user, size: 32, color: AppColors.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Icon(LucideIcons.plus, color: Colors.grey[400]),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(LucideIcons.creditCard, size: 32, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(LucideIcons.camera, size: 32, color: AppColors.primary),
                              ),
                              const SizedBox(height: 12),
                              Text('แตะเพื่อถ่ายรูป', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                            ],
                          ),
              ),
            ),
            
            if (_capturedImage != null)
              Center(
                child: TextButton.icon(
                  onPressed: _retake,
                  icon: const Icon(LucideIcons.refreshCcw),
                  label: const Text('ถ่ายใหม่'),
                ),
              ),

            const SizedBox(height: 24),
            
            // Tips
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ข้อควรระวัง', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildTip(LucideIcons.eye, 'เห็นใบหน้าชัดเจน ไม่มีสิ่งบดบัง'),
                  _buildTip(LucideIcons.creditCard, 'ถือบัตรให้อ่านข้อมูลได้'),
                  _buildTip(LucideIcons.sun, 'ถ่ายในที่มีแสงสว่างเพียงพอ'),
                  _buildTip(LucideIcons.xCircle, 'ไม่สวมหมวกหรือแว่นตาดำ'),
                ],
              ),
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _capturedImage != null ? _nextStep : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey[300],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('ถัดไป', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[600]))),
        ],
      ),
    );
  }
}
