import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/main.dart';

void main() {
  testWidgets('create, edit, and reopen a semester schedule', (tester) async {
    await tester.pumpWidget(const TigerTrackApp());
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('A fresh start'), findsOneWidget);
    await tester.tap(find.text('New schedule'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Spring 2027');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'ENGL 1001 | Mon 9 AM\nMATH 1021',
    );
    await tester.scrollUntilVisible(
      find.text('Create schedule'),
      250,
      scrollable: find.byType(Scrollable).first,
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
  });
}
