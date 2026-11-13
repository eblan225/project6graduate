import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:project6graduate/schedules/schedule.dart';
import 'package:project6graduate/schedules/schedule_detail_screen.dart';

void main() {
  testWidgets('copies the current class list with optional meeting times', (
    tester,
  ) async {
    final messenger = tester.binding.defaultBinaryMessenger;
    MethodCall? copied;
    messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') copied = call;
      return null;
    });

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleDetailScreen(
          schedule: SemesterSchedule(
            name: 'Spring 2027',
            classes: [
              ScheduleClass(name: 'CSC 2259', time: 'Mon 9:00 AM'),
              ScheduleClass(name: 'MATH 1550'),
            ],
          ),
          onChanged: () async => fail('Copying should not change the schedule'),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Copy class list'));
    await tester.pumpAndSettle();

    expect(copied?.arguments, {
      'text': 'Spring 2027\n\n• CSC 2259 — Mon 9:00 AM\n• MATH 1550',
    });
    expect(find.text('Class list copied.'), findsOneWidget);
  });

  testWidgets('shows a message when the clipboard write fails', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard-unavailable');
        }
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleDetailScreen(
          schedule: SemesterSchedule(
            name: 'Spring 2027',
            classes: [ScheduleClass(name: 'CSC 2259')],
          ),
          onChanged: () async {},
        ),
      ),
    );
    await tester.tap(find.byTooltip('Copy class list'));
    await tester.pumpAndSettle();

    expect(find.text('Could not copy the class list.'), findsOneWidget);
  });

  testWidgets('hides the copy action when the schedule is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleDetailScreen(
          schedule: SemesterSchedule(name: 'Spring 2027', classes: []),
          onChanged: () async {},
        ),
      ),
    );

    expect(find.byTooltip('Copy class list'), findsNothing);
  });
}
