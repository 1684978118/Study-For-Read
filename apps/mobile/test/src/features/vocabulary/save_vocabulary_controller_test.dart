import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/local_study_daily_stat.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/study/domain/lookup_result.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/vocabulary_api_client.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/vocabulary_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/save_vocabulary_controller.dart';

void main() {
  test('online save creates remote card and synced local state', () async {
    final apiClient = _FakeVocabularyApiClient();
    final lexemeRepository = _FakeLocalLexemeRepository();
    final wordCardRepository = _FakeLocalWordCardRepository();
    final statsRepository = _FakeStudyStatsRepository();
    final controller = _controller(
      apiClient: apiClient,
      lexemeRepository: lexemeRepository,
      wordCardRepository: wordCardRepository,
      statsRepository: statsRepository,
    );

    await controller.saveLookupLexeme(
      _lookupLexeme(),
      sourceBookFingerprint:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      sourceBookTitle: 'Kokoro',
      now: DateTime.utc(2026, 5, 8, 10),
    );

    expect(apiClient.lexemeCalls, hasLength(1));
    expect(apiClient.lexemeCalls.single.lexemeId, 'lexeme-1');
    expect(lexemeRepository.saved.single.id, 'lexeme-1');
    expect(wordCardRepository.saved, hasLength(1));
    expect(wordCardRepository.saved.single.serverCardId, 'server-card-1');
    expect(wordCardRepository.saved.single.syncStatus, 'synced');
    expect(wordCardRepository.saved.single.sourceBookTitle, 'Kokoro');
    expect(statsRepository.increments.single.cardsCreated, 1);
    expect(controller.state.status, SaveVocabularyStatus.saved);
  });

  test(
    'offline save creates local card and pending sync metadata only',
    () async {
      final pendingRepository = _FakePendingSyncEventRepository();
      final controller = _controller(
        apiClient: _FakeVocabularyApiClient(error: _offlineError()),
        pendingRepository: pendingRepository,
      );

      await controller.saveLookupLexeme(
        _lookupLexeme(),
        sourceBookFingerprint:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        sourceBookTitle: 'Kokoro',
        now: DateTime.utc(2026, 5, 8),
      );

      expect(controller.state.status, SaveVocabularyStatus.localOnly);
      expect(pendingRepository.saved, hasLength(1));
      final event = pendingRepository.saved.single;
      expect(event.eventType, 'word_card_create');
      expect(event.aggregateKey, 'lexeme-1');
      final payload = jsonDecode(event.payloadJson) as Map<String, dynamic>;
      expect(payload['cardType'], 'lexeme');
      expect(payload['lexemeId'], 'lexeme-1');
      expect(payload['sourceBookFingerprint'], isNotNull);
      expect(payload['sourceBookTitle'], 'Kokoro');
      for (final forbidden in [
        'content',
        'chapterContent',
        'originalFile',
        'filePath',
        'fullChapter',
        'fullBook',
        'translatedText',
      ]) {
        expect(payload, isNot(containsPair(forbidden, anything)));
      }
    },
  );

  test('saving same owner and lexeme twice is local idempotent', () async {
    final apiClient = _FakeVocabularyApiClient();
    final wordCardRepository = _FakeLocalWordCardRepository();
    final statsRepository = _FakeStudyStatsRepository();
    final controller = _controller(
      apiClient: apiClient,
      wordCardRepository: wordCardRepository,
      statsRepository: statsRepository,
    );

    await controller.saveLookupLexeme(
      _lookupLexeme(),
      now: DateTime.utc(2026, 5, 8),
    );
    await controller.saveLookupLexeme(
      _lookupLexeme(),
      now: DateTime.utc(2026, 5, 8),
    );

    expect(apiClient.lexemeCalls, hasLength(1));
    expect(wordCardRepository.saved, hasLength(1));
    expect(statsRepository.increments, hasLength(1));
    expect(controller.state.status, SaveVocabularyStatus.alreadySaved);
  });
}

SaveVocabularyController _controller({
  _FakeVocabularyApiClient? apiClient,
  _FakeLocalLexemeRepository? lexemeRepository,
  _FakeLocalWordCardRepository? wordCardRepository,
  _FakePendingSyncEventRepository? pendingRepository,
  _FakeStudyStatsRepository? statsRepository,
}) {
  return SaveVocabularyController(
    ownerUserId: 'user-1',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    apiClient: apiClient ?? _FakeVocabularyApiClient(),
    lexemeRepository: lexemeRepository ?? _FakeLocalLexemeRepository(),
    wordCardRepository: wordCardRepository ?? _FakeLocalWordCardRepository(),
    pendingRepository: pendingRepository ?? _FakePendingSyncEventRepository(),
    statsRepository: statsRepository ?? _FakeStudyStatsRepository(),
  );
}

