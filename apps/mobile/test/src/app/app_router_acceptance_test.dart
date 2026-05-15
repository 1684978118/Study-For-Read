import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/app/study_for_read_app.dart';

void main() {
  testWidgets('acceptance reader route is hidden by default', (tester) async {
    await tester.pumpWidget(
      const StudyForReadApp(initialLocation: '/acceptance/reader'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-email-field')), findsOneWidget);
    expect(find.byKey(const Key('reader-page-view')), findsNothing);
  });

  testWidgets('enabled acceptance reader route opens a seeded full-screen reader', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(
        initialLocation: '/acceptance/reader',
        enableAcceptanceReader: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-page-view')), findsOneWidget);
    expect(find.textContaining('第一章的阅读验收文本'), findsOneWidget);
    expect(find.textContaining('Acceptance Reader Seed chapter one'), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    expect(find.textContaining('验收阅读样书'), findsOneWidget);
    expect(find.byKey(const Key('reader-directory-button')), findsOneWidget);
    expect(find.byKey(const Key('reader-night-toggle-button')), findsOneWidget);
    expect(find.byKey(const Key('reader-settings-button')), findsOneWidget);
  });

  testWidgets('enabled acceptance reader can close back to Sign In', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(
        initialLocation: '/acceptance/reader',
        enableAcceptanceReader: true,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-close-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('sign-in-email-field')), findsOneWidget);
    expect(find.byKey(const Key('reader-page-view')), findsNothing);
  });
}
