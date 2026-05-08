import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_controller.dart';

void main() {
  test('loads due, all, and private sentence cards for current owner', () async {
    final now = DateTime.utc(2026, 5, 8, 12);
    final wordRepository = _FakeWordCardRepository([
      _lexemeCard(id: 'due-null', ownerUserId: 'user-1', lexemeId: 'lexeme-1'),
      _lexemeCard(
        id: 'due-time',
        ownerUserId: 'user-1',
        lexemeId: 'lexeme-2',
        nextReviewAt: now.subtract(const Duration(minutes: 1)),
      ),
      _lexemeCard(
        id: 'future',
        ownerUserId: 'user-1',
        lexemeId: 'lexeme-3',
        nextReviewAt: now.add(const Duration(days: 1)),
      ),
      _privateCard(id: 'private-1', ownerUserId: 'user-1'),
      _privateCard(
        id: 'other-private',
        ownerUserId: 'user-2',
        privateSurface: 'Other private sentence',
        privateDefinition: 'Other meaning',
        privateContext: 'Do not show this',
      ),
    ]);
    final controller = VocabularyController(
      ownerUserId: 'user-1',
      wordCardRepository: wordRepository,
      lexemeRepository: _FakeLexemeRepository({
        'lexeme-1': _lexeme(id: 'lexeme-1', surface: '心'),
        'lexeme-2': _lexeme(id: 'lexeme-2', surface: '先生'),
        'lexeme-3': _lexeme(id: 'lexeme-3', surface: '明日'),
      }),
      now: () => now,
    );

    await controller.load();

    expect(wordRepository.ownerQueries, everyElement('user-1'));
    expect(controller.dueCards.map((card) => card.id), [
      'due-null',
      'due-time',
      'private-1',
    ]);
    expect(controller.allCards.map((card) => card.id), [
      'due-null',
      'due-time',
      'future',
      'private-1',
    ]);
    expect(controller.privateSentenceCards.map((card) => card.id), [
      'private-1',
    ]);
    expect(controller.allCards.map((card) => card.surface), contains('心'));
    expect(
      controller.privateSentenceCards.single.privateContext,
      'My private context',
    );
  });
}

LocalLexeme _lexeme({required String id, required String surface}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalLexeme(
    id: id,
    surface: surface,
    reading: 'reading-$id',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: 'definition-$id',
    shortDefinition: 'short-$id',
    cachedAt: now,
    updatedAt: now,
  );
}

LocalWordCard _lexemeCard({
  required String id,
  required String ownerUserId,
  required String lexemeId,
  DateTime? nextReviewAt,
}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalWordCard(
    id: id,
    serverCardId: null,
    ownerUserId: ownerUserId,
    cardType: 'lexeme',
    lexemeId: lexemeId,
    privateSurface: null,
    privateDefinition: null,
    privateContext: null,
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'new',
    reviewCount: 0,
    nextReviewAt: nextReviewAt,
    lastReviewedAt: null,
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

LocalWordCard _privateCard({
  required String id,
  required String ownerUserId,
  String privateSurface = '私だけの文',
  String privateDefinition = 'Private meaning',
  String privateContext = 'My private context',
}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalWordCard(
    id: id,
    serverCardId: null,
    ownerUserId: ownerUserId,
    cardType: 'private_sentence',
    lexemeId: null,
    privateSurface: privateSurface,
    privateDefinition: privateDefinition,
    privateContext: privateContext,
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'learning',
    reviewCount: 2,
    nextReviewAt: null,
    lastReviewedAt: null,
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeWordCardRepository implements LocalWordCardRepository {
  _FakeWordCardRepository(this.cards);

  final List<LocalWordCard> cards;
  final List<String> ownerQueries = [];

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async {
    ownerQueries.add(ownerUserId);
    return cards
        .where((card) => card.ownerUserId == ownerUserId)
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    ownerQueries.add(ownerUserId);
    return cards
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              (card.nextReviewAt == null ||
                  !card.nextReviewAt!.isAfter(dueAt)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    ownerQueries.add(ownerUserId);
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
