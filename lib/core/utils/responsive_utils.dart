import 'package:flutter/material.dart';

/// ระบบตรวจสอบขนาดหน้าจอและคำนวณค่าที่ตอบสนอง
/// โดยไม่ตอบสนองต่อการตั้งค่าการเข้าถึงของระบบ (ล็อคการซูม)
class ResponsiveUtils {
  /// Breakpoints สำหรับขนาดหน้าจอต่างๆ (หน่วย: logical pixels)
  static const double smallScreenWidth = 400;  // 4.7" - 5.5"
  static const double mediumScreenWidth = 500; // 5.5" - 6.7"
  static const double largeScreenWidth = 600;  // 6.7" - 8"+

  /// ตรวจสอบประเภทขนาดหน้าจอ
  static ScreenSize getScreenSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < smallScreenWidth) {
      return ScreenSize.small;
    } else if (screenWidth < mediumScreenWidth) {
      return ScreenSize.medium;
    } else if (screenWidth < largeScreenWidth) {
      return ScreenSize.large;
    } else {
      return ScreenSize.extraLarge;
    }
  }

  /// คำนวณ scale factor สำหรับ responsive design
  static double getScaleFactor(BuildContext context) {
    final screenSize = getScreenSize(context);
    
    switch (screenSize) {
      case ScreenSize.small:
        return 0.9; // ลดขนาดเล็กนิดหน่อยสำหรับหน้าจอเล็ก
      case ScreenSize.medium:
        return 1.0; // ขนาดมาตรฐาน
      case ScreenSize.large:
        return 1.1; // เพิ่มขนาดเล็กนิดหน่อยสำหรับหน้าจอใหญ่
      case ScreenSize.extraLarge:
        return 1.2; // เพิ่มขนาดสำหรับแท็บเล็ต
    }
  }

  /// ตรวจสอบว่าเป็นหน้าจอขนาดเล็กหรือไม่
  static bool isSmallScreen(BuildContext context) {
    return getScreenSize(context) == ScreenSize.small;
  }

  /// ตรวจสอบว่าเป็นหน้าจอขนาดใหญ่หรือไม่
  static bool isLargeScreen(BuildContext context) {
    final screenSize = getScreenSize(context);
    return screenSize == ScreenSize.large || screenSize == ScreenSize.extraLarge;
  }

  /// ตรวจสอบว่าเป็นแนวตั้งหรือแนวนอน
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// ตรวจสอบ safe area (notch, home indicator, etc.)
  static EdgeInsets getSafeArea(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// คำนวณความสูงที่ใช้งานได้จริง (ลบ safe area)
  static double getUsableHeight(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.height - mediaQuery.padding.top - mediaQuery.padding.bottom;
  }

  /// คำนวณความกว้างที่ใช้งานได้จริง (ลบ safe area)
  static double getUsableWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.size.width - mediaQuery.padding.left - mediaQuery.padding.right;
  }
}

/// ประเภทขนาดหน้าจอ
enum ScreenSize {
  small,    // 4.7" - 5.5"
  medium,   // 5.5" - 6.7"
  large,    // 6.7" - 8"
  extraLarge // 8"+ (แท็บเล็ต)
}

/// Extension สำหรับ BuildContext เพื่อใช้งานง่าย
extension ResponsiveBuildContext on BuildContext {
  /// รับขนาดหน้าจอ
  ScreenSize get screenSize => ResponsiveUtils.getScreenSize(this);
  
  /// รับ scale factor
  double get scaleFactor => ResponsiveUtils.getScaleFactor(this);
  
  /// ตรวจสอบหน้าจอเล็ก
  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);
  
  /// ตรวจสอบหน้าจอใหญ่
  bool get isLargeScreen => ResponsiveUtils.isLargeScreen(this);
  
  /// ตรวจสอบแนวนอน
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
  
  /// รับ safe area
  EdgeInsets get safeArea => ResponsiveUtils.getSafeArea(this);
  
  /// รับความสูงที่ใช้งานได้
  double get usableHeight => ResponsiveUtils.getUsableHeight(this);
  
  /// รับความกว้างที่ใช้งานได้
  double get usableWidth => ResponsiveUtils.getUsableWidth(this);
}