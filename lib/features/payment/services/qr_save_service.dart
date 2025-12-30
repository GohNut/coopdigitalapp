import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/image_save_service.dart';
import '../../deposit/domain/deposit_account.dart';
import '../presentation/widgets/qr_receive_widget.dart';

class QrSaveService {
  static final ScreenshotController screenshotController = ScreenshotController();
  static String? _lastGeneratedUrl;

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
      if (kIsWeb) {
        debugPrint('QrSaveService: Requesting server-side QR generation...');
        try {
          // Cleanup previous if exists
          await deleteLastGeneratedQr();

          final payload = {
            'name': account.accountName,
            'account_no_masked': account.maskedAccountNumber,
            'qr_payload': "coop://pay?account_id=${account.id}&name=${Uri.encodeComponent(account.accountName)}${amount != null && amount.isNotEmpty ? '&amount=${amount.replaceAll(',', '')}' : ''}",
            'amount': double.tryParse(amount?.replaceAll(',', '') ?? '') ?? 0,
          };

          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/qr/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String? qrUrl = data['url'];
            if (qrUrl != null) {
              _lastGeneratedUrl = qrUrl;
              debugPrint('QrSaveService: Server generated URL: $qrUrl');
              return await ImageSaveService.saveImageFromUrl(qrUrl);
            }
          }
          debugPrint('QrSaveService: Server generation failed, falling back to local capture');
        } catch (e) {
          debugPrint('QrSaveService: Server error: $e');
        }
      }

      final Uint8List imageBytes = await _captureQr(account, amount);
      final String filename = "qr_receive_${account.accountNumber}_${DateTime.now().millisecondsSinceEpoch}.png";
      
      return await ImageSaveService.saveImageFromBytes(imageBytes, filename);
    } catch (e) {
      debugPrint('Error saving QR: $e');
      return false;
    }
  }

  /// Deletes the last generated QR from the server
  static Future<void> deleteLastGeneratedQr() async {
    if (_lastGeneratedUrl == null) return;
    
    try {
      debugPrint('QrSaveService: Deleting last generated QR: $_lastGeneratedUrl');
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/qr/delete'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': _lastGeneratedUrl}),
      );
      _lastGeneratedUrl = null;
    } catch (e) {
      debugPrint('QrSaveService: Failed to delete QR: $e');
    }
  }

  /// Saves QR code image bytes to the gallery (legacy/utility method)
  static Future<bool> saveQrToGallery(Uint8List imageBytes, String filename) async {
    try {
      return await ImageSaveService.saveImageFromBytes(imageBytes, filename);
    } catch (e) {
      debugPrint('Error saving QR bytes: $e');
      return false;
    }
  }
}