LookupLexeme _lookupLexeme() {
  return const LookupLexeme(
    id: 'lexeme-1',
    surface: '心',
    reading: 'こころ',
    entryType: 'word',
    partOfSpeech: 'noun',
    definition: 'heart; mind',
    shortDefinition: 'heart',
  );
}

DioException _offlineError() {
  return DioException.connectionError(
    requestOptions: RequestOptions(path: '/api/v1/vocabulary/cards'),
    reason: 'offline',
  );
}

class _LexemeCall {
  const _LexemeCall({required this.lexemeId});

  final String lexemeId;
}

class _FakeVocabularyApiClient extends VocabularyApiClient {
  _FakeVocabularyApiClient({this.error}) : super(dio: Dio());

  final Object? error;
  final List<_LexemeCall> lexemeCalls = [];

  @override
  Future<VocabularyCardResult> createLexemeCard({
    required String lexemeId,
    String? sourceBookFingerprint,
    String? sourceBookTitle,
  }) async {
    lexemeCalls.add(_LexemeCall(lexemeId: lexemeId));
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return const VocabularyCardResult(
      existing: false,
      card: VocabularyCard(
        id: 'server-card-1',
        cardType: 'lexeme',
        reviewStatus: 'new',
        reviewCount: 0,
      ),
    );
  }
}

class _FakeLocalLexemeRepository implements LocalLexemeRepository {
  final List<LocalLexeme> saved = [];

  @override
  Future<LocalLexeme?> findById(String id) async => null;

  @override
  Future<void> upsert(LocalLexeme lexeme) async {
    saved.add(lexeme);
  }
}

class _FakeLocalWordCardRepository implements LocalWordCardRepository {
  final List<LocalWordCard> saved = [];

  @override
  Future<LocalWordCard?> findByOwnerUserIdAndLexemeId({
    required String ownerUserId,
    required String lexemeId,
  }) async {
    return saved
        .where(
          (card) =>
              card.ownerUserId == ownerUserId && card.lexemeId == lexemeId,
        )
        .firstOrNull;
  }

  @override
  Future<void> upsert(LocalWordCard card) async {
    if (await findByOwnerUserIdAndLexemeId(
          ownerUserId: card.ownerUserId,
          lexemeId: card.lexemeId!,
        ) ==
        null) {
      saved.add(card);
    }
  }

  @override
  Future<LocalWordCard?> findById(String id) async => null;

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async =>
      saved;

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    return const [];
  }

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    return const [];
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
}

class _FakePendingSyncEventRepository implements PendingSyncEventRepository {
  final List<PendingSyncEvent> saved = [];

  @override
  Future<int> insert(PendingSyncEvent event) async {
    saved.add(event);
    return 1;
  }

  @override
  Future<List<PendingSyncEvent>> findPendingByOwnerUserId(
    String ownerUserId,
  ) async {
    return saved;
  }
}

class _StatsIncrement {
  const _StatsIncrement({required this.cardsCreated});

  final int cardsCreated;
}

class _FakeStudyStatsRepository implements LocalStudyStatsRepository {
  final List<_StatsIncrement> increments = [];

  @override
  Future<List<LocalStudyDailyStat>> findByOwnerUserId(
    String ownerUserId,
  ) async {
    return const [];
  }

  @override
  Future<LocalStudyDailyStat?> findByOwnerUserIdAndStatDate({
    required String ownerUserId,
    required DateTime statDate,
  }) async {
    return null;
  }

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
    increments.add(_StatsIncrement(cardsCreated: cardsCreated));
    return LocalStudyDailyStat(
      id: 'stat-1',
      ownerUserId: ownerUserId,
      statDate: statDate,
      readingMinutes: readingMinutes,
      lookupCount: lookupCount,
      paragraphTranslationCount: paragraphTranslationCount,
      cardsCreated: cardsCreated,
      cardsReviewed: cardsReviewed,
      syncStatus: 'dirty',
      createdAt: DateTime.utc(2026, 5, 8),
      updatedAt: DateTime.utc(2026, 5, 8),
    );
  }
}
