import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/main.dart';
import 'package:project6graduate/planner/course_plan.dart';
import 'package:project6graduate/planner/course_template.dart';
import 'package:project6graduate/schedules/create_schedule_screen.dart';
import 'package:project6graduate/models/degree_timeline.dart';
import 'package:project6graduate/schedules/schedule.dart';
import 'package:project6graduate/schedules/schedule_repository.dart';
import 'package:project6graduate/schedules/schedules_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('degree upload comes before empty semester schedules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final plan = CoursePlan();
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulesScreen(
          repository: MemoryScheduleRepository(),
          coursePlan: plan,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.text('Your degree path')).dy,
      lessThan(tester.getTopLeft(find.text('Semester schedules')).dy),
    );
    await tester.tap(find.text('Upload degree flowchart'));
    await tester.pumpAndSettle();
    expect(find.text('Choose XLSX or PDF'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Your degree path'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    plan.dispose();
  });

  testWidgets(
    'one semester loads existing map courses and protects manual edits',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final plan = CoursePlan();
      plan.importCourses(
        [
          const TemplateCourse('TEST 1001', 'First term', 3, 1),
          const TemplateCourse('TEST 1002', 'Already completed', 3, 1),
          const TemplateCourse('TEST 2001', 'Second term', 3, 2),
        ],
        [],
        merge: false,
      );
      plan.update('TEST 1002', PlanStatus.completed, 'A', null);
      await tester.pumpWidget(
        MaterialApp(home: CreateScheduleScreen(coursePlan: plan)),
      );
      final field = find.widgetWithText(TextFormField, 'Your classes');
      String classes() => tester.widget<TextFormField>(field).controller!.text;
      expect(classes(), 'TEST 1001 — First term');
      expect(find.text('Import XLSX / PDF'), findsNothing);
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 2').last);
      await tester.pumpAndSettle();
      expect(classes(), 'TEST 2001 — Second term');
      await tester.ensureVisible(field);
      await tester.enterText(field, 'MY 1234 / Tue 10 AM');
      await tester.ensureVisible(find.byType(DropdownButtonFormField<int>));
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Semester 1').last);
      await tester.pumpAndSettle();
      expect(classes(), 'MY 1234 / Tue 10 AM');
      await tester.ensureVisible(find.text('Use this semester’s map courses'));
      await tester.tap(find.text('Use this semester’s map courses'));
      await tester.pumpAndSettle();
      expect(find.text('Replace your class list?'), findsOneWidget);
      await tester.tap(find.text('Use map courses'));
      await tester.pumpAndSettle();
      expect(classes(), 'TEST 1001 — First term');
      await tester.pumpWidget(const SizedBox.shrink());
      plan.dispose();
    },
  );

  testWidgets('course map templates are saved and survive reopening', (
    tester,
  ) async {
    final repository = MemoryScheduleRepository();
    final key = GlobalKey<SchedulesScreenState>();
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulesScreen(key: key, repository: repository),
      ),
    );
    await tester.pumpAndSettle();
    await key.currentState!.addFromTemplate(
      SemesterSchedule(
        name: 'Fall 2027',
        classes: [ScheduleClass(name: 'MATH 1550')],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fall 2027'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      MaterialApp(home: SchedulesScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fall 2027'));
    await tester.pumpAndSettle();
    expect(find.text('MATH 1550'), findsOneWidget);
  });

  testWidgets(
    'unconfigured Google sign-in offers guest preview and clears it on exit',
    (tester) async {
      await tester.pumpWidget(
        TigerTrackApp(scheduleRepository: MemoryScheduleRepository()),
      );
      final button = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Sign in with Google'),
      );
      expect(button.onPressed, isNull);
      await tester.tap(find.text('Explore without signing in'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Physics');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Explore without signing in'), findsOneWidget);
      await tester.tap(find.text('Explore without signing in'));
      await tester.pumpAndSettle();
      expect(find.text('Physics'), findsNothing);
    },
  );

  testWidgets('create, edit, and reopen a semester schedule', (tester) async {
    final repository = MemoryScheduleRepository();
    const timeline = DegreeTimeline(
      programYears: 4,
      startYear: 2027,
      startsInFall: true,
      currentSemester: 2,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulesScreen(repository: repository, timeline: timeline),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A fresh start'), findsOneWidget);
    await tester.tap(find.text('New schedule'));
    await tester.pumpAndSettle();
    expect(find.text('Spring 2028'), findsWidgets);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fall 2028').last);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Fall 2028',
    );
    await tester.enterText(find.byType(TextFormField).first, 'Spring 2027');
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'Your classes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Your classes'),
      'ENGL 1001 / Mon 9 AM\nMATH 1021',
    );
    await tester.scrollUntilVisible(
      find.text('Create schedule'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Create schedule'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create schedule'));
    await tester.pumpAndSettle();
    expect(find.text('ENGL 1001'), findsOneWidget);
    expect(find.text('Time not added'), findsOneWidget);
    await tester.tap(find.text('MATH 1021'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Tue 10 AM');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Tue 10 AM'), findsOneWidget);
    await tester.tap(find.text('Calendar'));
    await tester.pumpAndSettle();
    expect(find.text('Your week starts here'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Spring 2027'));
    await tester.pumpAndSettle();
    expect(find.text('Tue 10 AM'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      MaterialApp(
        home: SchedulesScreen(repository: repository, timeline: timeline),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Spring 2027'), findsOneWidget);
  });
}

class MemoryScheduleRepository implements ScheduleRepository {
  List<SemesterSchedule> saved = [];

  @override
  Future<List<SemesterSchedule>> load() async => saved
      .map((schedule) => SemesterSchedule.fromJson(schedule.toJson()))
      .toList();

  @override
  Future<void> save(List<SemesterSchedule> schedules) async {
    saved = schedules
        .map((schedule) => SemesterSchedule.fromJson(schedule.toJson()))
        .toList();
  }
}
