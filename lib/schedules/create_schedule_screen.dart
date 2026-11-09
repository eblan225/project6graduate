import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import 'schedule.dart';
import '../models/degree_timeline.dart';
import '../planner/course_plan.dart';
import '../importing/import_courses_screen.dart';

class CreateScheduleScreen extends StatefulWidget {
  const CreateScheduleScreen({super.key, this.timeline, this.coursePlan});
  final DegreeTimeline? timeline;
  final CoursePlan? coursePlan;
  @override
  State<CreateScheduleScreen> createState() => _CreateScheduleScreenState();
}

class _CreateScheduleScreenState extends State<CreateScheduleScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final classes = TextEditingController();
  @override
  void initState() {
    super.initState();
    final plan = widget.timeline;
    if (plan != null) name.text = plan.semesterLabel(plan.currentSemester);
  }

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
          if (widget.timeline != null) ...[
            DropdownButtonFormField<String>(
              initialValue: widget.timeline!.semesterLabel(
                widget.timeline!.currentSemester,
              ),
              decoration: const InputDecoration(labelText: 'Semester template'),
              isExpanded: true,
              items: widget.timeline!.semesterNames
                  .map(
                    (label) =>
                        DropdownMenuItem(value: label, child: Text(label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) name.text = value;
              },
            ),
            const SizedBox(height: 16),
          ] else ...[
            const Text(
              'Set your first semester in My goals to get semester templates.',
            ),
            const SizedBox(height: 16),
          ],
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(
                    Icons.upload_file_outlined,
                    color: AppStyle.purple,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text('Import courses from XLSX or PDF'),
                  const SizedBox(height: 8),
                  const Text(
                    'Review your file, then arrange courses in Course map. Grades and personal progress are excluded.',
                    textAlign: TextAlign.center,
                  ),
                  if (widget.coursePlan != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (_) =>
                              ImportCoursesScreen(plan: widget.coursePlan!),
                        ),
                      ),
                      child: const Text('Import XLSX / PDF'),
                    ),
                    TextButton(
                      onPressed: () {
                        final labels = widget.timeline?.semesterNames ?? [];
                        final index = labels.indexOf(name.text.trim());
                        if (index < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Choose a semester template first.',
                              ),
                            ),
                          );
                          return;
                        }
                        final plan = widget.coursePlan!;
                        final rows = plan.courses.where(
                          (c) =>
                              plan.placements[c.id] == index + 1 &&
                              plan.status(c.id) != PlanStatus.completed,
                        );
                        classes.text = rows
                            .map((c) => '${plan.label(c)} — ${c.title}')
                            .join('\n');
                      },
                      child: const Text('Use this semester’s map courses'),
                    ),
                  ],
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
              hintText: 'One class per line\nENGL 1001 / Mon 9:00 AM\nMATH 1021\n\nTimes are optional.',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Add at least one class' : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Separate a class name and time with /. This preview keeps times as notes.',
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
                    final parts = line.split('/');
                    return ScheduleClass(
                      name: parts.first.trim(),
                      time: parts.skip(1).join('/').trim(),
                    );
                  })
                  .toList();
              if (rows.any((row) => row.name.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Each line needs a class name before /.'),
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
