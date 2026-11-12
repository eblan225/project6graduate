import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/degree_planning/degree_plan.dart';

void main() {
  group('DegreePlanner', () {
    test('distributes credits through the target term without summer', () {
      final estimate = DegreePlanner.calculate(
        const DegreePlanInput(
          totalCreditsRequired: 120,
          completedCredits: 60,
          currentTermCredits: 15,
          currentTerm: AcademicTerm(2026, AcademicSeason.fall),
          targetTerm: AcademicTerm(2028, AcademicSeason.spring),
          includeSummer: false,
        ),
      );

      expect(estimate, isNotNull);
      expect(estimate!.futureCreditsNeeded, 45);
      expect(estimate.minimumCreditsPerTerm, 15);
      expect(estimate.termLoads.map((load) => load.term.label), [
        'Spring 2027',
        'Fall 2027',
        'Spring 2028',
      ]);
      expect(estimate.termLoads.map((load) => load.credits), [15, 15, 15]);
    });

    test('includes summer only when the student opts in', () {
      final estimate = DegreePlanner.calculate(
        const DegreePlanInput(
          totalCreditsRequired: 120,
          completedCredits: 60,
          currentTermCredits: 15,
          currentTerm: AcademicTerm(2026, AcademicSeason.fall),
          targetTerm: AcademicTerm(2028, AcademicSeason.spring),
          includeSummer: true,
        ),
      );

      expect(estimate!.termLoads.map((load) => load.term.label), [
        'Spring 2027',
        'Summer 2027',
        'Fall 2027',
        'Spring 2028',
      ]);
      expect(estimate.termLoads.map((load) => load.credits), [12, 11, 11, 11]);
    });

    test('uses fall as the next term when current term is summer and summer is off', () {
      final estimate = DegreePlanner.calculate(
        const DegreePlanInput(
          totalCreditsRequired: 120,
          completedCredits: 90,
          currentTermCredits: 0,
          currentTerm: AcademicTerm(2026, AcademicSeason.summer),
          targetTerm: AcademicTerm(2027, AcademicSeason.spring),
          includeSummer: false,
        ),
      );

      expect(estimate!.termLoads.map((load) => load.term.label), [
        'Fall 2026',
        'Spring 2027',
      ]);
      expect(estimate.termLoads.map((load) => load.credits), [15, 15]);
    });

    test('returns no estimate when target is not after current term', () {
      final estimate = DegreePlanner.calculate(
        const DegreePlanInput(
          totalCreditsRequired: 120,
          completedCredits: 30,
          currentTermCredits: 12,
          currentTerm: AcademicTerm(2026, AcademicSeason.fall),
          targetTerm: AcademicTerm(2026, AcademicSeason.fall),
          includeSummer: false,
        ),
      );

      expect(estimate, isNull);
    });

    test(
      'reports zero future credits when completed plus current reaches target',
      () {
        final estimate = DegreePlanner.calculate(
          const DegreePlanInput(
            totalCreditsRequired: 120,
            completedCredits: 115,
            currentTermCredits: 5,
            currentTerm: AcademicTerm(2026, AcademicSeason.fall),
            targetTerm: AcademicTerm(2027, AcademicSeason.spring),
            includeSummer: false,
          ),
        );

        expect(estimate!.futureCreditsNeeded, 0);
        expect(estimate.minimumCreditsPerTerm, 0);
        expect(estimate.termLoads.single.credits, 0);
      },
    );

    test('matches normalized course codes and reports unmet requirements', () {
      final estimate = DegreePlanner.calculate(
        const DegreePlanInput(
          totalCreditsRequired: 120,
          completedCredits: 60,
          currentTermCredits: 15,
          currentTerm: AcademicTerm(2026, AcademicSeason.fall),
          targetTerm: AcademicTerm(2027, AcademicSeason.spring),
          includeSummer: false,
          completedCourseCodes: [' math\t1550 ', 'ENGL 1001'],
          requiredCourseCodes: [
            'MATH 1550',
            'ENGL 1001',
            'BIOL   1201',
            'BIOL1201',
          ],
        ),
      );

      expect(estimate!.remainingCourseCodes, ['BIOL 1201']);
    });
  });
}
