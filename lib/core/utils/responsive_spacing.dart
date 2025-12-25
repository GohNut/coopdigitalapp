import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// ระบบ spacing ตอบสนองสำหรับ padding และ margin
/// ปรับขนาดตามขนาดหน้าจอเพื่อให้เหมาะสมกับอุปกรณ์ต่างๆ
class ResponsiveSpacing {
  /// ค่า spacing มาตรฐาน (หน่วย: logical pixels)
  static const double _baseXS = 4.0;
  static const double _baseS = 8.0;
  static const double _baseM = 16.0;
  static const double _baseL = 24.0;
  static const double _baseXL = 32.0;
  static const double _baseXXL = 48.0;

  /// คำนวณ spacing ที่ตอบสนองตามขนาดหน้าจอ
  static double _getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final scaleFactor = ResponsiveUtils.getScaleFactor(context);
    return baseSpacing * scaleFactor;
  }

  /// Extra Small Spacing (4px -> responsive)
  static double xs(BuildContext context) => _getResponsiveSpacing(context, _baseXS);

  /// Small Spacing (8px -> responsive)
  static double s(BuildContext context) => _getResponsiveSpacing(context, _baseS);

  /// Medium Spacing (16px -> responsive)
  static double m(BuildContext context) => _getResponsiveSpacing(context, _baseM);

  /// Large Spacing (24px -> responsive)
  static double l(BuildContext context) => _getResponsiveSpacing(context, _baseL);

  /// Extra Large Spacing (32px -> responsive)
  static double xl(BuildContext context) => _getResponsiveSpacing(context, _baseXL);

  /// Extra Extra Large Spacing (48px -> responsive)
  static double xxl(BuildContext context) => _getResponsiveSpacing(context, _baseXXL);

  /// Padding สำหรับหน้าจอเล็ก (ขอบหน้าจอ)
  static EdgeInsets screenPadding(BuildContext context) {
    final spacing = m(context);
    return EdgeInsets.all(spacing);
  }

  /// Padding สำหรับหน้าจอกลาง
  static EdgeInsets screenPaddingMedium(BuildContext context) {
    final spacing = l(context);
    return EdgeInsets.all(spacing);
  }

  /// Padding สำหรับหน้าจอใหญ่
  static EdgeInsets screenPaddingLarge(BuildContext context) {
    final spacing = xl(context);
    return EdgeInsets.all(spacing);
  }

  /// Padding แนวตั้งสำหรับหน้าจอ
  static EdgeInsets verticalPadding(BuildContext context) {
    final vertical = m(context);
    return EdgeInsets.symmetric(vertical: vertical);
  }

  /// Padding แนวนอนสำหรับหน้าจอ
  static EdgeInsets horizontalPadding(BuildContext context) {
    final horizontal = m(context);
    return EdgeInsets.symmetric(horizontal: horizontal);
  }

  /// Padding สำหรับ Card
  static EdgeInsets cardPadding(BuildContext context) {
    final padding = m(context);
    return EdgeInsets.all(padding);
  }

  /// Padding สำหรับ Button
  static EdgeInsets buttonPadding(BuildContext context) {
    final vertical = s(context);
    final horizontal = m(context);
    return EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
  }

  /// Padding สำหรับ Form Field
  static EdgeInsets formFieldPadding(BuildContext context) {
    final vertical = s(context);
    final horizontal = m(context);
    return EdgeInsets.symmetric(vertical: vertical, horizontal: horizontal);
  }

  /// Margin ระหว่าง Element
  static SizedBox spacerXS(BuildContext context) => SizedBox(height: xs(context));
  static SizedBox spacerS(BuildContext context) => SizedBox(height: s(context));
  static SizedBox spacerM(BuildContext context) => SizedBox(height: m(context));
  static SizedBox spacerL(BuildContext context) => SizedBox(height: l(context));
  static SizedBox spacerXL(BuildContext context) => SizedBox(height: xl(context));
  static SizedBox spacerXXL(BuildContext context) => SizedBox(height: xxl(context));

  /// Horizontal Spacer
  static SizedBox hSpacerXS(BuildContext context) => SizedBox(width: xs(context));
  static SizedBox hSpacerS(BuildContext context) => SizedBox(width: s(context));
  static SizedBox hSpacerM(BuildContext context) => SizedBox(width: m(context));
  static SizedBox hSpacerL(BuildContext context) => SizedBox(width: l(context));
  static SizedBox hSpacerXL(BuildContext context) => SizedBox(width: xl(context));
  static SizedBox hSpacerXXL(BuildContext context) => SizedBox(width: xxl(context));

  /// EdgeInsets แบบกำหนดเอง
  static EdgeInsets custom(BuildContext context, double baseSpacing) {
    return EdgeInsets.all(_getResponsiveSpacing(context, baseSpacing));
  }

  /// EdgeInsets แบบ asymmetric
  static EdgeInsets asymmetric(
    BuildContext context, {
    double vertical = 0,
    double horizontal = 0,
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  }) {
    return EdgeInsets.only(
      top: top > 0 ? _getResponsiveSpacing(context, top) : vertical > 0 ? _getResponsiveSpacing(context, vertical) : 0,
      bottom: bottom > 0 ? _getResponsiveSpacing(context, bottom) : vertical > 0 ? _getResponsiveSpacing(context, vertical) : 0,
      left: left > 0 ? _getResponsiveSpacing(context, left) : horizontal > 0 ? _getResponsiveSpacing(context, horizontal) : 0,
      right: right > 0 ? _getResponsiveSpacing(context, right) : horizontal > 0 ? _getResponsiveSpacing(context, horizontal) : 0,
    );
  }
}

