import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_selector/file_selector.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/importing/course_import.dart';
import 'package:project6graduate/importing/import_courses_screen.dart';
import 'package:project6graduate/planner/course_plan.dart';
import 'package:project6graduate/planner/course_template.dart';

Uint8List sampleWorkbook() {
  final archive = Archive();
  final xml = '''<worksheet><sheetData>
    <row><c r="A1" t="inlineStr"><is><t>Registrations Used</t></is></c><c r="B1" t="inlineStr"><is><t>Credit Hours</t></is></c><c r="C1" t="inlineStr"><is><t>Grade</t></is></c><c r="D1" t="inlineStr"><is><t>Status</t></is></c></row>
    <row><c r="A2" t="inlineStr"><is><t>TEST 1234 - Example Course (In Progress)</t></is></c><c r="B2"><v>3</v></c><c r="C2" t="inlineStr"><is><t>SYNTHETIC PRIVATE VALUE</t></is></c><c r="D2" t="inlineStr"><is><t>Satisfied</t></is></c></row>
    <row><c r="A3" t="inlineStr"><is><t>TEST 1234 - Example Course</t></is></c><c r="B3"><v>3</v></c></row>
    </sheetData></worksheet>''';
  final data = utf8.encode(xml);
  archive.addFile(ArchiveFile('xl/worksheets/sheet1.xml', data.length, data));
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  testWidgets('picker failure is distinct from file parsing and allows retry', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ImportCoursesScreen(
          plan: CoursePlan(),
          pickFile: () async {
            calls++;
            if (calls == 1) throw MissingPluginException('not registered');
            return null;
          },
        ),
      ),
    );
    await tester.tap(find.text('Choose XLSX or PDF'));
    await tester.pumpAndSettle();
    expect(find.textContaining('file picker is not loaded'), findsOneWidget);
    expect(find.textContaining('Could not read'), findsNothing);
    await tester.tap(find.text('Choose XLSX or PDF'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.textContaining('file picker is not loaded'), findsNothing);
  });

  test('XLSX imports course structure, deduplicates, and ignores grade/status fields', () {
    final result = parseAcademicXlsx(sampleWorkbook());
    expect(result.courses.length, 1);
    expect(result.courses.single.title, 'Example Course');
    expect(result.courses.single.credits, 3);
    final plan = CoursePlan();
    final row = result.courses.single;
    plan.importCourses(
      [TemplateCourse(row.id, row.title, row.credits!, row.semester)],
      [],
      merge: false,
    );
    expect(plan.courses.single.id, 'TEST 1234');
    expect(plan.grades, isEmpty);
    expect(plan.statuses, isEmpty);
    expect(plan.links, isEmpty);
    expect(plan.warnings('TEST 1234', null), isEmpty);
  });
  test('PDF recognition requires full supported chart; unknown PDFs require credit review', () {
    final full =
        'COMPUTER ENGINEERING 2026-27 TOTAL HOURS 127 ${eecCourses.map((c) => c.id).join(' ')}';
    expect(parseCoursePdfText(full).supportedFlowchart, isTrue);
    final generic = parseCoursePdfText('Course list ABC 1234 and XYZ 5678');
    expect(generic.supportedFlowchart, isFalse);
    expect(generic.courses.every((c) => c.credits == null), isTrue);
    expect(() => parseCoursePdfText('scanned image'), throwsFormatException);
    expect(
      () => parseAcademicXlsx(Uint8List.fromList([1, 2, 3])),
      throwsA(anything),
    );
  });
  testWidgets('picker review applies courses only after confirmation', (
    tester,
  ) async {
    final plan = CoursePlan();
    await tester.pumpWidget(
      MaterialApp(
        home: ImportCoursesScreen(
          plan: plan,
          pickFile: () async => XFile.fromData(
            sampleWorkbook(),
            name: 'sample.xlsx',
            path: 'sample.xlsx',
          ),
        ),
      ),
    );
    await tester.tap(find.text('Choose XLSX or PDF'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('TEST 1234'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('TEST 1234'), findsOneWidget);
    expect(plan.courses.any((c) => c.id == 'TEST 1234'), isFalse);
    await tester.scrollUntilVisible(
      find.text('Apply reviewed import'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Apply reviewed import'),
    );
    await tester.tap(find.text('Apply reviewed import'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply import'));
    await tester.pumpAndSettle();
    expect(plan.courses.any((c) => c.id == 'TEST 1234'), isTrue);
    expect(plan.grades, isEmpty);
  });
}
