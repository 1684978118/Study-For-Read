import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/app/study_for_read_app.dart';

void main() {
  testWidgets('StudyForReadApp shows the signed-out shell', (tester) async {
    await tester.pumpWidget(const StudyForReadApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });
}
