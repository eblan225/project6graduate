import 'package:material_ui/material_ui.dart';

import '../degree_planning/degree_plan_screen.dart';
import '../importing/import_courses_screen.dart';
import '../planner/course_map_screen.dart';
import '../ui/app_theme.dart';
import 'schedule.dart';
import '../models/degree_timeline.dart';
import '../planner/course_plan.dart';
import 'create_schedule_screen.dart';
import 'schedule_detail_screen.dart';
import 'schedule_repository.dart';

class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({
    super.key,
    this.repository,
    this.timeline,
    this.coursePlan,
    this.onOpenCourseMap,
  });
  final ScheduleRepository? repository;
  final DegreeTimeline? timeline;
  final CoursePlan? coursePlan;
  final VoidCallback? onOpenCourseMap;
  @override
  State<SchedulesScreen> createState() => SchedulesScreenState();
}

class SchedulesScreenState extends State<SchedulesScreen> {
  late final ScheduleRepository repository;
  final schedules = <SemesterSchedule>[];

  bool loading = true;
  String? loadError;

  @override
  void initState() {
    super.initState();
    repository = widget.repository ?? PreferencesScheduleRepository();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      loadError = null;
    });
    try {
      final saved = await repository.load();
      if (!mounted) return;
      setState(() {
        schedules
          ..clear()
          ..addAll(saved);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loadError = 'Saved schedules could not be loaded. Your saved data was left untouched.';
      });
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _persist() async {
    try {
      await repository.save(schedules);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not save changes on this device.')),
      );
    }
  }

  Future<void> addFromTemplate(SemesterSchedule schedule) async {
    if (loading || loadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Load your schedules before adding a semester.'),
        ),
      );
      return;
    }
    setState(() => schedules.add(schedule));
    await _persist();
  }

  Future<void> open(SemesterSchedule schedule) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ScheduleDetailScreen(schedule: schedule, onChanged: _persist),
      ),
    );
    if (!mounted) return;
    setState(() {});
    await _persist();
  }

  Future<void> uploadDegreePath() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ImportCoursesScreen(plan: widget.coursePlan!, initialMerge: false),
      ),
    );
    if (mounted) setState(() {});
  }

  void openDegreePath() {
    if (widget.onOpenCourseMap != null) {
      widget.onOpenCourseMap!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CourseMapScreen(
          plan: widget.coursePlan!,
          timeline: widget.timeline,
          onCreateSchedule: addFromTemplate,
        ),
      ),
    );
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
    await _persist();
    await open(result);
  }

  Future<void> removeSchedule(int index) async {
    final schedule = schedules[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete semester?'),
        content: Text('Delete ${schedule.name} and all its classes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    setState(() => schedules.removeAt(index));
    await _persist();
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
          tooltip: 'Degree credit planner',
          icon: const Icon(Icons.school_outlined),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const DegreePlanScreen()),
          ),
        ),
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
                      'Schedules are stored on this device. Account sync is not connected yet. Upload your degree flowchart above your semester schedules.',
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
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : loadError != null
        ? AppPage(
            children: [
              const SizedBox(height: 48),
              const EmptyPanel(
                icon: Icons.storage_outlined,
                title: 'Could not load schedules',
                message: 'Your saved schedule data has not been changed.',
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          )
        : AppPage(
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
              const SizedBox(height: 28),
              if (widget.coursePlan != null) ...[
                ListenableBuilder(
                  listenable: widget.coursePlan!,
                  builder: (context, _) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.account_tree_outlined,
                            color: AppStyle.purple,
                            size: 32,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your degree path',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Start with your full degree flowchart, then build a schedule for each semester.',
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.coursePlan!.hasImportedCourses
                                ? '${widget.coursePlan!.courses.length} courses and requirements in your degree map'
                                : 'A Computer Engineering example is available. Upload your flowchart to use your own degree path.',
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              FilledButton.icon(
                                onPressed: uploadDegreePath,
                                icon: const Icon(Icons.upload_file_outlined),
                                label: const Text('Upload degree flowchart'),
                              ),
                              OutlinedButton.icon(
                                onPressed: openDegreePath,
                                icon: const Icon(Icons.account_tree_outlined),
                                label: const Text('View degree map'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Your degree map stays in this session.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF767085),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Semester schedules',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${schedules.length} ${schedules.length == 1 ? 'semester' : 'semesters'}',
                    style: const TextStyle(color: Color(0xFF767085)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (schedules.isEmpty)
                const EmptyPanel(
                  icon: Icons.event_note_outlined,
                  title: 'A fresh start',
                  message: 'No semester schedules yet. Start with your degree path above, then create one semester using its map courses or your own class list.',
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
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Schedule actions',
                      onSelected: (action) {
                        if (action == 'delete') {
                          removeSchedule(schedules.indexOf(schedule));
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete semester'),
                        ),
                      ],
                    ),
                    onTap: () => open(schedule),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Saved on this device • No account or cloud sync.',
                style: TextStyle(fontSize: 12, color: Color(0xFF767085)),
              ),
              const SizedBox(height: 96),
            ],
          ),
    floatingActionButton: loading || loadError != null
        ? null
        : FloatingActionButton.extended(
            onPressed: create,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('New schedule'),
          ),
  );
}
