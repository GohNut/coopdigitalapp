import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/payment_service.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  // Mock Scanner UI

  void _onQrFound(String code) async {
    try {
      final merchant = await paymentServiceProvider.resolveQr(code);
      if (mounted) {
        context.push('/payment/input', extra: merchant);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('QR Code ไม่ถูกต้อง: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Mock Camera Preview
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 4),
                borderRadius: BorderRadius.circular(24)
              ),
              width: 300,
              height: 300,
              child: const Center(
                child: Text('Simulating Camera...', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
          
          // Overlay UI
          SafeArea(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: () => context.pop(),
                    ),
                    const Text('สแกน QR Code', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.flash_on, color: Colors.white),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 50),
                const Text(
                   'วาง QR Code ในกรอบเพื่อสแกน',
                   style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                // Debug / Simulate Button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () => _onQrFound('mock-qr-data'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                    child: const Text('จำลองการสแกนสำเร็จ'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
