import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/app/study_for_read_app.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_screen.dart';
import 'package:study_for_read_mobile/src/features/settings/presentation/settings_screen.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/study_stats_summary.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_controller.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_screen.dart';

void main() {
  testWidgets('signed-out auth entry uses Chinese copy', (tester) async {
    await tester.pumpWidget(const StudyForReadApp());
    await tester.pumpAndSettle();

    expect(find.text('登录'), findsOneWidget);
    expect(find.text('离线阅读，边读边学。'), findsOneWidget);
    expect(find.text('邮箱'), findsOneWidget);
    expect(find.text('密码'), findsOneWidget);
    expect(find.text('继续'), findsOneWidget);
    expect(find.text('创建账号'), findsOneWidget);
    expect(find.text('Sign In'), findsNothing);
  });

  testWidgets('signed-in shell uses Chinese navigation labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const StudyForReadApp(isSignedIn: true, initialLocation: '/reader'),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      const StudyForReadApp(isSignedIn: true, initialLocation: '/library'),
    );
    await tester.pumpAndSettle();

    expect(find.text('书库'), findsWidgets);
    expect(find.text('词卡'), findsWidgets);
    expect(find.text('统计'), findsWidgets);
    expect(find.text('设置'), findsWidgets);
    expect(find.text('Library'), findsNothing);
    expect(find.text('Vocabulary'), findsNothing);
    expect(find.text('Stats'), findsNothing);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Settings acceptance guidance uses Chinese copy', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('账号与语言'), findsOneWidget);
    expect(find.text('日语到中文'), findsOneWidget);
    expect(find.text('同步与隐私'), findsOneWidget);
    expect(find.text('本地书籍只保存在这台设备上'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('导出到 Anki'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('导出到 Anki'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('退出登录'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('Export to Anki'), findsNothing);
  });

  testWidgets('Reader and Stats shell copy is Chinese', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ReaderScreen()));
    await tester.pumpAndSettle();

    expect(find.text('阅读器'), findsOneWidget);
    expect(find.text('未找到本地书籍'), findsOneWidget);
    expect(find.text('Reader'), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: StatsScreen(
          controller: StatsController.fake(
            today: const StudyStatsSummary(
              readingMinutes: 12,
              lookupCount: 3,
              paragraphTranslationCount: 2,
              cardsCreated: 1,
              cardsReviewed: 4,
            ),
            last7Days: StudyStatsSummary.zero,
            allTime: StudyStatsSummary.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日概览'), findsOneWidget);
    expect(find.text('12 分钟'), findsOneWidget);
    expect(find.text('3 次查词'), findsOneWidget);
    expect(find.text('4 次复习'), findsOneWidget);
    expect(find.text('Today at a glance'), findsNothing);
  });
}
