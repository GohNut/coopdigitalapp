import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider สำหรับจัดการ iLife Token
class TokenNotifier extends Notifier<String?> {
  static const String _tokenKey = 'ilife_token';

  @override
  String? build() {
    _loadToken();
    return null;
  }

  /// โหลด token จาก SharedPreferences
  Future<void> _loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      state = token;
    } catch (e) {
      print('Error loading token: $e');
    }
  }

  /// บันทึก token ใหม่
  Future<void> setToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      state = token;
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  /// ลบ token
  Future<void> clearToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      state = null;
    } catch (e) {
      print('Error clearing token: $e');
    }
  }

  /// ดึง token จาก URL (รองรับทั้ง Query, Path, และ Fragment)
  Future<void> extractTokenFromUrl() async {
    try {
      final uri = Uri.base;
      final token = extractTokenFromUri(uri);
      if (token != null && token.isNotEmpty) {
        await setToken(token);
      }
    } catch (e) {
      print('Error extracting token from URL: $e');
    }
  }

  /// Helper สำหรับดึง token จาก Uri อย่างละเอียด
  static String? extractTokenFromUri(Uri uri) {
    // 1. ลองหาจาก Query Parameters มาตรฐาน (?token=xxx)
    if (uri.queryParameters.containsKey('token')) {
      return uri.queryParameters['token'];
    }

    // 2. ลองหาจาก Path (กรณีเช่น /token=xxx)
    final path = uri.path;
    if (path.contains('token=')) {
      final parts = path.split('token=');
      if (parts.length > 1) {
        // ตัดเอาส่วนหลัง token= และหยุดที่ / หรือ ? ตัวถัดไป
        String tokenPart = parts[1];
        if (tokenPart.contains('/')) {
          tokenPart = tokenPart.split('/')[0];
        }
        if (tokenPart.contains('?')) {
          tokenPart = tokenPart.split('?')[0];
        }
        return tokenPart;
      }
    }

    // 3. ลองหาจาก Fragment (ส่วนหลัง # เช่น /#/home?token=xxx)
    final fragment = uri.fragment;
    if (fragment.isNotEmpty) {
      if (fragment.contains('token=')) {
        final parts = fragment.split('token=');
        if (parts.length > 1) {
          String tokenPart = parts[1];
          // ตัดเอาส่วนที่อยู่ก่อน & หรือ / หรือ ?
          final separators = RegExp(r'[&/?]');
          final endIdx = tokenPart.indexOf(separators);
          if (endIdx != -1) {
            tokenPart = tokenPart.substring(0, endIdx);
          }
          return tokenPart;
        }
      }
    }

    return null;
  }
}

/// Provider instance สำหรับเข้าถึง token
final tokenProvider = NotifierProvider<TokenNotifier, String?>(TokenNotifier.new);

