import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'native_bridge_stub.dart' if (dart.library.js) 'native_bridge_web.dart' as bridge;

abstract class NativeBridgeService {
  static const platform = MethodChannel('com.example.coop_digital_app/native_bridge');

  /// Calls the native download function
  /// On Web: Uses JavaScript bridge
  /// On Android/iOS Mobile: Uses Method Channel  
  static Future<void> callNativeDownload(String url) async {
    debugPrint('NativeBridgeService: callNativeDownload triggered');
    debugPrint('NativeBridgeService: kIsWeb = $kIsWeb, URL length = ${url.length}');
    
    if (kIsWeb) {
      debugPrint('NativeBridgeService: Running in BROWSER/WEB mode');
      await bridge.callNativeDownload(url);
    } else {
      debugPrint('NativeBridgeService: Running in MOBILE/NATIVE mode');
      try {
        debugPrint('NativeBridgeService: Attempting MethodChannel checkStatus...');
        final String status = await platform.invokeMethod('checkStatus');
        debugPrint('NativeBridgeService: Connection Status = $status');
        
        debugPrint('NativeBridgeService: Calling downloadImage...');
        final result = await platform.invokeMethod('downloadImage', {'dataUrl': url});
        debugPrint('NativeBridgeService: SUCCESS! Result = $result');
      } on PlatformException catch (e) {
        debugPrint('NativeBridgeService: FAILED with PlatformException:');
        debugPrint('  - Code: ${e.code}');
        debugPrint('  - Message: ${e.message}');
      } catch (e) {
        debugPrint('NativeBridgeService: UNEXPECTED Error: $e');
      }
    }
  }
}
