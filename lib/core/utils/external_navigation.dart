import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ExternalNavigation {
  static const String iLifeBaseUrl = 'https://care.ilife.co.th/cus/page1';

  /// ดึง Token และเปิด URL กลับไปที่ iLife
  static Future<void> backToILife() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('ilife_token') ?? '';
      
      final url = Uri.parse('$iLifeBaseUrl?lang=th&token=$token');
      
      debugPrint('Navigating back to iLife with URL: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      debugPrint('Error navigating back to iLife: $e');
    }
  }
}
