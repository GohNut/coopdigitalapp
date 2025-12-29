// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Calls the native download function defined in index.html
Future<void> callNativeDownload(String url) async {
  if (js.context.hasProperty('call_native_download')) {
    js.context.callMethod('call_native_download', [url]);
  } else {
    // Fallback or print error if not running in the hybrid shell
    print('WEB: call_native_download function not found in window context.');
  }
}
