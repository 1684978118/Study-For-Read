import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_options.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_service.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/anki_export_screen.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_screen.dart';

void main() {
  testWidgets('Anki export screen offers range options and completion state', (
    tester,
  ) async {
    final service = _FakeAnkiExportService();

    await tester.pumpWidget(
      MaterialApp(home: AnkiExportScreen(service: service)),
    );

    expect(find.text('Export to Anki'), findsOneWidget);
    expect(find.text('All cards'), findsOneWidget);
    expect(find.text('Due cards'), findsOneWidget);
    expect(find.text('Private sentence cards'), findsOneWidget);
    expect(find.text('Include examples'), findsOneWidget);
    expect(find.text('Include source metadata'), findsOneWidget);

    await tester.tap(find.text('Due cards'));
    await tester.tap(find.text('Include examples'));
    await tester.tap(find.text('Export UTF-8 TXT'));
    await tester.pumpAndSettle();

    expect(service.lastOptions?.scope, AnkiExportScope.dueCards);
    expect(service.lastOptions?.includeExamples, false);
    expect(find.text('Export ready'), findsOneWidget);
    expect(find.text('StudyForRead-Anki.txt'), findsOneWidget);
    expect(find.textContaining('#separator:Tab'), findsNothing);
    expect(find.textContaining('card-1\tfront'), findsNothing);
  });

  testWidgets('Vocabulary screen exposes Anki export entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VocabularyScreen()));

    expect(find.text('Export'), findsOneWidget);
  });
}

class _FakeAnkiExportService extends AnkiExportService {
  AnkiExportOptions? lastOptions;

  @override
  String exportText({
    required Iterable<AnkiExportCard> cards,
    required AnkiExportOptions options,
  }) {
    lastOptions = options;
    return '#separator:Tab\ncard-1\tfront\n';
  }
}
