# คู่มือการใช้งานระบบ Responsive Design

## ภาพรวม

ระบบ Responsive Design นี้ถูกออกแบบมาเพื่อแก้ไขปัญหาการแสดงผลที่ไม่สม่ำเสมอในอุปกรณ์มือถือและแท็บเล็ตขนาดต่างๆ โดยมีหลักการสำคัญ:

- **ล็อคการซูม**: ไม่ตอบสนองต่อการตั้งค่าการเข้าถึงของระบบ
- **ตอบสนองตามขนาดหน้าจอ**: ปรับขนาดตามอุปกรณ์ 4.7" - 8" 
- **รักษาเอกลักษณ์**: ใช้สีและธีมเดิมทั้งหมด

## โครงสร้างไฟล์

```
lib/core/utils/
├── responsive_utils.dart      # ระบบตรวจสอบขนาดหน้าจอ
├── responsive_text.dart       # ระบบฟอนต์ตอบสนอง
└── responsive_spacing.dart    # ระบบ spacing ตอบสนอง
```

## การใช้งาน

### 1. ตรวจสอบขนาดหน้าจอ

```dart
// ตรวจสอบประเภทขนาดหน้าจอ
final screenSize = context.screenSize;
switch (screenSize) {
  case ScreenSize.small:
    // หน้าจอ 4.7" - 5.5"
    break;
  case ScreenSize.medium:
    // หน้าจอ 5.5" - 6.7" 
    break;
  case ScreenSize.large:
    // หน้าจอ 6.7" - 8"
    break;
  case ScreenSize.extraLarge:
    // หน้าจอ 8"+ (แท็บเล็ต)
    break;
}

// ตรวจสอบแบบง่ายๆ
if (context.isSmallScreen) {
  // ปรับขนาดเล็กลง
}

if (context.isLargeScreen) {
  // ปรับขนาดใหญ่ขึ้น
}
```

### 2. ใช้ฟอนต์ตอบสนอง

```dart
// ใช้ฟอนต์ที่กำหนดไว้แล้ว
Text('หัวข้อ', style: context.displayLargeText);
Text('ข้อความปกติ', style: context.bodyLargeText);
Text('ข้อความรอง', style: context.bodyMediumText);

// หรือสร้างแบบกำหนดเอง
Text(
  'ข้อความกำหนดเอง',
  style: ResponsiveText.custom(
    context,
    18, // ขนาดฐาน
    fontWeight: FontWeight.bold,
    color: Colors.blue,
  ),
);

// ใช้ ResponsiveTextWidget (แนะนำ)
ResponsiveTextWidget(
  text: 'ข้อความที่ตอบสนอง',
  style: context.bodyLargeText,
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
);
```

### 3. ใช้ spacing ตอบสนอง

```dart
// ใช้ spacing ที่กำหนดไว้แล้ว
Padding(
  padding: context.screenPadding, // สำหรับขอบหน้าจอ
  child: YourWidget(),
);

Padding(
  padding: context.cardPadding, // สำหรับ card
  child: YourWidget(),
);

// สร้าง spacing แบบกำหนดเอง
Column(
  children: [
    Widget1(),
    context.spacerM, // spacing กลาง
    Widget2(),
    context.spacerL, // spacing ใหญ่
    Widget3(),
  ],
);

// Padding แบบกำหนดเอง
Padding(
  padding: ResponsiveSpacing.custom(context, 20),
  child: YourWidget(),
);
```

### 4. Layout ที่ตอบสนอง

```dart
// ใช้ Flexible และ Expanded
Row(
  children: [
    Flexible(
      child: Text('ข้อความที่ยาวมากๆ'),
    ),
    context.hSpacerM,
    Icon(Icons.star),
  ],
);

// ใช้ Wrap แทน Row เพื่อป้องกัน overflow
Wrap(
  spacing: context.spacingS,
  children: [
    Chip(label: Text('Tag 1')),
    Chip(label: Text('Tag 2')),
    Chip(label: Text('Tag 3')),
  ],
);

// ใช้ LayoutBuilder
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth < 400) {
      return Column(
        children: [Widget1(), Widget2()],
      );
    } else {
      return Row(
        children: [Widget1(), Widget2()],
      );
    }
  },
);
```

### 5. ล็อคการซูม

