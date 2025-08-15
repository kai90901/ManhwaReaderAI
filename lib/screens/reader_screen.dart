import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_storage_service.dart';

class ReaderScreen extends StatefulWidget {
  final List<String> pageUrls;
  final String chapterTitle;
  const ReaderScreen({super.key, required this.pageUrls, required this.chapterTitle});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late PageController _controller;
  double fontSize = 16;
  bool showTranslation = true;
  int currentPageIndex = 0;
  Map<int, String> extractedTexts = {};
  Map<int, String> translatedTexts = {};
  Map<int, String> localImagePaths = {};

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      _controller = PageController(initialPage: currentPageIndex);
      setState(() {});
    });
    _prepare(0);
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      fontSize = prefs.getDouble('fontSize') ?? 16;
      showTranslation = prefs.getBool('showTranslation') ?? true;
      currentPageIndex = prefs.getInt('lastPageIndex_${widget.chapterTitle}') ?? 0;
    });
  }

  Future<void> _saveCurrentPage(int i) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastPageIndex_${widget.chapterTitle}', i);
  }

  Future<void> _prepare(int index) async {
    if (translatedTexts.containsKey(index)) return;
    // load or download image
    String? localPath = await LocalStorageService.getImagePath('${widget.chapterTitle}_page_$index.jpg');
    if (localPath == null) {
      if (index < widget.pageUrls.length && widget.pageUrls[index].startsWith('http')) {
        final res = await http.get(Uri.parse(widget.pageUrls[index]));
        localPath = await LocalStorageService.saveImage('${widget.chapterTitle}_page_$index.jpg', res.bodyBytes);
      } else if (index < widget.pageUrls.length) {
        localPath = widget.pageUrls[index];
      } else {
        return;
      }
    }
    localImagePaths[index] = localPath;

    // OCR
    final recognizer = TextRecognizer();
    final input = InputImage.fromFilePath(localPath);
    final r = await recognizer.processImage(input);
    final ocr = r.text.trim().isEmpty ? 'لا يوجد نص' : r.text.trim();
    extractedTexts[index] = ocr;

    // fallback: عرض الـ OCR كنص طبقة (الترجمة النهائية تعتمد على التحميل المُسبق)
    translatedTexts[index] = extractedTexts[index];

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chapterTitle),
        actions: [
          IconButton(
            tooltip: showTranslation ? 'إخفاء الترجمة' : 'إظهار الترجمة',
            icon: Icon(showTranslation ? Icons.subtitles : Icons.subtitles_off),
            onPressed: () async {
              setState(() => showTranslation = !showTranslation);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showTranslation', showTranslation);
            },
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () async {
              setState(() => fontSize = (fontSize - 2).clamp(10, 40));
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('fontSize', fontSize);
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              setState(() => fontSize = (fontSize + 2).clamp(10, 40));
              final prefs = await SharedPreferences.getInstance();
              await prefs.setDouble('fontSize', fontSize);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _controller,
        scrollDirection: Axis.vertical,
        itemCount: widget.pageUrls.length,
        onPageChanged: (i) {
          setState(() => currentPageIndex = i);
          _saveCurrentPage(i);
          _prepare(i);
          if (i + 1 < widget.pageUrls.length) _prepare(i + 1);
        },
        itemBuilder: (context, i) {
          final imagePath = localImagePaths[i];
          return InteractiveViewer(
            minScale: 0.8,
            maxScale: 4.0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: imagePath != null
                      ? Image.file(File(imagePath), fit: BoxFit.contain)
                      : (i < widget.pageUrls.length && widget.pageUrls[i].startsWith('http')
                          ? Image.network(widget.pageUrls[i], fit: BoxFit.contain)
                          : const SizedBox.shrink()),
                ),
                if (showTranslation)
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      color: Colors.black54,
                      child: Text(
                        translatedTexts[i] ?? extractedTexts[i] ?? 'جارٍ التحليل...',
                        style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
