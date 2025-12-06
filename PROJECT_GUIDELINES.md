# คู่มือมาตรฐานการพัฒนาโปรเจ็ค Coop Digital (Project Guidelines)

เอกสารนี้สรุปธีมหลัก (Design Theme) และกฎเกณฑ์ทางเทคนิค (Technical Rules) เพื่อให้ทีมงานสามารถแก้ไขและพัฒนาต่อยอดได้โดยไม่กระทบโครงสร้างหลักของระบบ

## 1. ธีมและการออกแบบ (Design Theme)

โปรเจ็คนี้ใช้ **Material 3** เป็นฐานในการออกแบบ โดยมีความเป็นเอกลักษณ์ดังนี้:

### 🎨 ชุดสี (Color Palette)
**ห้าม Hardcode ค่าสี** ให้เรียกใช้ผ่าน class `AppColors` เท่านั้น
- **Primary Color (สีหลัก):** Blue `#1A90CE` (ใช้กับ Header, ปุ่มหลัก, Active State)
- **Secondary Color (สีรอง):** Pink `#FA0585` (ใช้กับ Icon, Accent Text)
- **Background:** Light Gray `#F5F5F5`
- **Surface (Card/Input):** White `#FFFFFF`
- **Semantic Colors:** 
  - Success: Green `#4CAF50`
  - Error: Red `#E53935`

### 🔤 ตัวอักษร (Typography)
- **Font Family:** `Prompt` (Google Fonts)
- **การใช้งาน:** ระบบมีการตั้งค่า TextTheme ไว้แล้วใน `AppTheme` ให้เรียกใช้ผ่าน `Theme.of(context).textTheme` แทนการกำหนด Style เองทุกครั้ง

### 🧩 รูปลักษณ์องค์ประกอบ (Component Styles)
- **Border Radius:** มาตรฐานอยู่ที่ `12px` (Button, Input) ถึง `16px` (Card)
- **Input Fields:** สไตล์ Filled สีขาว ขอบมน 12px
- **Buttons:** พื้นหลังสี Primary ตัวหนังสือสีขาว ขอบมน 12px
- **AppBar:** สี Primary, ตัวหนังสือสีขาว, กึ่งกลาง (Center Title)

---

## 2. สถาปัตยกรรมและเทคโนโลยี (Architecture & Tech Stack)

### 🛠 Core Tech
- **Framework:** Flutter
- **State Management:** Riverpod (`ConsumerWidget`, `ProviderScope`)
- **Routing:** GoRouter
- **Backend:** Firebase Integration

### 📂 โครงสร้างไฟล์ (Folder Structure)
โปรเจ็คใช้โครงสร้างแบบ **Feature-first** (`lib/features/`) แบ่งตามการใช้งานจริง:
```
lib/
  ├── core/            # โค้ดส่วนกลาง (Theme, Router, Utils)
  ├── features/        # แยกตามฟีเจอร์ (เช่น home, loan)
  │    ├── [feature_name]/
  │    │    ├── data/          # Repository, API calls
  │    │    ├── domain/        # Models, Entities
  │    │    └── presentation/  # Screens, Widgets
  └── main.dart        # Entry point
```

---

## 3. กฎเหล็กในการพัฒนา (Core Development Rules)

เพื่อให้โค้ดสะอาดและดูแลรักษาง่าย ขอให้ปฏิบัติตามกฎดังนี้:

1. **การจัดการ Navigation:**
   - ห้ามใช้ `Navigator.push` แบบปกติ ให้ใช้ `context.go()` หรือ `context.push()` ผ่าน **GoRouter** เสมอ
   - หากเพิ่มหน้าจอใหม่ ต้องไปลงทะเบียน Route ใน `lib/core/router/router_provider.dart`

2. **การจัดการ State:**
   - ใช้ **Riverpod** ในการจัดการ Logic และ State ของแอพ
   - หลีกเลี่ยงการใช้ `setState` ใน Logic ที่ซับซ้อน หรือ Logic ข้าม Widget

3. **การแก้ไข UI/Theme:**
   - หากต้องการเปลี่ยนธีมรวม ให้แก้ที่ `lib/core/theme/app_theme.dart` ที่เดียว
   - ห้ามแก้สีที่ไฟล์ Widget โดยตรง ถ้าสีนั้นเป็นสีหลักของแอพ (ให้แก้ที่ `AppColors`)

4. **โครงสร้าง Widget:**
   - ถ้า Widget เริ่มยาวเกินไป ให้แยกเป็นไฟล์ย่อยในโฟลเดอร์ `widgets/` ของฟีเจอร์นั้นๆ
   - ใช้ `ConsumerWidget` เมื่อต้องการเข้าถึง State ของ Riverpod

---

> **หมายเหตุ:** ก่อนเริ่มงานฟีเจอร์ใหม่ ให้ตรวจสอบไฟล์ใน `lib/core/` เพื่อดูว่ามี components หรือ utilities ใดที่สามารถนำมาใช้ซ้ำได้ เพื่อลดความซ้ำซ้อนของโค้ด