```dart
// สำหรับ Text Widget
Text(
  'ข้อความ',
  textScaleFactor: 1.0, // ล็อคการซูม
);

// สำหรับ TextFormField
TextFormField(
  textScaleFactor: 1.0, // ล็อคการซูม
  decoration: InputDecoration(...),
);

// สำหรับ ResponsiveTextWidget
ResponsiveTextWidget(
  text: 'ข้อความ', // มีการล็อคการซูม built-in
);
```

## ขนาดหน้าจอที่รองรับ

| ขนาด | ช่วงหน้าจอ | Scale Factor | ตัวอย่างอุปกรณ์ |
|------|-------------|--------------|----------------|
| Small | 4.7" - 5.5" | 0.9 | iPhone SE, Android small |
| Medium | 5.5" - 6.7" | 1.0 | iPhone 12/13, Android standard |
| Large | 6.7" - 8" | 1.1 | iPhone Pro Max, Android large |
| Extra Large | 8"+ | 1.2 | iPad, Android tablet |

## Best Practices

### 1. ใช้ ResponsiveTextWidget แทน Text

```dart
// ✅ แนะนำ
ResponsiveTextWidget(
  text: 'ข้อความ',
  style: context.bodyLargeText,
);

// ❌ ไม่แนะนำ
Text(
  'ข้อความ',
  style: TextStyle(fontSize: 16), // ขนาดคงที่
);
```

### 2. ใช้ context extensions

```dart
// ✅ แนะนำ
context.spacerM
context.screenPadding
context.bodyLargeText

// ❌ ไม่แนะนำ
ResponsiveSpacing.m(context)
ResponsiveSpacing.screenPadding(context)
ResponsiveText.bodyLarge(context)
```

### 3. ใช้ Flexible สำหรับข้อความยาว

```dart
// ✅ แนะนำ
Flexible(
  child: ResponsiveTextWidget(
    text: longText,
    overflow: TextOverflow.ellipsis,
  ),
)

// ❌ ไม่แนะนำ
ResponsiveTextWidget(
  text: longText,
  // ไม่มีการจัดการ overflow
)
```

### 4. ทดสอบในขนาดต่างๆ

```dart
// ใช้ Flutter Inspector เปลี่ยนขนาดหน้าจอ
// หรือใช้ device simulation
// ทดสอบใน iPhone SE (small), iPhone 12 (medium), iPad (large)
```

## การแก้ไขปัญหาที่พบบ่อย

### 1. ข้อความล้นขอบ

```dart
// ✅ แก้ไขด้วย Flexible
Flexible(
  child: ResponsiveTextWidget(
    text: longText,
    overflow: TextOverflow.ellipsis,
  ),
)

// ✅ หรือใช้ Wrap
Wrap(
  children: longText.split(' ').map((word) => 
    Chip(label: Text(word))
  ).toList(),
)
```

### 2. ปุ่มเล็กเกินไปในหน้าจอเล็ก

```dart
// ✅ ปรับขนาดตามหน้าจอ
SizedBox(
  height: context.isSmallScreen ? 48 : 54,
  child: ElevatedButton(...),
)
```

### 3. Card แคบเกินไป

```dart
// ✅ ใช้ responsive card
Card(
  margin: context.screenPadding,
  child: Padding(
    padding: context.cardPadding,
    child: content,
  ),
)
```

## การ Migration จากโค้ดเก่า

### เปลี่ยน Text Style

```dart
// เดิม
Text('Hello', style: TextStyle(fontSize: 16))

// ใหม่
ResponsiveTextWidget('Hello', style: context.bodyLargeText)
```

### เปลี่ยน Padding

```dart
// เดิม
Padding(padding: EdgeInsets.all(24.0))

// ใหม่
Padding(padding: context.screenPadding)
```

### เปลี่ยน SizedBox

```dart
// เดิม
SizedBox(height: 16.0)

// ใหม่
context.spacerM
```

## สรุป

ระบบนี้ช่วยให้แอปมีความสม่ำเสมอในทุกอุปกรณ์โดย:
- ล็อคการซูมเพื่อความสม่ำเสมอ
- ปรับขนาดตามหน้าจอเพื่อความเหมาะสม  
- ใช้งานง่ายด้วย context extensions
- ป้องกัน overflow ด้วย layout ที่เหมาะสม

หากมีปัญหาหรือข้อสงสัย สามารถดูตัวอย่างใน LoginScreen และ HomeHeader ได้