import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../presentation/widgets/slip_widget.dart';
import 'save_web_stub.dart' if (dart.library.html) 'save_web_web.dart';

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

  /// Saves the slip to the gallery (or downloads it on web)
  static Future<bool> saveSlipToGallery(BuildContext context, Map<String, dynamic> slipInfo) async {
    try {
      print('📸 [SlipService] Starting save process...');
      print('📸 [SlipService] kIsWeb: $kIsWeb');
      
      final Uint8List imageBytes = await _captureSlip(slipInfo);
      print('📸 [SlipService] Image captured, size: ${imageBytes.length} bytes');

      if (kIsWeb) {
        print('🌐 [SlipService] Web platform - downloading...');
        await saveWebBlob(imageBytes, "slip_${slipInfo['transaction_ref'] ?? 'txn'}.png");
        return true;
      } else {
        print('📱 [SlipService] Mobile platform - saving to gallery...');
        
        // 1. Check/Request permission
        print('📱 [SlipService] Checking permission...');
        final hasPermission = await Gal.hasAccess();
        print('📱 [SlipService] Has permission: $hasPermission');
        
        if (!hasPermission) {
          print('📱 [SlipService] Requesting permission...');
          final granted = await Gal.requestAccess();
          print('📱 [SlipService] Permission granted: $granted');
          
          if (!granted) {
            print('❌ [SlipService] Permission denied by user');
            return false;
          }
        }

        // 2. Save image directly using bytes to a specific album
        final filename = "slip_${slipInfo['transaction_ref'] ?? 'txn'}";
        print('📱 [SlipService] Saving to Coop album with name: $filename');
        
        await Gal.putImageBytes(
          imageBytes, 
          name: filename,
          album: "Coop",
        );
        
        print('✅ [SlipService] Save completed successfully');
        return true;
      }
    } catch (e, stack) {
      print('❌ [SlipService] Error saving slip: $e');
      print('❌ [SlipService] Stack trace: $stack');
      debugPrint('Error saving slip: $e');
      return false;
    }
  }
}
