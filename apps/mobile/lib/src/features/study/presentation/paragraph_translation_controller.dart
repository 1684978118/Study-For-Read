import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../../core/network/api_error.dart';
import '../../stats/data/local_study_stats_repository.dart';
import '../../stats/domain/local_study_daily_stat.dart';
import '../data/local_translation_cache_repository.dart';
import '../data/study_api_client.dart';
import '../domain/local_translation_cache_entry.dart';
import '../domain/paragraph_selection.dart';

enum ParagraphTranslationStatus {
  idle,
  loading,
  cached,
  success,
  offline,
  error,
}

class ParagraphTranslationState {
  const ParagraphTranslationState._({
    required this.status,
    this.translatedText,
    this.provider,
    this.message,
  });

  const ParagraphTranslationState.idle()
    : this._(status: ParagraphTranslationStatus.idle);

  const ParagraphTranslationState.loading()
    : this._(status: ParagraphTranslationStatus.loading);

  const ParagraphTranslationState.cached({
    required String translatedText,
    String? provider,
  }) : this._(
         status: ParagraphTranslationStatus.cached,
         translatedText: translatedText,
         provider: provider,
       );

  const ParagraphTranslationState.success({
    required String translatedText,
    required String provider,
  }) : this._(
         status: ParagraphTranslationStatus.success,
         translatedText: translatedText,
         provider: provider,
       );

  const ParagraphTranslationState.offline()
    : this._(
        status: ParagraphTranslationStatus.offline,
        message: 'Paragraph translation is unavailable offline.',
      );

  const ParagraphTranslationState.error(String message)
    : this._(status: ParagraphTranslationStatus.error, message: message);

  final ParagraphTranslationStatus status;
  final String? translatedText;
  final String? provider;
  final String? message;
}

class ParagraphTranslationController extends ChangeNotifier {
  ParagraphTranslationController({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required StudyApiClient apiClient,
    required LocalTranslationCacheRepository cacheRepository,
    required LocalStudyStatsRepository statsRepository,
  }) : _ownerUserId = ownerUserId,
       _sourceLang = sourceLang,
       _targetLang = targetLang,
       _apiClient = apiClient,
       _cacheRepository = cacheRepository,
       _statsRepository = statsRepository;

  ParagraphTranslationController.test()
    : _ownerUserId = '',
      _sourceLang = 'ja',
      _targetLang = 'zh-CN',
      _apiClient = StudyApiClient(),
      _cacheRepository = _NoopTranslationCacheRepository(),
      _statsRepository = _NoopStudyStatsRepository();

  static Future<ParagraphTranslationController> local({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
  }) async {
    final database = await MobileDatabase().open();
    return ParagraphTranslationController(
      ownerUserId: ownerUserId,
      sourceLang: sourceLang,
      targetLang: targetLang,
      apiClient: StudyApiClient(),
      cacheRepository: LocalTranslationCacheRepository(database),
      statsRepository: LocalStudyStatsRepository(database),
    );
  }

  final String _ownerUserId;
  final String _sourceLang;
  final String _targetLang;
  final StudyApiClient _apiClient;
  final LocalTranslationCacheRepository _cacheRepository;
  final LocalStudyStatsRepository _statsRepository;
  final Map<String, ParagraphTranslationState> _statesByHash = {};

  ParagraphTranslationState state = const ParagraphTranslationState.idle();

  ParagraphTranslationState stateFor(ParagraphSelection selection) {
    return _statesByHash[_sourceTextHash(selection.selectedParagraphText)] ??
        const ParagraphTranslationState.idle();
  }

