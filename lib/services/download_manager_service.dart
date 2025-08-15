import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class DownloadManagerService {
  static Future<String> _dir() async => (await getApplicationDocumentsDirectory()).path;

  static Future<List<Map<String, dynamic>>> getDownloadedChapters() async {
    final d = Directory(await _dir());
    if (!await d.exists()) return [];
    final list = <Map<String, dynamic>>[];
    for (final f in d.listSync().where((e) => e.path.endsWith('.json'))) {
      final name = f.uri.pathSegments.last.replaceAll('.json', '');
      final content = await File(f.path).readAsString();
      final data = json.decode(content) as Map<String, dynamic>;
      list.add({'title': name.replaceAll('_',' '), 'pages': data.length, 'filePath': f.path});
    }
    return list;
  }

  static Future<void> deleteChapter(String title) async {
    final safe = title.replaceAll(' ', '_');
    final jsonFile = File('${await _dir()}/$safe.json');
    if (await jsonFile.exists()) {
      final data = json.decode(await jsonFile.readAsString()) as Map<String, dynamic>;
      for (final v in data.values) {
        final p = v['imagePath'] as String?;
        if (p != null && await File(p).exists()) {
          await File(p).delete();
        }
      }
      await jsonFile.delete();
    }
  }
}
