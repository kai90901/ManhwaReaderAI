import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workmanager/workmanager.dart';

class ScheduleDownloadScreen extends StatefulWidget {
  const ScheduleDownloadScreen({super.key});
  @override
  State<ScheduleDownloadScreen> createState() => _ScheduleDownloadScreenState();
}

class _ScheduleDownloadScreenState extends State<ScheduleDownloadScreen> {
  TimeOfDay? selectedTime;
  final titleCtrl = TextEditingController(text: 'فصل 1');
  final pagesCtrl = TextEditingController(text: 'https://picsum.photos/seed/31/900/1400,https://picsum.photos/seed/32/900/1400');

  void _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (t != null) setState(() => selectedTime = t);
  }

  void _schedule() {
    if (selectedTime == null) return;
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, selectedTime!.hour, selectedTime!.minute);
    final delay = dt.isAfter(now) ? dt.difference(now) : dt.add(const Duration(days: 1)).difference(now);

    final pages = pagesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    Workmanager().registerOneOffTask(
      'scheduled_download_${titleCtrl.text}',
      'backgroundDownload',
      initialDelay: delay,
      inputData: {'title': titleCtrl.text, 'pages': pages},
    );

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('⏳ تم جدولة التحميل عند ${DateFormat.Hm().format(DateTime.now().add(delay))}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جدولة التحميل')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'عنوان الفصل')),
            const SizedBox(height: 8),
            TextField(controller: pagesCtrl, decoration: const InputDecoration(labelText: 'روابط الصفحات (مفصولة بفاصلة)')),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(onPressed: _pickTime, child: Text(selectedTime == null ? 'اختر الوقت' : selectedTime!.format(context))),
                const SizedBox(width: 12),
                ElevatedButton(onPressed: _schedule, child: const Text('جدولة')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
