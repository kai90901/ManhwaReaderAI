import 'package:flutter/material.dart';
import '../services/download_manager_service.dart';

class DownloadedChaptersScreen extends StatefulWidget {
  const DownloadedChaptersScreen({super.key});
  @override
  State<DownloadedChaptersScreen> createState() => _DownloadedChaptersScreenState();
}

class _DownloadedChaptersScreenState extends State<DownloadedChaptersScreen> {
  bool loading = true;
  List<Map<String, dynamic>> chapters = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    chapters = await DownloadManagerService.getDownloadedChapters();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الفصول المحمّلة')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : chapters.isEmpty
              ? const Center(child: Text('لا توجد فصول محمّلة'))
              : ListView.builder(
                  itemCount: chapters.length,
                  itemBuilder: (context, i) {
                    final c = chapters[i];
                    return ListTile(
                      title: Text(c['title']),
                      subtitle: Text('عدد الصفحات: ${c['pages']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await DownloadManagerService.deleteChapter(c['title']);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف ${c['title']}')));
                          _load();
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
