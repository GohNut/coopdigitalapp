import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/services/image_save_service.dart';

class QrSaveService {
  /// Saves QR code image bytes to the gallery (or downloads it via bridge on web)
  static Future<bool> saveQrToGallery(Uint8List imageBytes, String filename) async {
    try {
      // Use the unified ImageSaveService
      return await ImageSaveService.saveImageFromBytes(imageBytes, filename);
    } catch (e) {
      debugPrint('Error saving QR: $e');
      return false;
    }
  }
}
