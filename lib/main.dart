import 'package:flutter/material.dart';

import 'planner/course_plan.dart';
import 'planner/course_map_screen.dart';
import 'schedules/schedule.dart';
import 'auth/sign_in_screen.dart';
import 'models/degree_timeline.dart';
import 'schedules/schedule_repository.dart';
import 'schedules/schedules_screen.dart';
import 'schedules/welcome_screen.dart';
import 'ui/app_theme.dart';

void main() => runApp(const TigerTrackApp());

class TigerTrackApp extends StatelessWidget {
  const TigerTrackApp({super.key, this.scheduleRepository});

  final ScheduleRepository? scheduleRepository;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Graduate!',
    debugShowCheckedModeBanner: false,
    theme: AppStyle.theme,
    home: AuthGate(child: _StartScreen(scheduleRepository: scheduleRepository)),
  );
}

class _StartScreen extends StatefulWidget {
  const _StartScreen({required this.scheduleRepository});

  final ScheduleRepository? scheduleRepository;

  @override
  State<_StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<_StartScreen> {
  int selected = 0;
  DegreeTimeline? timeline;
  final coursePlan = CoursePlan();
  final schedulesKey = GlobalKey<SchedulesScreenState>();
  @override
  void dispose() {
    coursePlan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: selected,
      children: [
        WelcomeScreen(
          onContinue: (value) => setState(() {
            timeline = value;
            selected = 1;
          }),
        ),
        SchedulesScreen(
          key: schedulesKey,
          timeline: timeline,
          coursePlan: coursePlan,
          repository: widget.scheduleRepository,
        ),
        CourseMapScreen(
          plan: coursePlan,
          timeline: timeline,
          onCreateSchedule: (SemesterSchedule schedule) {
            schedulesKey.currentState?.addFromTemplate(schedule);
          },
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: selected,
      onDestinationSelected: (value) => setState(() => selected = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.school_outlined),
          label: 'My goals',
        ),
        NavigationDestination(
          icon: Icon(Icons.calendar_month_outlined),
          label: 'Semesters',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_tree_outlined),
          label: 'Course map',
        ),
      ],
    ),
  );
}

String creditLabel(int credits) =>
    '$credits ${credits == 1 ? 'credit' : 'credits'}';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}
