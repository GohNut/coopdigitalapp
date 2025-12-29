import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/image_save_service.dart';
import '../presentation/widgets/slip_widget.dart';

class SlipService {
  static final ScreenshotController screenshotController = ScreenshotController();

  /// Captures the SlipWidget as a byte array
  static Future<Uint8List> _captureSlip(Map<String, dynamic> slipInfo) async {
    return await screenshotController.captureFromWidget(
      Material(
        child: SlipWidget(slipInfo: slipInfo),
      ),
      delay: const Duration(milliseconds: 100),
      context: null, // No context needed for captureFromWidget
    );
  }

  /// Saves the slip to the gallery (or downloads it via bridge on web)
  static Future<bool> saveSlipToGallery(BuildContext context, Map<String, dynamic> slipInfo) async {
    try {
      if (kIsWeb) {
        // Option A: Call Backend for Slip Image URL
        debugPrint('SlipService: Requesting backend slip generation...');
        try {
          final requestBody = {'slip_info': slipInfo};
          debugPrint('SlipService: Sending to backend: ${jsonEncode(requestBody)}');
          
          final response = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/slip/generate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          );

          debugPrint('SlipService: Backend response status: ${response.statusCode}');
          debugPrint('SlipService: Backend response body: ${response.body}');

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final String? slipUrl = data['url'];
            if (slipUrl != null) {
              debugPrint('SlipService: Backend generated URL: $slipUrl');
              return await ImageSaveService.saveImageFromUrl(slipUrl);
            }
          }
          debugPrint('SlipService: Backend generation failed (${response.statusCode}), falling back to bytes bridge');
        } catch (e) {
          debugPrint('SlipService: Backend error: $e, falling back to bytes bridge');
        }
      }

      // Option B & Fallback: Capture locally and send bytes to bridge/save
      final Uint8List imageBytes = await _captureSlip(slipInfo);
      final String filename = "slip_${slipInfo['transaction_ref'] ?? 'txn'}.png";

      // Use the unified ImageSaveService
      return await ImageSaveService.saveImageFromBytes(imageBytes, filename);
    } catch (e) {
      debugPrint('Error saving slip: $e');
      return false;
    }
  }
}
