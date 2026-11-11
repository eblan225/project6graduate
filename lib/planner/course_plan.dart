import 'package:flutter/foundation.dart';

import '../models/degree_timeline.dart';
import 'course_template.dart';

enum PlanStatus { planned, inProgress, completed }

class CoursePlan extends ChangeNotifier {
  List<TemplateCourse> courses = List.of(eecCourses);
  List<CourseLink> links = List.of(eecLinks);
  bool usesEecRules = true;
  bool hasImportedCourses = false;
  String title = 'Computer Engineering · 2026–27';

  void importCourses(
    List<TemplateCourse> incoming,
    List<CourseLink> incomingLinks, {
    required bool merge,
  }) {
    hasImportedCourses = true;
    if (!merge) {
      courses = [];
      links = [];
      placements.clear();
      statuses.clear();
      grades.clear();
      selections.clear();
      usesEecRules = incomingLinks.isNotEmpty;
      title = usesEecRules
          ? 'Computer Engineering · 2026–27'
          : 'Imported course template';
    }
    final existing = courses.map((c) => c.id).toSet();
    courses = [...courses, ...incoming.where((c) => !existing.contains(c.id))];
    for (final c in incoming) {
      placements.putIfAbsent(c.id, () => c.semester);
    }
    links = [...links];
    for (final link in incomingLinks) {
      if (!links.any(
        (l) =>
            l.from == link.from &&
            l.to == link.to &&
            l.concurrent == link.concurrent,
      )) {
        links.add(link);
      }
    }
    notifyListeners();
  }

  void setDependencies(String id, List<CourseLink> incoming) {
    links = [...links.where((l) => l.to != id), ...incoming];
    notifyListeners();
  }

  final placements = {for (final c in eecCourses) c.id: c.semester};
  final statuses = <String, PlanStatus>{};
  final grades = <String, String>{};
  final selections = <String, String>{};
  PlanStatus status(String id) => statuses[id] ?? PlanStatus.planned;
  String label(TemplateCourse c) => (selections[c.id] ?? '').trim().isNotEmpty
      ? selections[c.id]!
      : courseDisplayId(c.id);
  bool get hasEdits =>
      statuses.isNotEmpty ||
      grades.isNotEmpty ||
      selections.isNotEmpty ||
      courses.any((c) => placements[c.id] != c.semester);
  void move(String id, int semester) {
    placements[id] = semester;
    notifyListeners();
  }

  void update(String id, PlanStatus status, String grade, String? choice) {
    statuses[id] = status;
    grades[id] = grade.trim().toUpperCase();
    if (choice == null || choice.isEmpty) {
      selections.remove(id);
    } else {
      selections[id] = choice;
    }
    notifyListeners();
  }

  void reset() {
    placements.clear();
    placements.addAll({for (final c in courses) c.id: c.semester});
    statuses.clear();
    grades.clear();
    selections.clear();
    notifyListeners();
  }

  bool meetsGrade(String id, {bool minimumC = true}) {
    final grade = grades[id] ?? '';
    return (minimumC
            ? const ['A+', 'A', 'A-', 'B+', 'B', 'B-', 'C+', 'C']
            : const [
                'A+',
                'A',
                'A-',
                'B+',
                'B',
                'B-',
                'C+',
                'C',
                'C-',
                'D+',
                'D',
                'D-',
              ])
        .contains(grade);
  }

  List<String> warnings(String id, DegreeTimeline? timeline) {
    final course = courses.firstWhere((c) => c.id == id);
    final semester = placements[id]!;
    final issues = <String>[];
    if (!course.id.contains(' ') && (selections[id] ?? '').trim().isEmpty) {
      issues.add(
        'Choose a course for this elective slot and confirm eligibility.',
      );
    }
    if (status(id) == PlanStatus.completed) {
      if (!meetsGrade(id, minimumC: course.minimumC)) {
        issues.add(
          'Completion grade needs review${course.minimumC ? ': minimum C required' : ''}. Transfer/pass credit must be confirmed separately.',
        );
      }
      return issues;
    }
    if (timeline != null && semester > timeline.totalSemesters) {
      issues.add(
        'Outside your selected degree timeline. Move this course to a semester in your plan.',
      );
    }
    if (timeline != null && semester < timeline.currentSemester) {
      issues.add(
        'Before your current semester; update progress or move this course.',
      );
    }
    String? offered = course.offered;
    final choice = selections[id] ?? '';
    if (choice.startsWith('EE 3160') || choice.startsWith('EE 3530')) {
      offered = 'Fall';
    }
    if (choice.startsWith('EE 3220')) offered = 'Spring';
    if (timeline != null &&
        offered != null &&
        !timeline.semesterLabel(semester).startsWith(offered)) {
      issues.add('$offered only in the supplied flowchart.');
    }
    for (final link in links.where((l) => l.to == id)) {
      final before = placements[link.from]!;
      if (status(link.from) == PlanStatus.completed) {
        final source = courses.firstWhere((c) => c.id == link.from);
        final needsC = source.minimumC || id.startsWith('EE ');
        if (!meetsGrade(link.from, minimumC: needsC)) {
          issues.add(
            '${courseDisplayId(link.from)}: completed grade must ${needsC ? 'meet C' : 'be passing'} or be reviewed before counting this dependency.',
          );
        }
      } else if (link.concurrent ? before > semester : before >= semester) {
        issues.add(
          '${courseDisplayId(link.from)} must be ${link.concurrent ? 'before or in the same semester' : 'in an earlier semester'}.',
        );
      }
    }
    if (usesEecRules &&
        id == 'EE 4810' &&
        placements.containsKey('BREADTH') &&
        placements.containsKey('EE 3755')) {
      final prior = courses
          .where(
            (c) =>
                (status(c.id) == PlanStatus.completed &&
                    meetsGrade(c.id, minimumC: c.minimumC)) ||
                (status(c.id) != PlanStatus.completed &&
                    placements[c.id]! < semester),
          )
          .fold<int>(0, (s, c) => s + c.credits);
      if (prior < 90) {
        issues.add(
          'Senior standing: at least 90 credits before Senior Design I ($prior in this draft).',
        );
      }
      final breadthBefore =
          (status('BREADTH') == PlanStatus.completed
              ? meetsGrade('BREADTH')
              : placements['BREADTH']! < semester) &&
          [
            'EE 3160',
            'EE 3220',
            'EE 3410',
            'EE 3530',
          ].any((selections['BREADTH'] ?? '').startsWith);
      final orgBefore = status('EE 3755') == PlanStatus.completed
          ? meetsGrade('EE 3755')
          : placements['EE 3755']! < semester;
      if (!orgBefore && !breadthBefore) {
        issues.add(
          'Also requires one of EE 3160, 3220, 3410, 3530, or 3755 beforehand.',
        );
      }
    }
    return issues;
  }
}
