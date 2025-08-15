import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LocalStorageService {
  static Future<String> _dir() async => (await getApplicationDocumentsDirectory()).path;

  static Future<File> _jsonFile(String chapterTitle) async {
    final path = await _dir();
    final safe = chapterTitle.replaceAll(' ', '_');
    return File('$path/$safe.json');
  }

  static Future<File> _imageFile(String name) async {
    final path = await _dir();
    return File('$path/$name');
  }

  static Future<void> saveChapterData(String chapterTitle, Map<int, dynamic> data) async {
    final f = await _jsonFile(chapterTitle);
    await f.writeAsString(json.encode(data));
  }

  static Future<Map<int, dynamic>?> loadChapterData(String chapterTitle) async {
    final f = await _jsonFile(chapterTitle);
    if (await f.exists()) {
      final data = json.decode(await f.readAsString()) as Map<String, dynamic>;
      return data.map((k, v) => MapEntry(int.parse(k), v));
    }
    return null;
  }

  static Future<String> saveImage(String imageName, List<int> bytes) async {
    final f = await _imageFile(imageName);
    await f.writeAsBytes(bytes);
    return f.path;
  }

  static Future<String?> getImagePath(String imageName) async {
    final f = await _imageFile(imageName);
    return await f.exists() ? f.path : null;
  }
}
