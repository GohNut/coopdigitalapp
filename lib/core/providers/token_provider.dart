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
}

/// Provider instance สำหรับเข้าถึง token
final tokenProvider = NotifierProvider<TokenNotifier, String?>(TokenNotifier.new);

