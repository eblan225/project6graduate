import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import 'schedule.dart';
import '../models/degree_timeline.dart';
import '../planner/course_plan.dart';
import 'create_schedule_screen.dart';
import 'schedule_detail_screen.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key, this.timeline, this.coursePlan});
  final DegreeTimeline? timeline;
  final CoursePlan? coursePlan;
  @override
  State<SchedulesScreen> createState() => SchedulesScreenState();
}

class SchedulesScreenState extends State<SchedulesScreen> {
  final schedules = <SemesterSchedule>[];
  void addFromTemplate(SemesterSchedule schedule) =>
      setState(() => schedules.add(schedule));
  Future<void> open(SemesterSchedule schedule) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ScheduleDetailScreen(schedule: schedule),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> create() async {
    final result = await Navigator.push<SemesterSchedule>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateScheduleScreen(
          timeline: widget.timeline,
          coursePlan: widget.coursePlan,
        ),
      ),
    );
    if (!mounted || result == null) return;
    setState(() => schedules.add(result));
    await open(result);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Graduate!',
        style: TextStyle(color: AppStyle.purple, fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: 'About this preview',
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            showDragHandle: true,
            builder: (_) => const SafeArea(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About this preview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Schedules are saved only during this session. Persistent storage and file import are not connected yet.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'This is a student planning prototype, not an official LSU degree audit. No connection to Workday is made.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    body: AppPage(
      children: [
        const SizedBox(height: 16),
        const Text(
          'Your next chapter,\none semester at a time.',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'A home for your classes and the plans ahead.',
          style: TextStyle(color: Color(0xFF767085)),
        ),
        const SizedBox(height: 36),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Schedules', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${schedules.length} semesters',
              style: const TextStyle(color: Color(0xFF767085)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (schedules.isEmpty)
          const EmptyPanel(
            icon: Icons.event_note_outlined,
            title: 'A fresh start',
            message: 'No schedules yet. Create your first semester and start adding classes.',
          ),
        for (final schedule in schedules)
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: const Icon(
                Icons.calendar_month_outlined,
                color: AppStyle.purple,
              ),
              title: Text(schedule.name),
              subtitle: Text('${schedule.classes.length} classes'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => open(schedule),
            ),
          ),
        const SizedBox(height: 16),
        const Text(
          'Session preview • Changes reset when the app restarts.',
          style: TextStyle(fontSize: 12, color: Color(0xFF767085)),
        ),
        const SizedBox(height: 96),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: create,
      icon: const Icon(Icons.edit_outlined),
      label: const Text('New schedule'),
    ),
  );
}
