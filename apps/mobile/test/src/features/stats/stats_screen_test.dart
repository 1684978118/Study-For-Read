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
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Last 7 days'), findsOneWidget);
    expect(find.text('All time'), findsOneWidget);
    expect(find.text('Reading minutes'), findsWidgets);
    expect(find.text('Lookups'), findsWidgets);
    expect(find.text('Paragraph translations'), findsWidgets);
    expect(find.text('Cards created'), findsWidgets);
    expect(find.text('Cards reviewed'), findsWidgets);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('30'), findsAtLeastNWidgets(1));
    expect(find.text('90'), findsOneWidget);
    expect(find.byType(Placeholder), findsNothing);
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
