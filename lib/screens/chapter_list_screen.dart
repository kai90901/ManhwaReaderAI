import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'reader_screen.dart';
import 'downloaded_chapters_screen.dart';
import 'schedule_download_screen.dart';
import '../services/download_service.dart';

class ChapterListScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDarkMode;
  const ChapterListScreen({super.key, required this.onToggleTheme, required this.isDarkMode});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  bool isOffline = false;

  final List<Map<String, dynamic>> chapters = [
    {
      'title': 'الفصل 1',
      'pages': [
        'https://picsum.photos/seed/11/900/1400',
        'https://picsum.photos/seed/12/900/1400',
      ]
    },
    {
      'title': 'الفصل 2',
      'pages': [
        'https://picsum.photos/seed/21/900/1400',
        'https://picsum.photos/seed/22/900/1400',
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    setState(() => isOffline = connectivity == ConnectivityResult.none);
  }

  Future<List<String>> _getDownloadedPages(String chapterTitle, int count) async {
    final dir = await getApplicationDocumentsDirectory();
    final List<String> list = [];
    for (int i = 0; i < count; i++) {
      final path = '${dir.path}/${chapterTitle}_page_$i.jpg';
      if (File(path).existsSync()) list.add(path);
    }
    return list;
  }

  Future<bool> _isChapterDownloaded(String title, int count) async {
    final l = await _getDownloadedPages(title, count);
    return l.length == count;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isOffline ? '📴 أوفلاين' : '📚 مكتبة الفصول'),
        actions: [
          IconButton(
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DownloadedChaptersScreen())),
            icon: const Icon(Icons.folder),
            tooltip: 'الفصول المحمّلة',
          ),
          IconButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScheduleDownloadScreen())),
            icon: const Icon(Icons.schedule),
            tooltip: 'جدولة التحميل',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          final title = chapters[i]['title'] as String;
          final pages = List<String>.from(chapters[i]['pages']);
          return FutureBuilder<bool>(
            future: _isChapterDownloaded(title, pages.length),
            builder: (context, snap) {
              final downloaded = snap.data ?? false;
              return ListTile(
                title: Text(title),
                subtitle: Text(downloaded ? '✅ محمّل' : 'غير محمّل'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(downloaded ? Icons.check_circle : Icons.download),
                      onPressed: downloaded
                          ? null
                          : () async {
                              int total = pages.length;
                              int current = 0;
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) {
                                  return StatefulBuilder(builder: (context, setStateDialog) {
                                    return AlertDialog(
                                      title: const Text('جاري التنزيل...'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          LinearProgressIndicator(value: total == 0 ? null : current / total),
                                          const SizedBox(height: 8),
                                          Text('${((current / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}%'),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              TextButton(
                                                onPressed: () => DownloadService.pauseDownload(),
                                                child: const Text('إيقاف مؤقت'),
                                              ),
                                              const SizedBox(width: 8),
                                              TextButton(
                                                onPressed: () => DownloadService.resumeDownload(title, pages, onProgress: (c, t) {
                                                  current = c;
                                                  setStateDialog(() {});
                                                }),
                                                child: const Text('استئناف'),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    );
                                  });
                                },
                              );

                              await DownloadService.downloadFullChapter(title, pages, onProgress: (c, t) {
                                current = c;
                                (context as Element).markNeedsBuild();
                              });

                              if (context.mounted) Navigator.pop(context);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم التنزيل!')));
                                setState(() {});
                              }
                            },
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () async {
                        final finalPages = isOffline ? await _getDownloadedPages(title, pages.length) : pages;
                        if (!context.mounted) return;
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ReaderScreen(pageUrls: finalPages, chapterTitle: title)));
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
