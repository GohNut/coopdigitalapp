import 'dart:typed_data';
import 'dart:html' as html;
import 'image_saver.dart';

class WebImageSaver implements ImageSaver {
  @override
  Future<void> saveImage(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}

ImageSaver getImageSaverImpl() => WebImageSaver();
