import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'save_web_stub.dart' if (dart.library.html) 'save_web_web.dart';

class QrSaveService {
  /// Saves QR code image bytes to the gallery (or downloads it on web)
  static Future<bool> saveQrToGallery(Uint8List imageBytes, String filename) async {
    try {
      if (kIsWeb) {
        // Use the helper for web download
        await saveWebBlob(imageBytes, filename);
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

        // 2. Save image directly using bytes to the 'Coop' album
        await Gal.putImageBytes(
          imageBytes, 
          name: filename.replaceAll('.png', ''),
          album: "Coop",
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('Error saving QR: $e');
      return false;
    }
  }
}
