import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../../core/network/api_error.dart';
import '../../stats/data/local_study_stats_repository.dart';
import '../../stats/domain/local_study_daily_stat.dart';
import '../data/local_lexeme_repository.dart';
import '../data/study_api_client.dart';
import '../domain/local_lexeme.dart';
import '../domain/lookup_result.dart';
import '../domain/reader_text_selection.dart';

enum LookupStatus { idle, loading, success, notFound, offline, error }

class LookupState {
  const LookupState._({
    required this.status,
    this.result,
    this.message,
  });

  const LookupState.idle() : this._(status: LookupStatus.idle);

  const LookupState.loading() : this._(status: LookupStatus.loading);

  const LookupState.success(LookupResult result)
    : this._(status: LookupStatus.success, result: result);

  const LookupState.notFound([String? message])
    : this._(status: LookupStatus.notFound, message: message);

  const LookupState.offline()
    : this._(
        status: LookupStatus.offline,
        message: '离线状态下暂时无法查词。',
      );

  const LookupState.error(String message)
    : this._(status: LookupStatus.error, message: message);

  final LookupStatus status;
  final LookupResult? result;
  final String? message;
}

class LookupController extends ChangeNotifier {
  LookupController({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required StudyApiClient apiClient,
    required LocalLexemeRepository lexemeRepository,
    required LocalStudyStatsRepository statsRepository,
  }) : _ownerUserId = ownerUserId,
       _sourceLang = sourceLang,
       _targetLang = targetLang,
       _apiClient = apiClient,
       _lexemeRepository = lexemeRepository,
       _statsRepository = statsRepository;

  LookupController.test()
    : _ownerUserId = '',
      _sourceLang = 'ja',
      _targetLang = 'zh-CN',
      _apiClient = StudyApiClient(),
      _lexemeRepository = _NoopLocalLexemeRepository(),
      _statsRepository = _NoopStudyStatsRepository();

  static Future<LookupController> local({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
  }) async {
    final database = await MobileDatabase().open();
    return LookupController(
      ownerUserId: ownerUserId,
      sourceLang: sourceLang,
      targetLang: targetLang,
      apiClient: StudyApiClient(),
      lexemeRepository: LocalLexemeRepository(database),
      statsRepository: LocalStudyStatsRepository(database),
    );
  }

  final String _ownerUserId;
  final String _sourceLang;
  final String _targetLang;
  final StudyApiClient _apiClient;
  final LocalLexemeRepository _lexemeRepository;
  final LocalStudyStatsRepository _statsRepository;

  LookupState state = const LookupState.idle();

  Future<void> lookup(ReaderTextSelection selection, {DateTime? now}) async {
    final selectedText = selection.selectedText.trim();
    if (selectedText.isEmpty) {
      state = const LookupState.notFound('没有选择文本。');
      notifyListeners();
      return;
    }

    state = const LookupState.loading();
    notifyListeners();

    try {
      final result = await _apiClient.lookup(
        text: selectedText,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        context: selection.paragraphContext,
      );
      if (result.provider == 'public_lexeme') {
        await _cacheLexeme(result);
      }
      await _incrementLookupCount(now ?? DateTime.now().toUtc());
      state = LookupState.success(result);
    } on ApiError catch (error) {
      state = _stateFromApiError(error);
    } on DioException catch (error) {
      state = _stateFromDioError(error);
    } catch (_) {
      state = const LookupState.error('查词失败。');
    }
    notifyListeners();
  }

  Future<void> _cacheLexeme(LookupResult result) async {
    final lexeme = result.lexeme;
    final now = DateTime.now().toUtc();
    await _lexemeRepository.upsert(
      LocalLexeme(
        id: lexeme.id,
        surface: lexeme.surface,
        reading: lexeme.reading,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        entryType: lexeme.entryType,
        partOfSpeech: lexeme.partOfSpeech,
        definition: lexeme.definition,
        shortDefinition: lexeme.shortDefinition,
        cachedAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _incrementLookupCount(DateTime now) {
    return _statsRepository.increment(
      ownerUserId: _ownerUserId,
      statDate: DateTime.utc(now.year, now.month, now.day),
      readingMinutes: 0,
      lookupCount: 1,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: 0,
    );
  }

  LookupState _stateFromApiError(ApiError error) {
    return switch (error.code) {
      'LEXEME_NOT_FOUND' || 'NOT_FOUND' => LookupState.notFound(error.message),
      'STUDY_PROVIDER_UNAVAILABLE' => LookupState.error(error.message),
      _ => LookupState.error(error.message),
    };
  }

  LookupState _stateFromDioError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const LookupState.offline(),
      _ => const LookupState.error('查词失败。'),
    };
  }
}

class _NoopLocalLexemeRepository implements LocalLexemeRepository {
  @override
  Future<LocalLexeme?> findById(String id) async => null;

  @override
  Future<void> upsert(LocalLexeme lexeme) async {}
}

class _NoopStudyStatsRepository implements LocalStudyStatsRepository {
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
    throw StateError('LookupController.test cannot increment stats.');
  }
}
