import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import '../../../../core/services/image_save_service.dart';
import '../../deposit/domain/deposit_account.dart';
import '../presentation/widgets/qr_receive_widget.dart';

class QrSaveService {
  static final ScreenshotController screenshotController = ScreenshotController();

  /// Captures the QrReceiveWidget as a byte array
  static Future<Uint8List> _captureQr(DepositAccount account, String? amount) async {
    return await screenshotController.captureFromWidget(
      Material(
        child: QrReceiveWidget(account: account, amount: amount),
      ),
      delay: const Duration(milliseconds: 100),
      context: null, // No context needed for captureFromWidget
    );
  }

  /// Saves receive QR code to the gallery (or downloads it via bridge on web)
  static Future<bool> saveReceiveQrToGallery(DepositAccount account, String? amount) async {
    try {
      final Uint8List imageBytes = await _captureQr(account, amount);
      final String filename = "qr_receive_${account.accountNumber}_${DateTime.now().millisecondsSinceEpoch}.png";
      
      // Use the unified ImageSaveService
      return await ImageSaveService.saveImageFromBytes(imageBytes, filename);
    } catch (e) {
      debugPrint('Error saving QR: $e');
      return false;
    }
  }

  /// Saves QR code image bytes to the gallery (legacy/utility method)
  static Future<bool> saveQrToGallery(Uint8List imageBytes, String filename) async {
    try {
      // Use the unified ImageSaveService
      return await ImageSaveService.saveImageFromBytes(imageBytes, filename);
    } catch (e) {
      debugPrint('Error saving QR bytes: $e');
      return false;
    }
  }
}
