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
      final Uint8List imageBytes = await _captureSlip(slipInfo);

      if (kIsWeb) {
        // Use the helper for web logic to avoid direct dart:html import
        await saveWebBlob(imageBytes, "slip_${slipInfo['transaction_ref'] ?? 'txn'}.png");
        return true;
      } else {
        // Handle mobile saving using gal
        
        // 1. Check/Request permission
        final hasPermission = await Gal.hasAccess();
        if (!hasPermission) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            return false;
          }
        }

        // 2. Save image directly using bytes to a specific album
        // Specifying an album name (e.g., 'Coop') helps the system index it correctly
        // and makes it easier for the user to find in their Gallery/Photos app.
        await Gal.putImageBytes(
          imageBytes, 
          name: "slip_${slipInfo['transaction_ref'] ?? 'txn'}",
          album: "Coop",
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error saving slip: $e');
      return false;
    }
  }
}