/// Extension สำหรับ BuildContext เพื่อใช้งาน spacing ง่าย
extension ResponsiveSpacingExtensions on BuildContext {
  /// Spacing values
  double get spacingXS => ResponsiveSpacing.xs(this);
  double get spacingS => ResponsiveSpacing.s(this);
  double get spacingM => ResponsiveSpacing.m(this);
  double get spacingL => ResponsiveSpacing.l(this);
  double get spacingXL => ResponsiveSpacing.xl(this);
  double get spacingXXL => ResponsiveSpacing.xxl(this);

  /// Screen padding
  EdgeInsets get screenPadding => ResponsiveSpacing.screenPadding(this);
  EdgeInsets get screenPaddingMedium => ResponsiveSpacing.screenPaddingMedium(this);
  EdgeInsets get screenPaddingLarge => ResponsiveSpacing.screenPaddingLarge(this);

  /// Specialized padding
  EdgeInsets get verticalPadding => ResponsiveSpacing.verticalPadding(this);
  EdgeInsets get horizontalPadding => ResponsiveSpacing.horizontalPadding(this);
  EdgeInsets get cardPadding => ResponsiveSpacing.cardPadding(this);
  EdgeInsets get buttonPadding => ResponsiveSpacing.buttonPadding(this);
  EdgeInsets get formFieldPadding => ResponsiveSpacing.formFieldPadding(this);

  /// Spacers
  SizedBox get spacerXS => ResponsiveSpacing.spacerXS(this);
  SizedBox get spacerS => ResponsiveSpacing.spacerS(this);
  SizedBox get spacerM => ResponsiveSpacing.spacerM(this);
  SizedBox get spacerL => ResponsiveSpacing.spacerL(this);
  SizedBox get spacerXL => ResponsiveSpacing.spacerXL(this);
  SizedBox get spacerXXL => ResponsiveSpacing.spacerXXL(this);

  /// Horizontal spacers
  SizedBox get hSpacerXS => ResponsiveSpacing.hSpacerXS(this);
  SizedBox get hSpacerS => ResponsiveSpacing.hSpacerS(this);
  SizedBox get hSpacerM => ResponsiveSpacing.hSpacerM(this);
  SizedBox get hSpacerL => ResponsiveSpacing.hSpacerL(this);
  SizedBox get hSpacerXL => ResponsiveSpacing.hSpacerXL(this);
  SizedBox get hSpacerXXL => ResponsiveSpacing.hSpacerXXL(this);
}