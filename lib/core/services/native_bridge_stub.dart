import 'package:flutter/foundation.dart';

/// Stub implementation for Native Bridge
Future<void> callNativeDownload(String url) async {
  debugPrint('Native bridge call is only available on Web platform: $url');
}
