import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/local_study_daily_stat.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/review_scheduler.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/review_controller.dart';

void main() {
  test('review updates local card, enqueues sync, and increments stats', () async {
    final reviewedAt = DateTime.utc(2026, 5, 8, 12);
    final card = _card(
      id: 'card-1',
      ownerUserId: 'user-1',
      serverCardId: 'server-card-1',
      reviewCount: 0,
    );
    final wordRepository = _FakeWordCardRepository([card]);
    final pendingRepository = _FakePendingSyncEventRepository();
    final statsRepository = _FakeStudyStatsRepository();
    final controller = ReviewController(
      ownerUserId: 'user-1',
      wordCardRepository: wordRepository,
      pendingRepository: pendingRepository,
      statsRepository: statsRepository,
      scheduler: const ReviewScheduler(),
      now: () => reviewedAt,
    );

    final result = await controller.reviewCard(cardId: 'card-1', known: true);

    expect(result.reviewCount, 1);
    expect(result.nextReviewAt, reviewedAt.add(const Duration(days: 3)));
    expect(wordRepository.updatedCardId, 'card-1');
    expect(wordRepository.updatedOwnerUserId, 'user-1');
    expect(wordRepository.updatedReviewStatus, 'learning');
    expect(wordRepository.updatedReviewCount, 1);
    expect(wordRepository.updatedSyncStatus, 'dirty');
    expect(pendingRepository.events, hasLength(1));
    expect(pendingRepository.events.single.eventType, 'word_card_review');
    expect(pendingRepository.events.single.ownerUserId, 'user-1');
    expect(statsRepository.cardsReviewed, 1);

    final payload =
        jsonDecode(pendingRepository.events.single.payloadJson)
            as Map<String, Object?>;
    expect(payload['cardId'], 'card-1');
    expect(payload['serverCardId'], 'server-card-1');
    expect(payload['known'], true);
    expect(payload['reviewStatus'], 'learning');
    expect(payload['reviewCount'], 1);
    expect(payload.keys, isNot(contains('content')));
    expect(payload.keys, isNot(contains('chapterContent')));
    expect(payload.keys, isNot(contains('originalFile')));
    expect(payload.keys, isNot(contains('filePath')));
    expect(payload.keys, isNot(contains('fullBook')));
    expect(payload.keys, isNot(contains('translatedText')));
  });

  test('cannot review another owner card', () async {
    final controller = ReviewController(
      ownerUserId: 'user-1',
      wordCardRepository: _FakeWordCardRepository([
        _card(id: 'card-2', ownerUserId: 'user-2'),
      ]),
      pendingRepository: _FakePendingSyncEventRepository(),
      statsRepository: _FakeStudyStatsRepository(),
      scheduler: const ReviewScheduler(),
      now: () => DateTime.utc(2026, 5, 8, 12),
    );

    expect(
      () => controller.reviewCard(cardId: 'card-2', known: false),
      throwsStateError,
    );
  });
}

LocalWordCard _card({
  required String id,
  required String ownerUserId,
  String? serverCardId,
  int reviewCount = 0,
}) {
  final now = DateTime.utc(2026, 5, 8, 12);
  return LocalWordCard(
    id: id,
    serverCardId: serverCardId,
    ownerUserId: ownerUserId,
    cardType: 'private_sentence',
    lexemeId: null,
    privateSurface: 'Sentence',
    privateDefinition: 'Meaning',
    privateContext: 'Context',
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'new',
    reviewCount: reviewCount,
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
  String? updatedCardId;
  String? updatedOwnerUserId;
  String? updatedReviewStatus;
  int? updatedReviewCount;
  String? updatedSyncStatus;

  @override
  Future<LocalWordCard?> findById(String id) async {
    return cards.where((card) => card.id == id).firstOrNull;
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
    updatedCardId = id;
    updatedOwnerUserId = cards
        .where((card) => card.id == id)
        .firstOrNull
        ?.ownerUserId;
    updatedReviewStatus = reviewStatus;
    updatedReviewCount = reviewCount;
    updatedSyncStatus = syncStatus;
    return cards.any((card) => card.id == id) ? 1 : 0;
  }

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async => [];

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    return [];
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
    return events
        .where((event) => event.ownerUserId == ownerUserId)
        .toList(growable: false);
  }
}

class _FakeStudyStatsRepository implements LocalStudyStatsRepository {
  int cardsReviewed = 0;

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
    this.cardsReviewed += cardsReviewed;
    final now = DateTime.utc(2026, 5, 8, 12);
    return LocalStudyDailyStat(
      id: 'stat-1',
      ownerUserId: ownerUserId,
      statDate: statDate,
      readingMinutes: 0,
      lookupCount: 0,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: this.cardsReviewed,
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
