import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'local_storage_service.dart';

class DownloadService {
  static bool isPaused = false;

  static Future<void> pauseDownload() async {
    isPaused = true;
  }

  static Future<void> resumeDownload(String chapterTitle, List<String> pageUrls,
      {Function(int current, int total)? onProgress}) async {
    isPaused = false;
    await downloadFullChapter(chapterTitle, pageUrls, onProgress: onProgress);
  }

  static Future<void> downloadFullChapter(String chapterTitle, List<String> pageUrls,
      {Function(int current, int total)? onProgress}) async {
    final prefs = await SharedPreferences.getInstance();
    final progressKey = '${chapterTitle}_progress';
    int last = prefs.getInt(progressKey) ?? 0;

    final existing = await LocalStorageService.loadChapterData(chapterTitle) ?? {};
    final Map<int, dynamic> chapterData = Map<int, dynamic>.from(existing);

    for (int i = last; i < pageUrls.length; i++) {
      if (isPaused) {
        await prefs.setInt(progressKey, i);
        return;
      }
      final res = await http.get(Uri.parse(pageUrls[i]));
      final imagePath = await LocalStorageService.saveImage('${chapterTitle}_page_$i.jpg', res.bodyBytes);

      final recognizer = TextRecognizer();
      final input = InputImage.fromFilePath(imagePath);
      final ocr = await recognizer.processImage(input);
      final ocrText = (ocr.text.trim().isEmpty) ? 'لا يوجد نص' : ocr.text.trim();

      final translation = await _translateText(ocrText);

      chapterData[i] = {'ocr': ocrText, 'translation': translation, 'imagePath': imagePath};

      if (onProgress != null) onProgress(i + 1, pageUrls.length);
    }

    await LocalStorageService.saveChapterData(chapterTitle, chapterData);
    await prefs.remove(progressKey);
  }

  static Future<String> _translateText(String text) async {
    try {
      final uri = Uri.parse('https://libretranslate.de/translate');
      final res = await http.post(uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'q': text, 'source': 'auto', 'target': 'ar', 'format': 'text'}));
      if (res.statusCode == 200) {
        final data = json.decode(res.body) as Map<String, dynamic>;
        return (data['translatedText'] ?? 'خطأ في الترجمة').toString();
      }
      return 'تعذر الترجمة';
    } catch (_) {
      return 'خطأ في الاتصال';
    }
  }
}
