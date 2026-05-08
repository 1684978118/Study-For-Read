import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/local_study_daily_stat.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/data/study_api_client.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/study/domain/lookup_result.dart';
import 'package:study_for_read_mobile/src/features/study/domain/reader_text_selection.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_controller.dart';

void main() {
  test('sends selected text and paragraph context only', () async {
    final apiClient = _FakeStudyApiClient();
    final controller = _controller(apiClient: apiClient);

    await controller.lookup(
      const ReaderTextSelection(
        selectedText: '心',
        paragraphContext: '先生の心を知りたい。',
      ),
    );

    expect(apiClient.lookupCalls, hasLength(1));
    expect(apiClient.lookupCalls.single.text, '心');
    expect(apiClient.lookupCalls.single.context, '先生の心を知りたい。');
    expect(apiClient.lookupCalls.single.context, isNot(contains('第二段落')));
    expect(controller.state.status, LookupStatus.success);
  });

  test('caches public lexeme result and increments today lookup count', () async {
    final lexemeRepository = _FakeLocalLexemeRepository();
    final statsRepository = _FakeStudyStatsRepository();
    final controller = _controller(
      apiClient: _FakeStudyApiClient(),
      lexemeRepository: lexemeRepository,
      statsRepository: statsRepository,
    );

    await controller.lookup(
      const ReaderTextSelection(selectedText: '心'),
      now: DateTime.utc(2026, 5, 8, 10),
    );

    expect(lexemeRepository.saved, hasLength(1));
    expect(lexemeRepository.saved.single.id, 'lexeme-1');
    expect(lexemeRepository.saved.single.surface, '心');
    expect(statsRepository.increments, hasLength(1));
    expect(statsRepository.increments.single.lookupCount, 1);
    expect(statsRepository.increments.single.ownerUserId, 'user-1');
    expect(statsRepository.increments.single.statDate, DateTime.utc(2026, 5, 8));
  });

  test('maps provider unavailable to error state', () async {
    final controller = _controller(
      apiClient: _FakeStudyApiClient(
        error: const ApiError(
          code: 'STUDY_PROVIDER_UNAVAILABLE',
          message: 'Provider unavailable',
        ),
      ),
    );

    await controller.lookup(const ReaderTextSelection(selectedText: '心'));

    expect(controller.state.status, LookupStatus.error);
    expect(controller.state.message, contains('Provider unavailable'));
  });

  test('maps Dio connection errors to offline state', () async {
    final controller = _controller(
      apiClient: _FakeStudyApiClient(
        error: DioException.connectionError(
          requestOptions: RequestOptions(path: '/api/v1/study/lookup'),
          reason: 'offline',
        ),
      ),
    );

    await controller.lookup(const ReaderTextSelection(selectedText: '心'));

    expect(controller.state.status, LookupStatus.offline);
  });

  test('maps missing lexeme to not found state', () async {
    final controller = _controller(
      apiClient: _FakeStudyApiClient(
        error: const ApiError(code: 'LEXEME_NOT_FOUND', message: 'Not found'),
      ),
    );

    await controller.lookup(const ReaderTextSelection(selectedText: '???'));

    expect(controller.state.status, LookupStatus.notFound);
  });
}

LookupController _controller({
  _FakeStudyApiClient? apiClient,
  _FakeLocalLexemeRepository? lexemeRepository,
  _FakeStudyStatsRepository? statsRepository,
}) {
  return LookupController(
    ownerUserId: 'user-1',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    apiClient: apiClient ?? _FakeStudyApiClient(),
    lexemeRepository: lexemeRepository ?? _FakeLocalLexemeRepository(),
    statsRepository: statsRepository ?? _FakeStudyStatsRepository(),
  );
}

class _LookupCall {
  const _LookupCall({required this.text, this.context});

  final String text;
  final String? context;
}

class _FakeStudyApiClient extends StudyApiClient {
  _FakeStudyApiClient({this.error}) : super(dio: Dio());

  final Object? error;
  final List<_LookupCall> lookupCalls = [];

  @override
  Future<LookupResult> lookup({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? context,
  }) async {
    lookupCalls.add(_LookupCall(text: text, context: context));
    final error = this.error;
    if (error != null) {
      throw error;
    }
    return const LookupResult(
      kind: 'lexeme',
      lexeme: LookupLexeme(
        id: 'lexeme-1',
        surface: '心',
        reading: 'こころ',
        entryType: 'word',
        partOfSpeech: 'noun',
        definition: 'heart; mind',
        shortDefinition: 'heart',
      ),
      provider: 'public_lexeme',
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

class _StatsIncrement {
  const _StatsIncrement({
    required this.ownerUserId,
    required this.statDate,
    required this.lookupCount,
  });

  final String ownerUserId;
  final DateTime statDate;
  final int lookupCount;
}

class _FakeStudyStatsRepository implements LocalStudyStatsRepository {
  final List<_StatsIncrement> increments = [];

  @override
  Future<List<LocalStudyDailyStat>> findByOwnerUserId(String ownerUserId) async {
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
        ownerUserId: ownerUserId,
        statDate: DateTime.utc(statDate.year, statDate.month, statDate.day),
        lookupCount: lookupCount,
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
