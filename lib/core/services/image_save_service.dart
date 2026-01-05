import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'native_bridge_service.dart';
import 'image_save_error.dart';

class ImageSaveService {
  /// Saves an image from a URL.
  /// On Mobile: Downloads the image and saves it to the gallery using 'gal'.
  /// On Web: Calls the native bridge to let the hybrid shell handle the download.
  /// 
  /// Throws [ImageSaveException] with specific error type if saving fails.
  static Future<void> saveImageFromUrl(String url, {String? filename}) async {
    try {
      if (kIsWeb) {
        debugPrint('ImageSaveService: Calling native bridge for URL: $url');
        await NativeBridgeService.callNativeDownload(url);
      } else {
        // For Mobile, we can still use our Native Bridge (Method Channel)
        // by first downloading the bytes or passing the URL if the bridge supports it.
        // But our bridge currently expects Data URL/Base64.
        // So let's download bytes first.
        debugPrint('ImageSaveService: Downloading image for mobile: $url');
        
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await saveImageFromBytes(response.bodyBytes, filename ?? 'image.png');
        } else {
          throw ImageSaveException(
            ImageSaveError.networkError,
            'ไม่สามารถดาวน์โหลดรูปภาพได้ (HTTP ${response.statusCode})',
          );
        }
      }
    } on SocketException catch (e) {
      debugPrint('ImageSaveService: Network error: $e');
      throw ImageSaveException(
        ImageSaveError.networkError,
        'ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้',
      );
    } on HttpException catch (e) {
      debugPrint('ImageSaveService: HTTP error: $e');
      throw ImageSaveException(
        ImageSaveError.networkError,
        'เกิดข้อผิดพลาดในการดาวน์โหลด',
      );
    } on FileSystemException catch (e) {
      debugPrint('ImageSaveService: File system error: $e');
      throw ImageSaveException(
        ImageSaveError.fileSystemError,
        'พื้นที่จัดเก็บไม่เพียงพอหรือไม่สามารถเขียนไฟล์ได้',
      );
    } catch (e) {
      debugPrint('ImageSaveService error: $e');
      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || 
          errorStr.contains('denied') ||
          errorStr.contains('authorized')) {
        throw ImageSaveException(
          ImageSaveError.permissionDenied,
          'ไม่ได้รับอนุญาตให้เข้าถึงอัลบั้มรูป',
        );
      }
      throw ImageSaveException(
        ImageSaveError.unknownError,
        e.toString(),
      );
    }
  }

  /// Saves an image from Uint8List bytes.
  /// Uses the unified NativeBridgeService (Method Channel on Mobile, JS Bridge on Web).
  /// 
  /// Throws [ImageSaveException] with specific error type if saving fails.
  static Future<void> saveImageFromBytes(Uint8List bytes, String filename) async {
    try {
      // Convert bytes to base64 Data URL for the bridge
      final String base64Data = base64Encode(bytes);
      final String dataUrl = 'data:image/png;base64,$base64Data';
      
      debugPrint('ImageSaveService: Saving image via NativeBridge (length: ${dataUrl.length})');
      await NativeBridgeService.callNativeDownload(dataUrl);
    } on FileSystemException catch (e) {
      debugPrint('ImageSaveService (bytes) file system error: $e');
      throw ImageSaveException(
        ImageSaveError.fileSystemError,
        'พื้นที่จัดเก็บไม่เพียงพอหรือไม่สามารถเขียนไฟล์ได้',
      );
    } catch (e) {
      debugPrint('ImageSaveService (bytes) error: $e');
      // Check if it's a permission error
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('permission') || 
          errorStr.contains('denied') ||
          errorStr.contains('authorized')) {
        throw ImageSaveException(
          ImageSaveError.permissionDenied,
          'ไม่ได้รับอนุญาตให้เข้าถึงอัลบั้มรูป',
        );
      }
      throw ImageSaveException(
        ImageSaveError.unknownError,
        e.toString(),
      );
    }
  }
}
