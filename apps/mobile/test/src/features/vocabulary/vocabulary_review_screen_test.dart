import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/local_study_daily_stat.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/review_scheduler.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/review_controller.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_controller.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/vocabulary_screen.dart';

void main() {
  testWidgets('Known action reviews a due card without network', (tester) async {
    final now = DateTime.utc(2026, 5, 8, 12);
    final wordRepository = _FakeWordCardRepository([
      _card(id: 'card-1', ownerUserId: 'user-1', lexemeId: 'lexeme-1'),
    ]);
    final pendingRepository = _FakePendingSyncEventRepository();
    final vocabularyController = VocabularyController(
      ownerUserId: 'user-1',
      wordCardRepository: wordRepository,
      lexemeRepository: _FakeLexemeRepository({
        'lexeme-1': _lexeme(id: 'lexeme-1', surface: 'kokoro'),
      }),
      now: () => now,
    );
    final reviewController = ReviewController(
      ownerUserId: 'user-1',
      wordCardRepository: wordRepository,
      pendingRepository: pendingRepository,
      statsRepository: _FakeStudyStatsRepository(),
      scheduler: const ReviewScheduler(),
      now: () => now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: VocabularyScreen(
          controller: vocabularyController,
          reviewController: reviewController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('认识'), findsOneWidget);
    expect(find.text('不认识'), findsOneWidget);
    expect(find.text('新卡 - 已复习 0 次'), findsOneWidget);

    await tester.tap(find.text('认识'));
    await tester.pumpAndSettle();

    expect(find.text('现在没有待复习词卡'), findsOneWidget);
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();

    expect(find.text('学习中 - 已复习 1 次'), findsOneWidget);
    expect(pendingRepository.events.single.eventType, 'word_card_review');
  });
}

LocalLexeme _lexeme({required String id, required String surface}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalLexeme(
    id: id,
    surface: surface,
    reading: 'reading',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: 'definition',
    shortDefinition: 'short',
    cachedAt: now,
    updatedAt: now,
  );
}

LocalWordCard _card({
  required String id,
  required String ownerUserId,
  required String lexemeId,
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

  @override
  Future<LocalWordCard?> findById(String id) async {
    return cards.where((card) => card.id == id).firstOrNull;
  }

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
              (card.nextReviewAt == null ||
                  !card.nextReviewAt!.isAfter(dueAt)),
        )
        .toList(growable: false);
  }

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
    final index = cards.indexWhere((card) => card.id == id);
    if (index < 0) {
      return 0;
    }
    final current = cards[index];
    cards[index] = LocalWordCard(
      id: current.id,
      serverCardId: current.serverCardId,
      ownerUserId: current.ownerUserId,
      cardType: current.cardType,
      lexemeId: current.lexemeId,
      privateSurface: current.privateSurface,
      privateDefinition: current.privateDefinition,
      privateContext: current.privateContext,
      sourceBookFingerprint: current.sourceBookFingerprint,
      sourceBookTitle: current.sourceBookTitle,
      reviewStatus: reviewStatus,
      reviewCount: reviewCount,
      nextReviewAt: nextReviewAt,
      lastReviewedAt: lastReviewedAt,
      syncStatus: syncStatus,
      createdAt: current.createdAt,
      updatedAt: updatedAt,
    );
    return 1;
  }

  @override
  Future<LocalWordCard?> findByOwnerUserIdAndLexemeId({
    required String ownerUserId,
    required String lexemeId,
  }) async {
    return null;
  }

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    return [];
  }

  @override
  Future<void> upsert(LocalWordCard card) async {}
}

class _FakeLexemeRepository implements LocalLexemeRepository {
  const _FakeLexemeRepository(this.lexemes);

  final Map<String, LocalLexeme> lexemes;

  @override
  Future<LocalLexeme?> findById(String id) async => lexemes[id];

  @override
  Future<void> upsert(LocalLexeme lexeme) async {}
}

class _FakePendingSyncEventRepository implements PendingSyncEventRepository {
  final List<PendingSyncEvent> events = [];

  @override
  Future<int> insert(PendingSyncEvent event) async {
    events.add(event);
    return 1;
  }

  @override
  Future<List<PendingSyncEvent>> findPendingByOwnerUserId(
    String ownerUserId,
  ) async {
    return events;
  }
}

class _FakeStudyStatsRepository implements LocalStudyStatsRepository {
  @override
  Future<LocalStudyDailyStat> increment({
    required String ownerUserId,
    required DateTime statDate,
    required int readingMinutes,
    required int lookupCount,
    required int paragraphTranslationCount,
    required int cardsCreated,
    required int cardsReviewed,
  }) async {
    final now = DateTime.utc(2026, 5, 8, 12);
    return LocalStudyDailyStat(
      id: 'stat-1',
      ownerUserId: ownerUserId,
      statDate: statDate,
      readingMinutes: 0,
      lookupCount: 0,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: cardsReviewed,
      syncStatus: 'dirty',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<List<LocalStudyDailyStat>> findByOwnerUserId(
    String ownerUserId,
  ) async {
    return [];
  }

  @override
  Future<LocalStudyDailyStat?> findByOwnerUserIdAndStatDate({
    required String ownerUserId,
    required DateTime statDate,
  }) async {
    return null;
  }
}
