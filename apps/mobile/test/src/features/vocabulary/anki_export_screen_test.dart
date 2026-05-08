import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_options.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_service.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/anki_export_screen.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_controller.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_screen.dart';

void main() {
  testWidgets('Anki export screen offers range options and completion state', (
    tester,
  ) async {
    final service = _FakeAnkiExportService();

    await tester.pumpWidget(
      MaterialApp(
        home: AnkiExportScreen(
          service: service,
          allCards: const [
            AnkiExportCard(
              id: 'card-1',
              front: 'local vocabulary card',
              meaning: 'from local vocabulary',
            ),
          ],
          dueCards: const [
            AnkiExportCard(
              id: 'card-1',
              front: 'local vocabulary card',
              meaning: 'from local vocabulary',
            ),
          ],
        ),
      ),
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
    expect(service.lastCards, isNotEmpty);
    expect(service.lastCards.single.id, 'card-1');
    expect(service.lastCards.single.front, 'local vocabulary card');
    expect(find.text('Export ready'), findsOneWidget);
    expect(find.text('StudyForRead-Anki.txt'), findsOneWidget);
    expect(find.textContaining('#separator:Tab'), findsNothing);
    expect(find.textContaining('card-1\tfront'), findsNothing);
  });

  testWidgets('Anki export screen applies selected export range', (
    tester,
  ) async {
    final service = _FakeAnkiExportService();

    await tester.pumpWidget(
      MaterialApp(
        home: AnkiExportScreen(
          service: service,
          allCards: const [
            AnkiExportCard(
              id: 'all-card',
              front: 'All card',
              meaning: 'All meaning',
            ),
          ],
          dueCards: const [
            AnkiExportCard(
              id: 'due-card',
              front: 'Due card',
              meaning: 'Due meaning',
            ),
          ],
          privateSentenceCards: const [
            AnkiExportCard(
              id: 'private-card',
              front: 'Private card',
              meaning: 'Private meaning',
            ),
          ],
        ),
      ),
    );

    await tester.tap(find.text('Export UTF-8 TXT'));
    await tester.pumpAndSettle();
    expect(service.lastOptions?.scope, AnkiExportScope.allCards);
    expect(service.lastCards.map((card) => card.id), ['all-card']);

    await tester.tap(find.text('Due cards'));
    await tester.tap(find.text('Export UTF-8 TXT'));
    await tester.pumpAndSettle();
    expect(service.lastOptions?.scope, AnkiExportScope.dueCards);
    expect(service.lastCards.map((card) => card.id), ['due-card']);

    await tester.tap(find.text('Private sentence cards'));
    await tester.tap(find.text('Export UTF-8 TXT'));
    await tester.pumpAndSettle();
    expect(service.lastOptions?.scope, AnkiExportScope.privateSentenceCards);
    expect(service.lastCards.map((card) => card.id), ['private-card']);
  });

  testWidgets('Vocabulary screen exposes Anki export entry', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VocabularyScreen()));

    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('Vocabulary export uses currently loaded local cards', (
    tester,
  ) async {
    final service = _FakeAnkiExportService();
    final controller = VocabularyController(
      ownerUserId: 'user-1',
      wordCardRepository: _FakeWordCardRepository([
        _lexemeCard(id: 'local-card-1', lexemeId: 'lexeme-1'),
      ]),
      lexemeRepository: _FakeLexemeRepository({
        'lexeme-1': _lexeme(
          id: 'lexeme-1',
          surface: 'Local surface',
          reading: 'Local reading',
          definition: 'Local meaning',
        ),
      }),
      now: () => DateTime.utc(2026, 5, 8, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VocabularyScreen(
          controller: controller,
          ankiExportService: service,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Export UTF-8 TXT'));
    await tester.pumpAndSettle();

    expect(service.lastCards, isNotEmpty);
    expect(service.lastCards.single.id, 'local-card-1');
    expect(service.lastCards.single.front, 'Local surface');
    expect(service.lastCards.single.reading, 'Local reading');
    expect(service.lastCards.single.meaning, 'Local meaning');
  });
}

class _FakeAnkiExportService extends AnkiExportService {
  AnkiExportOptions? lastOptions;
  List<AnkiExportCard> lastCards = const [];

  @override
  String exportText({
    required Iterable<AnkiExportCard> cards,
    required AnkiExportOptions options,
  }) {
    lastOptions = options;
    lastCards = cards.toList(growable: false);
    return '#separator:Tab\ncard-1\tfront\n';
  }
}

LocalLexeme _lexeme({
  required String id,
  required String surface,
  required String reading,
  required String definition,
}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalLexeme(
    id: id,
    surface: surface,
    reading: reading,
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: definition,
    shortDefinition: definition,
    cachedAt: now,
    updatedAt: now,
  );
}

LocalWordCard _lexemeCard({required String id, required String lexemeId}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalWordCard(
    id: id,
    serverCardId: null,
    ownerUserId: 'user-1',
    cardType: 'lexeme',
    lexemeId: lexemeId,
    privateSurface: null,
    privateDefinition: null,
    privateContext: null,
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'new',
    reviewCount: 0,
    nextReviewAt: null,
    lastReviewedAt: null,
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeWordCardRepository implements LocalWordCardRepository {
  const _FakeWordCardRepository(this.cards);

  final List<LocalWordCard> cards;

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async {
    return cards
        .where((card) => card.ownerUserId == ownerUserId)
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    return cards
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              (card.nextReviewAt == null || !card.nextReviewAt!.isAfter(dueAt)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    return cards
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              card.cardType == 'private_sentence',
        )
        .toList(growable: false);
  }

  @override
  Future<LocalWordCard?> findById(String id) async => null;

  @override
  Future<LocalWordCard?> findByOwnerUserIdAndLexemeId({
    required String ownerUserId,
    required String lexemeId,
  }) async {
    return null;
  }

  @override
  Future<void> upsert(LocalWordCard card) async {}

  @override
  Future<int> updateReviewState({
    required String id,
    required String reviewStatus,
    required int reviewCount,
    required DateTime? nextReviewAt,
    required DateTime? lastReviewedAt,
    required String syncStatus,
    required DateTime updatedAt,
  }) async {
    return 0;
  }
}

class _FakeLexemeRepository implements LocalLexemeRepository {
  const _FakeLexemeRepository(this.lexemes);

  final Map<String, LocalLexeme> lexemes;

  @override
  Future<LocalLexeme?> findById(String id) async => lexemes[id];

  @override
  Future<void> upsert(LocalLexeme lexeme) async {}
}
