import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/models/degree_timeline.dart';
import 'package:project6graduate/planner/course_plan.dart';
import 'package:project6graduate/planner/course_map_screen.dart';
import 'package:project6graduate/schedules/schedule.dart';
import 'package:project6graduate/ui/app_theme.dart';

void main() {
  testWidgets('opens the course editor from a planning warning', (
    tester,
  ) async {
    final plan = CoursePlan()
      ..update('CHEM 1201', PlanStatus.completed, '', null);
    addTearDown(plan.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppStyle.theme,
        home: CourseMapScreen(plan: plan, onCreateSchedule: (_) {}),
      ),
    );
    await tester.tap(find.textContaining('Review ('));
    await tester.pumpAndSettle();

    final warning = find.widgetWithText(ListTile, 'CHEM 1201');
    await tester.tap(warning);
    await tester.pumpAndSettle();

    expect(find.text('Planning review'), findsNothing);
    expect(find.textContaining('CHEM 1201 ·'), findsOneWidget);
    expect(find.text('Save course'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets(
    'course map moves a course and creates a separate semester schedule',
    (tester) async {
      final plan = CoursePlan();
      SemesterSchedule? created;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppStyle.theme,
          home: CourseMapScreen(
            plan: plan,
            timeline: const DegreeTimeline(
              programYears: 4,
              startYear: 2027,
              startsInFall: true,
              currentSemester: 1,
            ),
            onCreateSchedule: (schedule) => created = schedule,
          ),
        ),
      );
      await tester.tap(find.text('CHEM 1201'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Spring 2028').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save course'));
      await tester.pumpAndSettle();
      expect(plan.placements['CHEM 1201'], 2);
      await tester.tap(find.text('Make schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Create schedule'));
      await tester.pumpAndSettle();
      expect(created!.name, 'Fall 2027');
      expect(
        created!.classes.any((c) => c.name.startsWith('CHEM 1201')),
        isFalse,
      );
      expect(
        created!.classes.any((c) => c.name.startsWith('MATH 1550')),
        isTrue,
      );
      plan.move('MATH 1550', 2);
      expect(
        created!.classes.any((c) => c.name.startsWith('MATH 1550')),
        isTrue,
      );
    },
  );
}
