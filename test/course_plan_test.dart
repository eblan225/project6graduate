import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/models/degree_timeline.dart';
import 'package:project6graduate/planner/course_plan.dart';
import 'package:project6graduate/planner/course_template.dart';

void main() {
  const timeline = DegreeTimeline(
    programYears: 4,
    startYear: 2027,
    startsInFall: true,
    currentSemester: 1,
  );
  test('blank reusable flowchart totals 127 credits with valid dependency endpoints', () {
    final plan = CoursePlan();
    expect(eecCourses.fold<int>(0, (s, c) => s + c.credits), 127);
    expect(eecCourses.map((c) => c.id).toSet().length, eecCourses.length);
    expect(plan.grades, isEmpty);
    expect(plan.statuses, isEmpty);
    for (final edge in eecLinks) {
      expect(plan.placements.containsKey(edge.from), isTrue);
      expect(plan.placements.containsKey(edge.to), isTrue);
    }
  });
  test('solid prerequisites require an earlier semester; co-requisites allow same semester', () {
    final plan = CoursePlan();
    plan.move('EE 2741', 3);
    expect(
      plan.warnings('EE 2742', timeline).any((v) => v.contains('EE 2741')),
      isTrue,
    );
    plan.move('EE 2741', 2);
    plan.move('CSC 1253', 3);
    expect(
      plan.warnings('EE 2742', timeline).any((v) => v.contains('CSC 1253')),
      isFalse,
    );
    plan.move('CSC 1253', 4);
    expect(
      plan.warnings('EE 2742', timeline).any((v) => v.contains('CSC 1253')),
      isTrue,
    );
  });
  test(
    'minimum C, season, senior standing and out-of-range checks react to moves',
    () {
      final plan = CoursePlan();
      plan.update('EE 2741', PlanStatus.completed, 'C-', null);
      expect(
        plan.warnings('EE 2742', timeline).any((v) => v.contains('grade')),
        isTrue,
      );
      plan.update('EE 2741', PlanStatus.completed, 'C', null);
      expect(
        plan.warnings('EE 2742', timeline).any((v) => v.contains('grade')),
        isFalse,
      );
      plan.move('EE 3755', 6);
      expect(
        plan.warnings('EE 3755', timeline).any((v) => v.contains('Fall only')),
        isTrue,
      );
      plan.move('EE 4810', 2);
      expect(
        plan.warnings('EE 4810', timeline).any((v) => v.contains('90 credits')),
        isTrue,
      );
      const short = DegreeTimeline(
        programYears: 2,
        startYear: 2027,
        startsInFall: true,
        currentSemester: 1,
      );
      expect(
        plan.warnings('EE 4820', short).any((v) => v.contains('Outside')),
        isTrue,
      );
      plan.reset();
      expect(plan.grades, isEmpty);
      expect(plan.placements['EE 4810'], 7);
    },
  );
}
