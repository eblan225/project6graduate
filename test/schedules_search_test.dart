import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:project6graduate/schedules/schedule.dart';
import 'package:project6graduate/schedules/schedule_repository.dart';
import 'package:project6graduate/schedules/schedules_screen.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets(
    'search filters saved semesters without changing the saved list',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final repository = PreferencesScheduleRepository();
      await repository.save([
        SemesterSchedule(name: 'Spring 2027', classes: []),
        SemesterSchedule(name: 'Fall 2027', classes: []),
      ]);
      await tester.pumpWidget(
        MaterialApp(home: SchedulesScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      final search = find.widgetWithText(TextField, 'Search semesters');
      final clear = find.byTooltip('Clear semester search');
      final spring = find.text('Spring 2027');
      final fall = find.text('Fall 2027');
      expect(
        tester.getTopLeft(spring).dy,
        lessThan(tester.getTopLeft(fall).dy),
      );

      await tester.enterText(search, '  fAlL  ');
      await tester.pumpAndSettle();
      expect(spring, findsNothing);
      expect(fall, findsOneWidget);
      expect((await repository.load()).map((schedule) => schedule.name), [
        'Spring 2027',
        'Fall 2027',
      ]);

      await tester.tap(find.byTooltip('Schedule actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete semester'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('No matching semesters'), findsOneWidget);
      expect((await repository.load()).single.name, 'Spring 2027');

      await tester.tap(clear);
      await tester.pumpAndSettle();
      expect(spring, findsOneWidget);
      expect(fall, findsNothing);
      expect(search, findsNothing);
    },
  );
}
