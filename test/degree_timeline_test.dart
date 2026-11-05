import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/models/degree_timeline.dart';

void main() {
  test(
    'Fall start rolls over to next Spring and counts semesters after current',
    () {
      const plan = DegreeTimeline(
        programYears: 2,
        startYear: 2027,
        startsInFall: true,
        currentSemester: 2,
      );
      expect(plan.semesterNames, [
        'Fall 2027',
        'Spring 2028',
        'Fall 2028',
        'Spring 2029',
      ]);
      expect(plan.semestersAfterCurrent, 2);
    },
  );
  test('Spring start and final semester work across program lengths', () {
    for (final years in [2, 4, 5]) {
      final plan = DegreeTimeline(
        programYears: years,
        startYear: 2027,
        startsInFall: false,
        currentSemester: years * 2,
      );
      expect(plan.semesterNames.length, years * 2);
      expect(plan.semesterNames.take(3), [
        'Spring 2027',
        'Fall 2027',
        'Spring 2028',
      ]);
      expect(plan.semesterNames.last, 'Fall ${2026 + years}');
      expect(plan.semestersAfterCurrent, 0);
    }
  });
}
