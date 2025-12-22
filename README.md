# run app
flutter run -d chrome

# Build Flutter web
flutter build web

# Deploy ขึ้น Firebase
firebase deploy --only hosting


# วิธีใช้งาน (Command Line):

## DEV: 
flutter run -d chrome --dart-define=ENV=dev
flutter run --dart-define=ENV=dev
## STAGING: flutter run --dart-define=ENV=staging
## UAT: flutter run --dart-define=ENV=uat
## PRODUCTION: flutter run --dart-define=ENV=prod (หรือแค่ flutter run เฉยๆ ก็จะเป็น Production เป็นค่าเริ่มต้นครับ)
วิธีนี้ใช้ได้เหมือนกันตอน Build (เช่น flutter build web --dart-define=ENV=uat) ครับ

## CORS Issue: หากรันบน Chrome แล้วเจอปัญหา CORS (เรียก API ไม่ได้) แนะนำให้ใช้คำสั่งนี้เพื่อปิด security ชั่วคราวสำหรับการ dev:
flutter run -d chrome --web-renderer html --web-browser-flag "--disable-web-security" --dart-define=ENV=dev