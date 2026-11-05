import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/main.dart';

void main() {
  testWidgets(
    'unconfigured Google sign-in offers guest preview and clears it on exit',
    (tester) async {
      await tester.pumpWidget(const TigerTrackApp());
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
    await tester.pumpWidget(const TigerTrackApp());
    await tester.tap(find.text('Explore without signing in'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Computer Science',
    );
    await tester.scrollUntilVisible(
      find.text('4-year program'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('4-year program'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2-year program').last);
    await tester.pumpAndSettle();
    expect(find.text('Semester 4 · End of year 2'), findsOneWidget);
    expect(find.text('Target term'), findsNothing);
    expect(find.text('Target year'), findsNothing);
    await tester.scrollUntilVisible(
      find.widgetWithText(TextFormField, 'First semester year'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'First semester year'),
      '2027',
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Current semester in your degree'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<int>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Semester 2 · Spring 2028').last);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Continue to schedules'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Continue to schedules'));
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
    await tester.tap(find.text('My goals'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('What is your major?'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Computer Science'), findsOneWidget);
  });
}
