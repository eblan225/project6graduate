import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import 'schedule.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key});
  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final classes = TextEditingController();
  @override
  void dispose() {
    name.dispose();
    classes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('New schedule')),
    body: Form(
      key: form,
      child: AppPage(
        children: [
          const Text(
            'Make room for what’s next.',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start with a semester and a few classes. You can add details later.',
          ),
          const SizedBox(height: 28),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Semester name',
              hintText: 'e.g. Spring 2027',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a semester name' : null,
          ),
          const SizedBox(height: 20),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.upload_file_outlined,
                    color: AppStyle.purple,
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text('Upload a schedule'),
                  SizedBox(height: 8),
                  Text(
                    'File import is coming later. Use manual entry below.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: classes,
            minLines: 6,
            maxLines: 12,
            decoration: const InputDecoration(
              labelText: 'Your classes',
              alignLabelWithHint: true,
              hintText: 'One class per line\nENGL 1001 | Mon 9:00 AM\nMATH 1021\n\nTimes are optional.',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Add at least one class' : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Separate a class name and time with |. This preview keeps times as notes.',
            style: TextStyle(color: Color(0xFF767085)),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final rows = classes.text
                  .split('\n')
                  .where((v) => v.trim().isNotEmpty)
                  .map((line) {
                    final parts = line.split('|');
                    return ScheduleClass(
                      name: parts.first.trim(),
                      time: parts.skip(1).join('|').trim(),
                    );
                  })
                  .toList();
              if (rows.any((row) => row.name.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Each line needs a class name before |.'),
                  ),
                );
                return;
              }
              Navigator.pop(
                context,
                SemesterSchedule(name: name.text.trim(), classes: rows),
              );
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Create schedule'),
          ),
        ],
      ),
    ),
  );
}
