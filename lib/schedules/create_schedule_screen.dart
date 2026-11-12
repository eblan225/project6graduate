import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import 'schedule.dart';
import '../models/degree_timeline.dart';
import '../planner/course_plan.dart';

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
  late int semester;
  String filledCourses = '';

  String semesterCourses() {
    final plan = widget.coursePlan;
    if (plan == null) return '';
    return plan.courses
        .where(
          (c) =>
              plan.placements[c.id] == semester &&
              plan.status(c.id) != PlanStatus.completed,
        )
        .map((c) => '${plan.label(c)} — ${c.title}')
        .join('\n');
  }

  void selectSemester(int value) {
    final canRefresh = classes.text.isEmpty || classes.text == filledCourses;
    setState(() {
      semester = value;
      name.text = widget.timeline?.semesterLabel(value) ?? 'Semester $value';
      if (canRefresh) {
        filledCourses = semesterCourses();
        classes.text = filledCourses;
      }
    });
    if (!canRefresh) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your class edits were kept. Use map courses to load the selected semester.',
          ),
        ),
      );
    }
  }

  Future<void> useMapCourses() async {
    if (classes.text.isNotEmpty && classes.text != filledCourses) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace your class list?'),
          content: const Text(
            'Load courses from this semester of your degree map in place of the classes entered here.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Use map courses'),
            ),
          ],
        ),
      );
      if (!mounted || replace != true) return;
    }
    setState(() {
      filledCourses = semesterCourses();
      classes.text = filledCourses;
    });
  }

  @override
  void initState() {
    super.initState();
    final plan = widget.timeline;
    semester = plan?.currentSemester ?? 1;
    name.text = plan?.semesterLabel(semester) ?? 'Semester $semester';
    filledCourses = semesterCourses();
    classes.text = filledCourses;
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
            'Plan one semester at a time. Courses from your degree map are added below; adjust them or enter your own.',
          ),
          const SizedBox(height: 28),
          if (widget.timeline != null) ...[
            DropdownButtonFormField<String>(
              initialValue: widget.timeline!.semesterLabel(
                widget.timeline!.currentSemester,
              ),
              decoration: const InputDecoration(labelText: 'Semester'),
              isExpanded: true,
              items: widget.timeline!.semesterNames
                  .map(
                    (label) =>
                        DropdownMenuItem(value: label, child: Text(label)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectSemester(
                    widget.timeline!.semesterNames.indexOf(value) + 1,
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ] else if (widget.coursePlan != null) ...[
            DropdownButtonFormField<int>(
              initialValue: semester,
              decoration: const InputDecoration(labelText: 'Semester'),
              items: List.generate(
                widget.coursePlan!.placements.values.fold<int>(
                  1,
                  (a, b) => a > b ? a : b,
                ),
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Text('Semester ${i + 1}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) selectSemester(value);
              },
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
          if (widget.coursePlan != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Courses for this semester',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use the courses already placed in your degree map. Completed courses are left out. You can edit the list before creating this schedule.',
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: useMapCourses,
                      icon: const Icon(Icons.account_tree_outlined),
                      label: const Text('Use this semester’s map courses'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
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
