import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reading_sync/data/reading_sync_api_client.dart';
import 'package:study_for_read_mobile/src/features/stats/data/stats_api_client.dart';
import 'package:study_for_read_mobile/src/features/sync/data/learning_sync_worker.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/vocabulary_api_client.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/vocabulary_card.dart';

void main() {
  const fingerprint =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  test(
    'syncs current owner metadata, progress, cards, reviews, and stats',
    () async {
      final pendingRepository = _FakePendingRepository([
        _event(
          id: 'book-event',
          ownerUserId: 'user-1',
          eventType: 'book_metadata',
          aggregateKey: fingerprint,
          payload: {
            'bookFingerprint': fingerprint,
            'title': 'Kokoro',
            'author': 'Soseki',
            'fileType': 'txt',
            'sourceLang': 'ja',
            'targetLang': 'zh-CN',
            'chapterCount': 42,
          },
        ),
        _event(
          id: 'progress-event',
          ownerUserId: 'user-1',
          eventType: 'reading_progress',
          aggregateKey: fingerprint,
          payload: {
            'bookFingerprint': fingerprint,
            'currentChapterIndex': 2,
            'currentParagraphIndex': 4,
            'currentCharOffset': 6,
            'lastReadAt': '2026-05-08T10:30:00.000Z',
          },
        ),
        _event(
          id: 'create-event',
          ownerUserId: 'user-1',
          eventType: 'word_card_create',
          aggregateKey: 'lexeme-1',
          payload: {
            'cardType': 'lexeme',
            'lexemeId': 'lexeme-1',
            'sourceBookFingerprint': fingerprint,
            'sourceBookTitle': 'Kokoro',
          },
        ),
        _event(
          id: 'review-event',
          ownerUserId: 'user-1',
          eventType: 'word_card_review',
          aggregateKey: 'server-card-1',
          payload: {
            'cardId': 'local-card-1',
            'serverCardId': 'server-card-1',
            'known': true,
            'reviewedAt': '2026-05-08T11:00:00.000Z',
            'reviewStatus': 'known',
            'reviewCount': 2,
            'nextReviewAt': '2026-05-15T11:00:00.000Z',
            'lastReviewedAt': '2026-05-08T11:00:00.000Z',
          },
        ),
        _event(
          id: 'stats-event',
          ownerUserId: 'user-1',
          eventType: 'daily_stats',
          aggregateKey: '2026-05-08',
          payload: {
            'statDate': '2026-05-08',
            'readingMinutes': 12,
            'lookupCount': 8,
            'paragraphTranslationCount': 3,
            'cardsCreated': 2,
            'cardsReviewed': 5,
          },
        ),
        _event(
          id: 'other-user-event',
          ownerUserId: 'user-2',
          eventType: 'daily_stats',
          aggregateKey: '2026-05-08',
          payload: {
            'statDate': '2026-05-08',
            'readingMinutes': 99,
            'lookupCount': 99,
            'paragraphTranslationCount': 99,
            'cardsCreated': 99,
            'cardsReviewed': 99,
          },
        ),
      ]);
      final readingClient = _FakeReadingSyncApiClient();
      final statsClient = _FakeStatsApiClient();
      final vocabularyClient = _FakeVocabularyApiClient();
      final wordCards = _FakeWordCardRepository([
        _localCard(id: 'local-card-1', lexemeId: 'lexeme-1'),
      ]);
      final worker = LearningSyncWorker(
        pendingRepository: pendingRepository,
        readingSyncApiClient: readingClient,
        statsApiClient: statsClient,
        vocabularyApiClient: vocabularyClient,
        localBookRepository: _FakeBookRepository(),
        readingPositionRepository: _FakeReadingPositionRepository(),
        wordCardRepository: wordCards,
        markEventDone: pendingRepository.markDone,
        markEventFailed: pendingRepository.markFailed,
        markWordCardSynced: wordCards.markSynced,
      );

      await worker.syncPendingEventsForCurrentUser('user-1');

      expect(pendingRepository.queriedOwnerUserId, 'user-1');
      expect(readingClient.upsertedBookFingerprints, [fingerprint]);
      expect(readingClient.updatedProgressFingerprints, [fingerprint]);
      expect(vocabularyClient.createdLexemeIds, ['lexeme-1']);
      expect(wordCards.syncedServerCardIds, ['server-created-card']);
      expect(vocabularyClient.reviewedCardIds, ['server-card-1']);
      expect(statsClient.sentReadingMinutes, [12]);
      expect(pendingRepository.doneEventIds, [
        'book-event',
        'progress-event',
        'create-event',
        'review-event',
        'stats-event',
      ]);
      expect(
        pendingRepository.doneEventIds,
        isNot(contains('other-user-event')),
      );
      expect(
        _jsonKeys(readingClient.lastBookMetadataPayload),
        isNot(contains('originalFile')),
      );
      expect(
        _jsonKeys(readingClient.lastBookMetadataPayload),
        isNot(contains('filePath')),
      );
      expect(
        _jsonKeys(readingClient.lastBookMetadataPayload),
        isNot(contains('content')),
      );
    },
  );

  test(
    'keeps word_card_review pending when server card id is missing',
    () async {
      final pendingRepository = _FakePendingRepository([
        _event(
          id: 'review-event',
          eventType: 'word_card_review',
          payload: {
            'cardId': 'local-card-1',
            'known': false,
            'reviewedAt': '2026-05-08T11:00:00.000Z',
            'reviewStatus': 'learning',
            'reviewCount': 1,
            'nextReviewAt': '2026-05-09T11:00:00.000Z',
            'lastReviewedAt': '2026-05-08T11:00:00.000Z',
          },
        ),
      ]);
      final vocabularyClient = _FakeVocabularyApiClient();
      final worker = _worker(
        pendingRepository: pendingRepository,
        vocabularyClient: vocabularyClient,
      );

      await worker.syncPendingEventsForCurrentUser('user-1');

      expect(vocabularyClient.reviewedCardIds, isEmpty);
      expect(pendingRepository.doneEventIds, isEmpty);
      expect(pendingRepository.failedEventIds, isEmpty);
    },
  );

  test('records retry state on recoverable failure', () async {
    final pendingRepository = _FakePendingRepository([
      _event(
        id: 'book-event',
        eventType: 'book_metadata',
        aggregateKey: fingerprint,
        payload: {
          'bookFingerprint': fingerprint,
          'title': 'Kokoro',
          'fileType': 'txt',
          'sourceLang': 'ja',
          'targetLang': 'zh-CN',
          'chapterCount': 42,
        },
      ),
    ]);
    final readingClient = _FakeReadingSyncApiClient(
      error: const ApiError(code: 'NETWORK_UNAVAILABLE', message: 'offline'),
    );
    final worker = _worker(
      pendingRepository: pendingRepository,
      readingClient: readingClient,
    );

    await worker.syncPendingEventsForCurrentUser('user-1');

    expect(pendingRepository.doneEventIds, isEmpty);
    expect(pendingRepository.failedEventIds, ['book-event']);
    expect(pendingRepository.failureCodes, ['NETWORK_UNAVAILABLE']);
    expect(pendingRepository.failedAttempts, [1]);
  });
}

