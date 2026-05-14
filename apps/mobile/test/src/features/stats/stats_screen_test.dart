// ignore_for_file: use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/study_stats_summary.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_controller.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_screen.dart';

void main() {
  testWidgets('Stats screen displays simple local summary counters', (
    tester,
  ) async {
    final controller = _FakeStatsController(
      today: const StudyStatsSummary(
        readingMinutes: 12,
        lookupCount: 3,
        paragraphTranslationCount: 2,
        cardsCreated: 1,
        cardsReviewed: 4,
      ),
      last7Days: const StudyStatsSummary(
        readingMinutes: 30,
        lookupCount: 9,
        paragraphTranslationCount: 6,
        cardsCreated: 3,
        cardsReviewed: 10,
      ),
      allTime: const StudyStatsSummary(
        readingMinutes: 90,
        lookupCount: 20,
        paragraphTranslationCount: 11,
        cardsCreated: 8,
        cardsReviewed: 30,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(home: StatsScreen(controller: controller)),
    );
    await tester.pumpAndSettle();

    expect(controller.loadCount, 1);
    expect(find.text('今日概览'), findsOneWidget);
    expect(find.text('12 分钟'), findsOneWidget);
    expect(find.text('3 次查词'), findsOneWidget);
    expect(find.text('4 次复习'), findsOneWidget);
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('最近 7 天'), findsOneWidget);
    expect(find.text('全部时间'), findsOneWidget);
    expect(find.text('阅读分钟数'), findsWidgets);
    expect(find.text('查词次数'), findsWidgets);
    expect(find.text('段落翻译次数'), findsWidgets);
    expect(find.text('创建词卡数'), findsWidgets);
    expect(find.text('复习词卡数'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('30'), findsAtLeastNWidgets(1));
    expect(find.text('90'), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
  });

  testWidgets('Stats glance cards fit Chinese copy without overflow', (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    final overflowErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) {
        overflowErrors.add(details);
        return;
      }
      previousErrorHandler?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousErrorHandler;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;

    final controller = _FakeStatsController(
      today: const StudyStatsSummary(
        readingMinutes: 128,
        lookupCount: 36,
        paragraphTranslationCount: 9,
        cardsCreated: 12,
        cardsReviewed: 45,
      ),
      last7Days: const StudyStatsSummary(
        readingMinutes: 256,
        lookupCount: 72,
        paragraphTranslationCount: 18,
        cardsCreated: 24,
        cardsReviewed: 90,
      ),
      allTime: const StudyStatsSummary(
        readingMinutes: 1024,
        lookupCount: 360,
        paragraphTranslationCount: 96,
        cardsCreated: 120,
        cardsReviewed: 450,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(1.15),
          ),
          child: StatsScreen(controller: controller),
        ),
      ),
    );
    await tester.pump();

    FlutterError.onError = previousErrorHandler;
    expect(overflowErrors, isEmpty);
  });
}

class _FakeStatsController extends StatsController {
  _FakeStatsController({
    required StudyStatsSummary today,
    required StudyStatsSummary last7Days,
    required StudyStatsSummary allTime,
  }) : super.fake(today: today, last7Days: last7Days, allTime: allTime);

  int loadCount = 0;

  @override
  Future<void> load() async {
    loadCount += 1;
  }
}
