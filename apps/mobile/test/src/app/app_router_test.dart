import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/app/study_for_read_app.dart';

void main() {
  testWidgets('defaults to Sign In when signed out', (tester) async {
    await tester.pumpWidget(const StudyForReadApp());
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Library'), findsNothing);
  });

  testWidgets('Sign In can navigate to Register', (tester) async {
    await tester.pumpWidget(const StudyForReadApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Register'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets('signed-out users cannot open Library directly', (tester) async {
    await tester.pumpWidget(const StudyForReadApp(initialLocation: '/library'));
    await tester.pumpAndSettle();

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Library'), findsNothing);
  });

  testWidgets('signed-in shell shows the four bottom navigation tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(isSignedIn: true, initialLocation: '/library'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Vocabulary'), findsWidgets);
    expect(find.text('Stats'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);
  });

  testWidgets('Reader is a standalone full-screen route outside bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(isSignedIn: true, initialLocation: '/reader'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reader'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
