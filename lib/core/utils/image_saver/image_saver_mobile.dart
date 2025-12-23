import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'image_saver.dart';

class MobileImageSaver implements ImageSaver {
  @override
  Future<void> saveImage(Uint8List bytes, String fileName) async {
    try {
      await Gal.putImageBytes(bytes, name: fileName);
    } catch (e) {
      throw Exception('Error saving image: $e');
    }
  }
}

ImageSaver getImageSaverImpl() => MobileImageSaver();
