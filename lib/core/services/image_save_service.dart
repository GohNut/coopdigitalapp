import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:gal/gal.dart';
import 'native_bridge_service.dart';

class ImageSaveService {
  /// Saves an image from a URL.
  /// On Mobile: Downloads the image and saves it to the gallery using 'gal'.
  /// On Web: Calls the native bridge to let the hybrid shell handle the download.
  static Future<bool> saveImageFromUrl(String url, {String? filename}) async {
    try {
      if (kIsWeb) {
        // For Flutter Web, use the Native Bridge JS function provided by the main app
        debugPrint('ImageSaveService: Calling native bridge for URL: $url');
        await NativeBridgeService.callNativeDownload(url);
        return true;
      } else {
        // For Flutter Mobile, download bytes and save via Gal
        debugPrint('ImageSaveService: Downloading image for mobile: $url');
        
        // 1. Check permissions
        final hasAccess = await Gal.hasAccess();
        if (!hasAccess) {
          final granted = await Gal.requestAccess();
          if (!granted) {
            debugPrint('ImageSaveService: Permission denied');
            return false;
          }
        }

        // 2. Fetch image bytes
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final Uint8List bytes = response.bodyBytes;
          
          // 3. Save to gallery
          final name = filename ?? DateTime.now().millisecondsSinceEpoch.toString();
          await Gal.putImageBytes(
            bytes,
            name: name,
            album: 'Coop',
          );
          
          debugPrint('ImageSaveService: Image saved successfully to gallery');
          return true;
        } else {
          debugPrint('ImageSaveService: Failed to download image. Status: ${response.statusCode}');
          return false;
        }
      }
    } catch (e) {
      debugPrint('ImageSaveService error: $e');
      return false;
    }
  }

  /// Saves an image from Uint8List bytes.
  /// On Mobile: Saves directly to the gallery.
  /// On Web: Converts to Data URL (Base64) and calls the native bridge.
  static Future<bool> saveImageFromBytes(Uint8List bytes, String filename) async {
    try {
      if (kIsWeb) {
        // Convert bytes to base64 Data URL for the bridge
        final String base64Data = base64Encode(bytes);
        final String dataUrl = 'data:image/png;base64,$base64Data'; // Assuming PNG for slips/QR
        
        debugPrint('ImageSaveService: Calling native bridge with Data URL (length: ${dataUrl.length})');
        await NativeBridgeService.callNativeDownload(dataUrl);
        return true;
      } else {
        // Check/Request permission
        final hasPermission = await Gal.hasAccess();
        if (!hasPermission) {
          final granted = await Gal.requestAccess();
          if (!granted) return false;
        }

        // Save image directly
        await Gal.putImageBytes(
          bytes,
          name: filename.replaceAll('.png', '').replaceAll('.jpg', ''),
          album: "Coop",
        );
        
        return true;
      }
    } catch (e) {
      debugPrint('ImageSaveService (bytes) error: $e');
      return false;
    }
  }
}
