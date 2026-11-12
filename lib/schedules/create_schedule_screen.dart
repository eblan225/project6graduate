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
  static final meetingTime = RegExp(
    r'\b(?:(?:[01]?\d|2[0-3]):[0-5]\d|(?:0?[1-9]|1[0-2])\s*(?:am|pm))\b',
    caseSensitive: false,
  );

  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final classes = TextEditingController();
  late int semester;
  List<String> mapCourseNames = [];

  String get filledCourses => mapCourseNames.join('\n');

  void fillFromMap() {
    final plan = widget.coursePlan;
    mapCourseNames = plan == null
        ? []
        : plan.courses
              .where(
                (c) =>
                    plan.placements[c.id] == semester &&
                    plan.status(c.id) != PlanStatus.completed,
              )
              .map((c) => '${plan.label(c)} — ${c.title}')
              .map((name) => name.trim())
              .toList();
    classes.text = filledCourses;
  }

  ScheduleClass parseClass(String line) {
    final title = line.trim();
    if (mapCourseNames.contains(title)) return ScheduleClass(name: title);

    // A known course title can itself contain @ followed by a clock time.
    var courseNameLength = 0;
    for (final name in mapCourseNames) {
      if (name.length > courseNameLength &&
          title.startsWith(name) &&
          title.substring(name.length).trimLeft().startsWith('@')) {
        courseNameLength = name.length;
      }
    }
    final courseName = title.substring(0, courseNameLength);
    final parts = title.substring(courseNameLength).split('@');
    for (var i = 1; i < parts.length; i++) {
      if (meetingTime.hasMatch(parts[i])) {
        return ScheduleClass(
          name: '$courseName${parts.take(i).join('@')}'.trim(),
          time: parts.skip(i).join('@').trim(),
        );
      }
    }
    return ScheduleClass(name: title);
  }

  void selectSemester(int value) {
    final canRefresh = classes.text.isEmpty || classes.text == filledCourses;
    setState(() {
      semester = value;
      name.text = widget.timeline?.semesterLabel(value) ?? 'Semester $value';
      if (canRefresh) {
        fillFromMap();
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
    setState(fillFromMap);
  }

  @override
  void initState() {
    super.initState();
    final plan = widget.timeline;
    semester = plan?.currentSemester ?? 1;
    name.text = plan?.semesterLabel(semester) ?? 'Semester $semester';
    fillFromMap();
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
              hintText:
                  'One class per line\nENGL 1001 @ Mon 9:00 AM\nMATH 1021',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Add at least one class' : null,
          ),
          const SizedBox(height: 12),
          const Text(
            'Meeting times are optional. Use @ before a time such as 9 AM or 14:30. A room by itself stays with the class name.',
            style: TextStyle(color: Color(0xFF767085)),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: () {
              if (!form.currentState!.validate()) return;
              final rows = classes.text
                  .split('\n')
                  .where((v) => v.trim().isNotEmpty)
                  .map(parseClass)
                  .toList();
              if (rows.any((row) => row.name.isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Each line needs a class name before the meeting time.',
                    ),
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
