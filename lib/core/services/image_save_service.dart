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
        debugPrint('ImageSaveService: Calling native bridge for URL: $url');
        await NativeBridgeService.callNativeDownload(url);
        return true;
      } else {
        // For Mobile, we can still use our Native Bridge (Method Channel)
        // by first downloading the bytes or passing the URL if the bridge supports it.
        // But our bridge currently expects Data URL/Base64.
        // So let's download bytes first.
        debugPrint('ImageSaveService: Downloading image for mobile: $url');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return await saveImageFromBytes(response.bodyBytes, filename ?? 'image.png');
        }
        return false;
      }
    } catch (e) {
      debugPrint('ImageSaveService error: $e');
      return false;
    }
  }

  /// Saves an image from Uint8List bytes.
  /// Uses the unified NativeBridgeService (Method Channel on Mobile, JS Bridge on Web).
  static Future<bool> saveImageFromBytes(Uint8List bytes, String filename) async {
    try {
      // Convert bytes to base64 Data URL for the bridge
      final String base64Data = base64Encode(bytes);
      final String dataUrl = 'data:image/png;base64,$base64Data';
      
      debugPrint('ImageSaveService: Saving image via NativeBridge (length: ${dataUrl.length})');
      await NativeBridgeService.callNativeDownload(dataUrl);
      return true;
    } catch (e) {
      debugPrint('ImageSaveService (bytes) error: $e');
      return false;
    }
  }
}
