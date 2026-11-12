import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/degree_planning/degree_plan.dart';
import 'package:project6graduate/degree_planning/degree_plan_repository.dart';
import 'package:project6graduate/degree_planning/degree_plan_screen.dart';

void main() {
  testWidgets('shows and saves a future-term credit estimate', (tester) async {
    final repository = MemoryDegreePlanRepository(
      const DegreePlanInput(
        totalCreditsRequired: 120,
        completedCredits: 60,
        currentTermCredits: 15,
        currentTerm: AcademicTerm(2026, AcademicSeason.fall),
        targetTerm: AcademicTerm(2028, AcademicSeason.spring),
        includeSummer: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: DegreePlanScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
    await tester.dragUntilVisible(
      find.text('45 credits left after this term'),
      find.byType(ListView),
      const Offset(0, -500),
    );

    expect(find.text('45 credits left after this term'), findsOneWidget);
    expect(
      find.text('Plan for about 15 credits per future term across 3 terms.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Calculate and save'));
    await tester.tap(find.text('Calculate and save'));
    await tester.pumpAndSettle();
    expect(repository.saved?.completedCredits, 60);
    expect(
      repository.saved?.targetTerm,
      const AcademicTerm(2028, AcademicSeason.spring),
    );
  });

  testWidgets('matches course codes entered with or without a space', (
    tester,
  ) async {
    final repository = MemoryDegreePlanRepository(
      const DegreePlanInput(
        totalCreditsRequired: 120,
        completedCredits: 60,
        currentTermCredits: 15,
        currentTerm: AcademicTerm(2026, AcademicSeason.fall),
        targetTerm: AcademicTerm(2027, AcademicSeason.spring),
        includeSummer: false,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: DegreePlanScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.ensureVisible(fields.at(3));
    await tester.enterText(fields.at(3), 'CSC1350');
    await tester.ensureVisible(fields.at(4));
    await tester.enterText(fields.at(4), 'CSC 1350\nCSC 2259');

    final calculate = find.text('Calculate and save');
    await tester.dragUntilVisible(
      calculate,
      find.byType(ListView),
      const Offset(0, -400),
    );
    await tester.tap(calculate);
    await tester.pumpAndSettle();

    final outstandingCourses = find.byWidgetPredicate(
      (widget) =>
          widget is Text && (widget.data?.contains('CSC 2259') ?? false),
    );
    await tester.dragUntilVisible(
      outstandingCourses,
      find.byType(ListView),
      const Offset(0, -400),
    );
    expect(tester.widget<Text>(outstandingCourses).data, 'CSC 2259');
  });
}

class MemoryDegreePlanRepository implements DegreePlanRepository {
  MemoryDegreePlanRepository(this.saved);

  DegreePlanInput? saved;

  @override
  Future<DegreePlanInput?> load() async => saved;

  @override
  Future<void> save(DegreePlanInput input) async {
    saved = input;
  }
}
