# Manhwa Reader (Flutter)

تطبيق قارئ مانهو مع:
- تنزيل الفصول + OCR + ترجمة تلقائية (LibreTranslate) وحفظ أوفلاين
- مكتبة فصول، متابعة آخر صفحة لكل فصل
- وضع ليلي، تغيير حجم النص، إظهار/إخفاء الترجمة
- تنزيل في الخلفية + إشعارات + جدولة + قائمة انتظار + إيقاف/استئناف

## طريقة التشغيل السريعة
1) أنشئ مشروع Flutter جديد (مرة واحدة):
   ```bash
   flutter create manhwa_reader
   ```
2) انسخ محتويات هذا المجلد فوق المشروع (استبدل `lib/` و `pubspec.yaml` وأضف `assets/`).
3) ثبّت الحزم:
   ```bash
   flutter pub get
   ```
4) (Android فقط) أضف صلاحيات الشبكة والتخزين في `android/app/src/main/AndroidManifest.xml`:
   ```xml
   <uses-permission android:name="android.permission.INTERNET"/>
   <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
   ```
5) (اختياري) فعل WorkManager حسب جهازك. في بعض الأجهزة يلزم تمكين battery optimization exceptions.
6) شغّل:
   ```bash
   flutter run
   ```
7) بناء نسخة إطلاق:
   ```bash
   flutter build apk --release
   ```

> ملاحظة: خدمة الترجمة تستخدم LibreTranslate العام. يمكنك تثبيت خادم محلي أو استبداله بـ Google Translate API.
> لتغيير روابط الفصول: حرّر `lib/screens/chapter_list_screen.dart` وعدّل قائمة `chapters`.

