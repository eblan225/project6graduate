import 'package:flutter_test/flutter_test.dart';
import 'package:project6graduate/main.dart';

void main() {
  testWidgets('app opens and navigates to the course list', (tester) async {
    await tester.pumpWidget(const TigerTrackApp());
    await tester.pumpAndSettle();

    expect(find.text('TigerTrack'), findsOneWidget);
    expect(find.text('Degree progress'), findsNothing);

    await tester.tap(find.text('Courses').last);
    await tester.pumpAndSettle();

    expect(find.text('My courses'), findsOneWidget);
    expect(find.text('ENGL 1001'), findsOneWidget);
  });
}
