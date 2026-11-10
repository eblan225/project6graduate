import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../planner/course_template.dart';

class ImportCourse {
  ImportCourse(
    this.id,
    this.title,
    this.credits,
    this.semester, {
    this.include = true,
    this.minimumC = false,
    this.offered,
  });
  String id, title;
  int? credits;
  int semester;
  bool include;
  final bool minimumC;
  final String? offered;
}

class CourseImport {
  CourseImport(
    this.courses,
    this.note, {
    this.supportedFlowchart = false,
    List<CourseLink>? links,
  }) : links = links ?? [];
  final List<ImportCourse> courses;
  final String note;
  final bool supportedFlowchart;
  final List<CourseLink> links;
}

final courseCodePattern = RegExp(r'\b([A-Z]{2,5})\s+(\d{4}[A-Z]?)\b');
TemplateCourse? knownCourse(String id) {
  for (final c in eecCourses) {
    if (c.id == id) return c;
  }
  return null;
}

CourseImport parseAcademicXlsx(Uint8List bytes) {
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  if (archive.files.fold<int>(0, (sum, f) => sum + f.size) > 20 * 1024 * 1024) {
    throw const FormatException('Workbook is too large after decompression.');
  }
  String? part(String path) {
    final f = archive.findFile(path);
    return f == null ? null : utf8.decode(f.content);
  }

  final shared = <String>[];
  final strings = part('xl/sharedStrings.xml');
  if (strings != null) {
    for (final si in XmlDocument.parse(strings).findAllElements('si')) {
      shared.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }
  final found = <String, ImportCourse>{};
  for (final file in archive.files.where(
    (f) => RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(f.name),
  )) {
    var courseColumn = '',
        creditsColumn = '',
        titleColumn = '',
        semesterColumn = '';
    for (final row in XmlDocument.parse(
      utf8.decode(file.content),
    ).findAllElements('row')) {
      final values = <String, String>{};
      for (final cell in row.findElements('c')) {
        final col = (cell.getAttribute('r') ?? '').replaceAll(
          RegExp(r'\d'),
          '',
        );
        final raw = cell.getElement('v')?.innerText ?? '';
        final value = cell.getAttribute('t') == 's'
            ? shared[int.parse(raw)]
            : cell.getAttribute('t') == 'inlineStr'
            ? cell.findAllElements('t').map((e) => e.innerText).join()
            : raw;
        values[col] = value.trim();
      }
      if (courseColumn.isEmpty) {
        for (final entry in values.entries) {
          final header = entry.value.toLowerCase();
          if ([
            'registrations used',
            'course',
            'course code',
            'course id',
          ].contains(header)) {
            courseColumn = entry.key;
          }
          if (['credit hours', 'credits'].contains(header)) {
            creditsColumn = entry.key;
          }
          if (['course title', 'title'].contains(header)) {
            titleColumn = entry.key;
          }
          if (['semester', 'semester number'].contains(header)) {
            semesterColumn = entry.key;
          }
        }
        continue;
      }
      // Read ONLY course identity, title, credits, and an optional ordinal semester.
      // Grade, Status, Academic Period, and other student fields are discarded.
      final raw = values[courseColumn] ?? '';
      final match = courseCodePattern.firstMatch(raw);
      if (match == null) continue;
      final id = '${match[1]} ${match[2]}';
      final known = knownCourse(id);
      final title = (values[titleColumn] ?? raw.substring(match.end))
          .replaceFirst(RegExp(r'^\s*[-–—]\s*'), '')
          .replaceAll(RegExp(r'\s*\([^)]*\)'), '')
          .trim();
      final number = num.tryParse(values[creditsColumn] ?? '');
      final credits = number != null && number == number.round()
          ? number.toInt()
          : null;
      final semester =
          int.tryParse(values[semesterColumn] ?? '') ?? known?.semester ?? 1;
      found.putIfAbsent(
        id,
        () => ImportCourse(
          id,
          title.isEmpty ? known?.title ?? id : title,
          credits,
          semester.clamp(1, 10),
        ),
      );
    }
  }
  if (found.isEmpty) {
    throw const FormatException(
      'No course rows found. Use Course / Course code / Registrations Used and Credits / Credit Hours columns.',
    );
  }
  return CourseImport(
    found.values.toList(),
    'Course names and credits only. Grades, completion status and academic periods are ignored. Repeated course codes are deduplicated. Verify credits and placement. XLSX files do not supply dependency arrows.',
  );
}

CourseImport parseCoursePdfText(String text) {
  final normalized = text.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
  final ids = courseCodePattern
      .allMatches(normalized)
      .map((m) => '${m[1]} ${m[2]}')
      .toSet();
  final required = eecCourses
      .where((c) => c.id.contains(' '))
      .map((c) => c.id)
      .toSet();
  final recognized =
      normalized.contains('COMPUTER ENGINEERING') &&
      normalized.contains('127') &&
      RegExp(r'2026\s*[-–]\s*(27|2027)').hasMatch(normalized) &&
      ids.containsAll(required);
  if (recognized) {
    return CourseImport(
      eecCourses
          .map((c) => ImportCourse(c.id, c.title, c.credits, c.semester))
          .toList(),
      'Recognized EEC 2026–27 flowchart. Courses, elective slots, semester placements and solid/dotted arrows use the matching built-in transcription. Review before applying. This is template matching, not general PDF arrow recognition.',
      supportedFlowchart: true,
      links: List.of(eecLinks),
    );
  }
  if (ids.isEmpty) {
    throw const FormatException(
      'No course codes found. Scanned/image-only PDFs need OCR, which is not supported yet.',
    );
  }
  return CourseImport(
    ids
        .map(
          (id) => ImportCourse(
            id,
            knownCourse(id)?.title ?? 'Imported course',
            null,
            knownCourse(id)?.semester ?? 1,
          ),
        )
        .toList(),
    'Course codes extracted from PDF text. Enter credit hours and confirm placement. Arbitrary PDF arrows and minimum grades cannot be read reliably and are not inferred.',
  );
}
