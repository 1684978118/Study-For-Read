import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/local_study_daily_stat.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_translation_cache_repository.dart';
import 'package:study_for_read_mobile/src/features/study/data/study_api_client.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_translation_cache_entry.dart';
import 'package:study_for_read_mobile/src/features/study/domain/paragraph_selection.dart';
import 'package:study_for_read_mobile/src/features/study/domain/translation_result.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/paragraph_translation_controller.dart';

void main() {
  test('translates exactly one selected paragraph', () async {
    final apiClient = _FakeStudyApiClient();
    final controller = _controller(apiClient: apiClient);

    await controller.translate(
      const ParagraphSelection(
        selectedParagraphText: '最初の段落です。',
        bookFingerprint:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        chapterIndex: 0,
        paragraphIndex: 1,
      ),
    );

    expect(apiClient.translateCalls, ['最初の段落です。']);
    expect(apiClient.translateCalls.single, isNot(contains('次の段落')));
    expect(controller.state.status, ParagraphTranslationStatus.success);
    expect(controller.state.translatedText, '第一段译文');
  });

  test('returns cached translation without a second api call', () async {
    final cacheRepository = _FakeTranslationCacheRepository(
      cachedTranslatedText: '缓存译文',
    );
    final apiClient = _FakeStudyApiClient();
    final controller = _controller(
      apiClient: apiClient,
      cacheRepository: cacheRepository,
    );

    await controller.translate(
      const ParagraphSelection(selectedParagraphText: '同じ段落です。'),
    );

    expect(apiClient.translateCalls, isEmpty);
    expect(cacheRepository.findCalls, hasLength(1));
    expect(cacheRepository.findCalls.single.sourceTextHash, hasLength(64));
    expect(
      cacheRepository.findCalls.single.sourceTextHash,
      matches(r'^[0-9a-f]+$'),
    );
    expect(controller.state.status, ParagraphTranslationStatus.cached);
    expect(controller.state.translatedText, '缓存译文');
  });

  test(
    'successful online translation writes cache and increments stats',
    () async {
      final cacheRepository = _FakeTranslationCacheRepository();
      final statsRepository = _FakeStudyStatsRepository();
      final controller = _controller(
        apiClient: _FakeStudyApiClient(),
        cacheRepository: cacheRepository,
        statsRepository: statsRepository,
      );

      await controller.translate(
        const ParagraphSelection(
          selectedParagraphText: '翻訳する段落です。',
          paragraphIndex: 2,
        ),
        now: DateTime.utc(2026, 5, 8, 10),
      );

      expect(cacheRepository.saved, hasLength(1));
      expect(cacheRepository.saved.single.ownerUserId, 'user-1');
      expect(cacheRepository.saved.single.translatedText, '第一段译文');
      expect(cacheRepository.saved.single.sourceTextPreview, '翻訳する段落です。');
      expect(cacheRepository.saved.single.paragraphIndex, 2);
      expect(statsRepository.increments, hasLength(1));
      expect(statsRepository.increments.single.paragraphTranslationCount, 1);
      expect(
        statsRepository.increments.single.statDate,
        DateTime.utc(2026, 5, 8),
      );
    },
  );

  test('offline with cached result shows cached translation', () async {
    final controller = _controller(
      apiClient: _FakeStudyApiClient(error: _offlineError()),
      cacheRepository: _FakeTranslationCacheRepository(
        cachedTranslatedText: '离线缓存译文',
      ),
    );

    await controller.translate(
      const ParagraphSelection(selectedParagraphText: 'キャッシュ済み段落。'),
    );

    expect(controller.state.status, ParagraphTranslationStatus.cached);
    expect(controller.state.translatedText, '离线缓存译文');
  });

  test(
    'offline without cached result shows offline unavailable state',
    () async {
      final controller = _controller(
        apiClient: _FakeStudyApiClient(error: _offlineError()),
      );

      await controller.translate(
        const ParagraphSelection(selectedParagraphText: '未缓存段落。'),
      );

      expect(controller.state.status, ParagraphTranslationStatus.offline);
      expect(controller.state.message, contains('离线'));
    },
  );
}

ParagraphTranslationController _controller({
  _FakeStudyApiClient? apiClient,
  _FakeTranslationCacheRepository? cacheRepository,
  _FakeStudyStatsRepository? statsRepository,
}) {
  return ParagraphTranslationController(
    ownerUserId: 'user-1',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    apiClient: apiClient ?? _FakeStudyApiClient(),
    cacheRepository: cacheRepository ?? _FakeTranslationCacheRepository(),
    statsRepository: statsRepository ?? _FakeStudyStatsRepository(),
  );
}

DioException _offlineError() {
  return DioException.connectionError(
    requestOptions: RequestOptions(path: '/api/v1/study/translate-paragraph'),
    reason: 'offline',
  );
}

class _FakeStudyApiClient extends StudyApiClient {
  _FakeStudyApiClient({this.error}) : super(dio: Dio());

  final Object? error;
  final List<String> translateCalls = [];

  @override
  Future<TranslationResult> translateParagraph({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    translateCalls.add(text);
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return const TranslationResult(
      translatedText: '第一段译文',
      provider: 'fallback',
      cached: false,
    );
  }
}

class _FindCall {
  const _FindCall({required this.sourceTextHash});

  final String sourceTextHash;
}

class _FakeTranslationCacheRepository
    implements LocalTranslationCacheRepository {
  _FakeTranslationCacheRepository({this.cachedTranslatedText});

  final String? cachedTranslatedText;
  final List<_FindCall> findCalls = [];
  final List<LocalTranslationCacheEntry> saved = [];

  @override
  Future<LocalTranslationCacheEntry?>
  findByOwnerAndLanguagePairAndSourceTextHash({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required String sourceTextHash,
  }) async {
    findCalls.add(_FindCall(sourceTextHash: sourceTextHash));
    final translatedText = cachedTranslatedText;
    if (translatedText == null) {
      return null;
    }
    final now = DateTime.utc(2026, 5, 8);
    return LocalTranslationCacheEntry(
      id: 'translation-cache-1',
      ownerUserId: ownerUserId,
      sourceTextHash: sourceTextHash,
      translatedText: translatedText,
      sourceLang: sourceLang,
      targetLang: targetLang,
      provider: 'cache',
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> upsert(LocalTranslationCacheEntry entry) async {
    saved.add(entry);
  }
}

class _StatsIncrement {
  const _StatsIncrement({
    required this.statDate,
    required this.paragraphTranslationCount,
  });

  final DateTime statDate;
  final int paragraphTranslationCount;
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
    increments.add(
      _StatsIncrement(
        statDate: DateTime.utc(statDate.year, statDate.month, statDate.day),
        paragraphTranslationCount: paragraphTranslationCount,
      ),
    );
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