LearningSyncWorker _worker({
  required _FakePendingRepository pendingRepository,
  _FakeReadingSyncApiClient? readingClient,
  _FakeStatsApiClient? statsClient,
  _FakeVocabularyApiClient? vocabularyClient,
}) {
  final wordCards = _FakeWordCardRepository([]);
  return LearningSyncWorker(
    pendingRepository: pendingRepository,
    readingSyncApiClient: readingClient ?? _FakeReadingSyncApiClient(),
    statsApiClient: statsClient ?? _FakeStatsApiClient(),
    vocabularyApiClient: vocabularyClient ?? _FakeVocabularyApiClient(),
    localBookRepository: _FakeBookRepository(),
    readingPositionRepository: _FakeReadingPositionRepository(),
    wordCardRepository: wordCards,
    markEventDone: pendingRepository.markDone,
    markEventFailed: pendingRepository.markFailed,
    markWordCardSynced: wordCards.markSynced,
  );
}

PendingSyncEvent _event({
  required String id,
  String ownerUserId = 'user-1',
  required String eventType,
  String? aggregateKey,
  required Map<String, Object?> payload,
  int attemptCount = 0,
}) {
  final now = DateTime.utc(2026, 5, 8, 10);
  return PendingSyncEvent(
    id: id,
    ownerUserId: ownerUserId,
    eventType: eventType,
    aggregateKey: aggregateKey,
    payloadJson: jsonEncode(payload),
    status: 'pending',
    attemptCount: attemptCount,
    lastErrorCode: null,
    createdAt: now,
    updatedAt: now,
  );
}

List<String> _jsonKeys(Map<String, Object?>? payload) {
  return payload?.keys.toList(growable: false) ?? const [];
}

