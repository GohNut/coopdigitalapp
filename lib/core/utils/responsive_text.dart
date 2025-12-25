import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// ระบบฟอนต์ตอบสนองที่ล็อคการซูม
/// ปรับขนาดตามขนาดหน้าจอ แต่ไม่ตอบสนองต่อ textScaleFactor ของระบบ
class ResponsiveText {
  /// ขนาดฟอนต์มาตรฐาน (ไม่ตอบสนองต่อระบบซูม)
  static const double _baseFontSize = 16.0;
  
  /// คำนวณขนาดฟอนต์ที่ตอบสนอง (ไม่รวม textScaleFactor)
  static double getFontSize(BuildContext context, double baseSize) {
    final scaleFactor = ResponsiveUtils.getScaleFactor(context);
    return baseSize * scaleFactor;
  }

  /// ฟอนต์สำหรับหัวข้อใหญ่ (Display)
  static TextStyle displayLarge(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 28), // เดิม 32 -> 28 (ลดลงเล็กนิด)
      fontWeight: FontWeight.bold,
      color: const Color(0xFF212121),
      height: 1.2,
    );
  }

  /// ฟอนต์สำหรับหัวข้อกลาง (Headline)
  static TextStyle headlineMedium(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 18), // เดิม 20 -> 18
      fontWeight: FontWeight.w600,
      color: const Color(0xFF212121),
      height: 1.3,
    );
  }

  /// ฟอนต์สำหรับข้อความปกติ (Body Large)
  static TextStyle bodyLarge(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 16), // คงเดิม
      fontWeight: FontWeight.normal,
      color: const Color(0xFF212121),
      height: 1.4,
    );
  }

  /// ฟอนต์สำหรับข้อความรอง (Body Medium)
  static TextStyle bodyMedium(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 14), // คงเดิม
      fontWeight: FontWeight.normal,
      color: const Color(0xFF757575),
      height: 1.4,
    );
  }

  /// ฟอนต์สำหรับป้ายกำกับ (Label)
  static TextStyle labelLarge(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 14),
      fontWeight: FontWeight.w500,
      color: const Color(0xFF757575),
      height: 1.2,
    );
  }

  /// ฟอนต์สำหรับปุ่ม (Button)
  static TextStyle buttonText(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 16),
      fontWeight: FontWeight.w600,
      color: Colors.white,
      height: 1.2,
    );
  }

  /// ฟอนต์สำหรับเล็กๆ (Caption)
  static TextStyle caption(BuildContext context) {
    return TextStyle(
      fontSize: getFontSize(context, 12),
      fontWeight: FontWeight.normal,
      color: const Color(0xFF9E9E9E),
      height: 1.3,
    );
  }

  /// สร้าง TextStyle แบบกำหนดเอง
  static TextStyle custom(
    BuildContext context, 
    double baseSize, {
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) {
    return TextStyle(
      fontSize: getFontSize(context, baseSize),
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }
}

/// Widget Text ที่ตอบสนอง (ล็อคการซูม)
class ResponsiveTextWidget extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveTextWidget({
    super.key,
    required this.text,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    // รวม style กับ responsive style
    final responsiveStyle = style ?? ResponsiveText.bodyLarge(context);
    
    return Text(
      text,
      style: responsiveStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      // ล็อค textScaleFactor เพื่อไม่ให้ตอบสนองต่อการตั้งค่าการเข้าถึง
      textScaleFactor: 1.0,
    );
  }
}

/// Extension สำหรับ BuildContext เพื่อใช้งานฟอนต์ง่าย
extension ResponsiveTextExtensions on BuildContext {
  /// ฟอนต์หัวข้อใหญ่
  TextStyle get displayLargeText => ResponsiveText.displayLarge(this);
  
  /// ฟอนต์หัวข้อกลาง
  TextStyle get headlineMediumText => ResponsiveText.headlineMedium(this);
  
  /// ฟอนต์ข้อความปกติ
  TextStyle get bodyLargeText => ResponsiveText.bodyLarge(this);
  
  /// ฟอนต์ข้อความรอง
  TextStyle get bodyMediumText => ResponsiveText.bodyMedium(this);
  
  /// ฟอนต์ป้ายกำกับ
  TextStyle get labelLargeText => ResponsiveText.labelLarge(this);
  
  /// ฟอนต์ปุ่ม
  TextStyle get buttonTextStyle => ResponsiveText.buttonText(this);
  
  /// ฟอนต์เล็ก
  TextStyle get captionText => ResponsiveText.caption(this);
}