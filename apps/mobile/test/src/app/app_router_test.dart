import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/app/study_for_read_app.dart';

void main() {
  testWidgets('defaults to Sign In when signed out', (tester) async {
    await tester.pumpWidget(const StudyForReadApp());
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('书库'), findsNothing);
  });

  testWidgets('Sign In can navigate to Register', (tester) async {
    await tester.pumpWidget(const StudyForReadApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('创建账号'));
    await tester.pumpAndSettle();

    expect(find.text('注册'), findsOneWidget);
    expect(find.text('登录'), findsNothing);
  });

  testWidgets('signed-out users cannot open Library directly', (tester) async {
    await tester.pumpWidget(const StudyForReadApp(initialLocation: '/library'));
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('书库'), findsNothing);
  });

  testWidgets('signed-in shell shows the four bottom navigation tabs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(isSignedIn: true, initialLocation: '/library'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('书库'), findsWidgets);
    expect(find.text('词卡'), findsWidgets);
    expect(find.text('统计'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
  });

  testWidgets('Reader is a standalone full-screen route outside bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(isSignedIn: true, initialLocation: '/reader'),
    );
    await tester.pumpAndSettle();

    expect(find.text('阅读器'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });
}