  Future<void> translate(ParagraphSelection selection, {DateTime? now}) async {
    final selectedParagraph = selection.selectedParagraphText.trim();
    if (selectedParagraph.isEmpty) {
      _setState(
        selection,
        const ParagraphTranslationState.error('No paragraph selected.'),
      );
      return;
    }

    final sourceTextHash = _sourceTextHash(selectedParagraph);
    final cached = await _cacheRepository
        .findByOwnerAndLanguagePairAndSourceTextHash(
          ownerUserId: _ownerUserId,
          sourceLang: _sourceLang,
          targetLang: _targetLang,
          sourceTextHash: sourceTextHash,
        );
    if (cached != null) {
      _setState(
        selection,
        ParagraphTranslationState.cached(
          translatedText: cached.translatedText,
          provider: cached.provider,
        ),
      );
      return;
    }

    _setState(selection, const ParagraphTranslationState.loading());

    try {
      final result = await _apiClient.translateParagraph(
        text: selectedParagraph,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
      );
      await _cacheTranslation(
        selection: selection,
        sourceTextHash: sourceTextHash,
        translatedText: result.translatedText,
        provider: result.provider,
      );
      await _incrementParagraphTranslationCount(now ?? DateTime.now().toUtc());
      _setState(
        selection,
        ParagraphTranslationState.success(
          translatedText: result.translatedText,
          provider: result.provider,
        ),
      );
    } on ApiError catch (error) {
      _setState(selection, ParagraphTranslationState.error(error.message));
    } on DioException catch (error) {
      _setState(selection, _stateFromDioError(error));
    } catch (_) {
      _setState(
        selection,
        const ParagraphTranslationState.error('Paragraph translation failed.'),
      );
    }
  }

  @visibleForTesting
  void setStateForTesting(
    ParagraphSelection selection,
    ParagraphTranslationState nextState,
  ) {
    _setState(selection, nextState);
  }

  Future<void> _cacheTranslation({
    required ParagraphSelection selection,
    required String sourceTextHash,
    required String translatedText,
    required String provider,
  }) async {
    final now = DateTime.now().toUtc();
    await _cacheRepository.upsert(
      LocalTranslationCacheEntry(
        id: _uuidV4(),
        ownerUserId: _ownerUserId,
        bookFingerprint: selection.bookFingerprint,
        chapterIndex: selection.chapterIndex,
        paragraphIndex: selection.paragraphIndex,
        sourceTextHash: sourceTextHash,
        sourceTextPreview: _preview(selection.selectedParagraphText),
        translatedText: translatedText,
        sourceLang: _sourceLang,
        targetLang: _targetLang,
        provider: provider,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _incrementParagraphTranslationCount(DateTime now) {
    return _statsRepository.increment(
      ownerUserId: _ownerUserId,
      statDate: DateTime.utc(now.year, now.month, now.day),
      readingMinutes: 0,
      lookupCount: 0,
      paragraphTranslationCount: 1,
      cardsCreated: 0,
      cardsReviewed: 0,
    );
  }

  ParagraphTranslationState _stateFromDioError(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionError ||
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout => const ParagraphTranslationState.offline(),
      _ => const ParagraphTranslationState.error(
        'Paragraph translation failed.',
      ),
    };
  }

  void _setState(
    ParagraphSelection selection,
    ParagraphTranslationState nextState,
  ) {
    _statesByHash[_sourceTextHash(selection.selectedParagraphText)] = nextState;
    state = nextState;
    notifyListeners();
  }

  String _sourceTextHash(String text) {
    return sha256.convert(utf8.encode(text.trim())).toString();
  }

  String _preview(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 120) {
      return trimmed;
    }
    return trimmed.substring(0, 120);
  }

  String _uuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0'));
    final value = hex.join();
    return '${value.substring(0, 8)}-'
        '${value.substring(8, 12)}-'
        '${value.substring(12, 16)}-'
        '${value.substring(16, 20)}-'
        '${value.substring(20)}';
  }
}

class _NoopTranslationCacheRepository
    implements LocalTranslationCacheRepository {
  @override
  Future<LocalTranslationCacheEntry?>
  findByOwnerAndLanguagePairAndSourceTextHash({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required String sourceTextHash,
  }) async {
    return null;
  }

  @override
  Future<void> upsert(LocalTranslationCacheEntry entry) async {}
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
    throw StateError(
      'ParagraphTranslationController.test cannot increment stats.',
    );
  }
}
