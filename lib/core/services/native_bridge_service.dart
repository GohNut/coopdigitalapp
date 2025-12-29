import 'native_bridge_stub.dart' if (dart.library.js) 'native_bridge_web.dart' as bridge;

abstract class NativeBridgeService {
  /// Calls the native download function (only effective on Web)
  static Future<void> callNativeDownload(String url) async {
    await bridge.callNativeDownload(url);
  }
}
