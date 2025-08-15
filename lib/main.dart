import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/chapter_list_screen.dart';
import 'services/notification_service.dart';
import 'services/download_service.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    final title = (inputData?['title'] ?? 'فصل').toString();
    final pages = List<String>.from(inputData?['pages'] ?? []);

    await DownloadService.downloadFullChapter(title, pages);
    await NotificationService.showNotification('📥 تم التحميل', "الفصل '$title' جاهز للقراءة");
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = prefs.getBool('darkMode') ?? false);
  }

  Future<void> _toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => isDarkMode = !isDarkMode);
    await prefs.setBool('darkMode', isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true),
      home: ChapterListScreen(onToggleTheme: _toggleTheme, isDarkMode: isDarkMode),
    );
  }
}
