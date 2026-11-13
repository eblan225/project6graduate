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
