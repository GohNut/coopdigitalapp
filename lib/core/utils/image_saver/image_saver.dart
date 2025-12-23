import 'dart:typed_data';
import 'image_saver_mobile.dart' if (dart.library.html) 'image_saver_web.dart';

abstract class ImageSaver {
  Future<void> saveImage(Uint8List bytes, String fileName);
}

ImageSaver getImageSaver() => getImageSaverImpl();
