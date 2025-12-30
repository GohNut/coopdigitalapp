import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'native_bridge_stub.dart' if (dart.library.js) 'native_bridge_web.dart' as bridge;

abstract class NativeBridgeService {
  static const platform = MethodChannel('com.example.coop_digital_app/native_bridge');

  /// Calls the native download function
  /// On Web: Uses JavaScript bridge
  /// On Android/iOS Mobile: Uses Method Channel  
  static Future<void> callNativeDownload(String url) async {
    if (kIsWeb) {
      // For Web, use existing JavaScript bridge
      await bridge.callNativeDownload(url);
    } else {
      // For Mobile (Android/iOS), use Method Channel
      try {
        await platform.invokeMethod('downloadImage', {'dataUrl': url});
        debugPrint('NativeBridgeService: Image download requested via Method Channel');
      } on PlatformException catch (e) {
        debugPrint('NativeBridgeService: Failed to download image: ${e.message}');
      }
    }
  }
}