LocalWordCard _localCard({required String id, required String lexemeId}) {
  final now = DateTime.utc(2026, 5, 8, 10);
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
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

class _FakePendingRepository implements PendingSyncEventRepository {
  _FakePendingRepository(this.events);

  final List<PendingSyncEvent> events;
  String? queriedOwnerUserId;
  final doneEventIds = <String>[];
  final failedEventIds = <String>[];
  final failureCodes = <String>[];
  final failedAttempts = <int>[];

  @override
  Future<List<PendingSyncEvent>> findPendingByOwnerUserId(
    String ownerUserId,
  ) async {
    queriedOwnerUserId = ownerUserId;
    return events.where((event) => event.ownerUserId == ownerUserId).toList();
  }

  @override
  Future<int> insert(PendingSyncEvent event) async {
    events.add(event);
    return 1;
  }

  Future<void> markDone(PendingSyncEvent event) async {
    doneEventIds.add(event.id);
  }

  Future<void> markFailed(PendingSyncEvent event, String errorCode) async {
    failedEventIds.add(event.id);
    failureCodes.add(errorCode);
    failedAttempts.add(event.attemptCount + 1);
  }
}

class _FakeReadingSyncApiClient extends ReadingSyncApiClient {
  _FakeReadingSyncApiClient({this.error});

  final Object? error;
  final upsertedBookFingerprints = <String>[];
  final updatedProgressFingerprints = <String>[];
  Map<String, Object?>? lastBookMetadataPayload;

  @override
  Future<void> upsertBookMetadata({
    required String bookFingerprint,
    required String title,
    String? author,
    required String fileType,
    required String sourceLang,
    required String targetLang,
    required int chapterCount,
  }) async {
    final error = this.error;
    if (error != null) {
      throw error;
    }
    upsertedBookFingerprints.add(bookFingerprint);
    lastBookMetadataPayload = {
      'title': title,
      'author': author,
      'fileType': fileType,
      'sourceLang': sourceLang,
      'targetLang': targetLang,
      'chapterCount': chapterCount,
    };
  }

  @override
  Future<void> updateReadingProgress({
    required String bookFingerprint,
    required int currentChapterIndex,
    required int currentParagraphIndex,
    required int currentCharOffset,
    DateTime? lastReadAt,
  }) async {
    updatedProgressFingerprints.add(bookFingerprint);
  }
}

class _FakeStatsApiClient extends StatsApiClient {
  final sentReadingMinutes = <int>[];

  @override
  Future<void> addDailyStats({
    required DateTime statDate,
    required int readingMinutes,
    required int lookupCount,
    required int paragraphTranslationCount,
    required int cardsCreated,
    required int cardsReviewed,
  }) async {
    sentReadingMinutes.add(readingMinutes);
  }
}

class _FakeVocabularyApiClient extends VocabularyApiClient {
  final createdLexemeIds = <String>[];
  final reviewedCardIds = <String>[];

  @override
  Future<VocabularyCardResult> createLexemeCard({
    required String lexemeId,
    String? sourceBookFingerprint,
    String? sourceBookTitle,
  }) async {
    createdLexemeIds.add(lexemeId);
    return const VocabularyCardResult(
      existing: false,
      card: VocabularyCard(
        id: 'server-created-card',
        cardType: 'lexeme',
        reviewStatus: 'new',
        reviewCount: 0,
      ),
    );
  }

  @override
  Future<VocabularyCardResult> createPrivateSentenceCard({
    required String privateSurface,
    required String privateDefinition,
    String? privateContext,
    String? sourceBookFingerprint,
    String? sourceBookTitle,
  }) async {
    return const VocabularyCardResult(
      existing: false,
      card: VocabularyCard(
        id: 'server-private-card',
        cardType: 'private_sentence',
        reviewStatus: 'new',
        reviewCount: 0,
      ),
    );
  }

  @override
  Future<VocabularyCard> reviewCard({
    required String cardId,
    required bool known,
    required DateTime reviewedAt,
  }) async {
    reviewedCardIds.add(cardId);
    return VocabularyCard(
      id: cardId,
      cardType: 'lexeme',
      reviewStatus: 'known',
      reviewCount: 1,
      lastReviewedAt: reviewedAt,
    );
  }
}

class _FakeWordCardRepository implements LocalWordCardRepository {
  _FakeWordCardRepository(this.cards);

  final List<LocalWordCard> cards;
  final syncedServerCardIds = <String>[];

  @override
  Future<LocalWordCard?> findByOwnerUserIdAndLexemeId({
    required String ownerUserId,
    required String lexemeId,
  }) async {
    return cards
        .where(
          (card) =>
              card.ownerUserId == ownerUserId && card.lexemeId == lexemeId,
        )
        .cast<LocalWordCard?>()
        .firstOrNull;
  }

  @override
  Future<LocalWordCard?> findById(String id) async {
    return cards
        .where((card) => card.id == id)
        .cast<LocalWordCard?>()
        .firstOrNull;
  }

  Future<void> markSynced(LocalWordCard card, String serverCardId) async {
    syncedServerCardIds.add(serverCardId);
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
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    return [];
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
    return 0;
  }

  @override
  Future<void> upsert(LocalWordCard card) async {}
}

class _FakeBookRepository implements LocalBookRepository {
  @override
  Future<LocalBook?> findByOwnerUserIdAndBookFingerprint({
    required String ownerUserId,
    required String bookFingerprint,
  }) async {
    return null;
  }

  @override
  Future<List<LocalBook>> findByOwnerUserId(String ownerUserId) async => [];

  @override
  Future<int> insert(LocalBook book) async => 1;

  @override
  Future<int> update(LocalBook book) async => 1;
}

class _FakeReadingPositionRepository implements LocalReadingPositionRepository {
  @override
  Future<LocalReadingPosition?> findByBookId(String bookId) async => null;

  @override
  Future<void> upsert(LocalReadingPosition position) async {}
}
