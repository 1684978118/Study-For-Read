import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../../core/network/api_error.dart';
import '../../stats/data/local_study_stats_repository.dart';
import '../../stats/domain/local_study_daily_stat.dart';
import '../../study/data/local_lexeme_repository.dart';
import '../../study/domain/local_lexeme.dart';
import '../../study/domain/lookup_result.dart';
import '../../sync/data/pending_sync_event_repository.dart';
import '../../sync/domain/pending_sync_event.dart';
import '../data/local_word_card_repository.dart';
import '../data/vocabulary_api_client.dart';
import '../domain/local_word_card.dart';

enum SaveVocabularyStatus {
  idle,
  saving,
  saved,
  localOnly,
  alreadySaved,
  error,
}

class SaveVocabularyState {
  const SaveVocabularyState._({required this.status, this.message});

  const SaveVocabularyState.idle() : this._(status: SaveVocabularyStatus.idle);

  const SaveVocabularyState.saving()
    : this._(status: SaveVocabularyStatus.saving);

  const SaveVocabularyState.saved()
    : this._(status: SaveVocabularyStatus.saved);

  const SaveVocabularyState.localOnly()
    : this._(
        status: SaveVocabularyStatus.localOnly,
        message: '已保存到本地，稍后会同步。',
      );

  const SaveVocabularyState.alreadySaved()
    : this._(status: SaveVocabularyStatus.alreadySaved, message: '已保存');

  const SaveVocabularyState.error(String message)
    : this._(status: SaveVocabularyStatus.error, message: message);

  final SaveVocabularyStatus status;
  final String? message;
}

class SaveVocabularyController extends ChangeNotifier {
  SaveVocabularyController({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required VocabularyApiClient apiClient,
    required LocalLexemeRepository lexemeRepository,
    required LocalWordCardRepository wordCardRepository,
    required PendingSyncEventRepository pendingRepository,
    required LocalStudyStatsRepository statsRepository,
  }) : _ownerUserId = ownerUserId,
       _sourceLang = sourceLang,
       _targetLang = targetLang,
       _apiClient = apiClient,
       _lexemeRepository = lexemeRepository,
       _wordCardRepository = wordCardRepository,
       _pendingRepository = pendingRepository,
       _statsRepository = statsRepository;

  SaveVocabularyController.test()
    : _ownerUserId = '',
      _sourceLang = 'ja',
      _targetLang = 'zh-CN',
      _apiClient = VocabularyApiClient(),
      _lexemeRepository = _NoopLocalLexemeRepository(),
      _wordCardRepository = _NoopLocalWordCardRepository(),
      _pendingRepository = _NoopPendingSyncEventRepository(),
      _statsRepository = _NoopStudyStatsRepository();

  static Future<SaveVocabularyController> local({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
  }) async {
    final database = await MobileDatabase().open();
    return SaveVocabularyController(
      ownerUserId: ownerUserId,
      sourceLang: sourceLang,
      targetLang: targetLang,
      apiClient: VocabularyApiClient(),
      lexemeRepository: LocalLexemeRepository(database),
      wordCardRepository: LocalWordCardRepository(database),
      pendingRepository: PendingSyncEventRepository(database),
      statsRepository: LocalStudyStatsRepository(database),
    );
  }

  final String _ownerUserId;
  final String _sourceLang;
  final String _targetLang;
  final VocabularyApiClient _apiClient;
  final LocalLexemeRepository _lexemeRepository;
  final LocalWordCardRepository _wordCardRepository;
  final PendingSyncEventRepository _pendingRepository;
  final LocalStudyStatsRepository _statsRepository;

  SaveVocabularyState state = const SaveVocabularyState.idle();

  Future<void> saveLookupLexeme(
    LookupLexeme lexeme, {
    String? sourceBookFingerprint,
    String? sourceBookTitle,
    DateTime? now,
  }) async {
    final existing = await _wordCardRepository.findByOwnerUserIdAndLexemeId(
      ownerUserId: _ownerUserId,
      lexemeId: lexeme.id,
    );
    if (existing != null) {
      _setState(const SaveVocabularyState.alreadySaved());
      return;
    }

    _setState(const SaveVocabularyState.saving());
    await _cacheLexeme(lexeme);

    try {
      final result = await _apiClient.createLexemeCard(
        lexemeId: lexeme.id,
        sourceBookFingerprint: sourceBookFingerprint,
        sourceBookTitle: sourceBookTitle,
      );
      await _createLocalCard(
        lexeme: lexeme,
        serverCardId: result.card.id,
        sourceBookFingerprint: sourceBookFingerprint,
        sourceBookTitle: sourceBookTitle,
        syncStatus: 'synced',
        now: now,
      );
      _setState(const SaveVocabularyState.saved());
    } on DioException {
      await _saveLocalOnly(
        lexeme: lexeme,
        sourceBookFingerprint: sourceBookFingerprint,
        sourceBookTitle: sourceBookTitle,
        now: now,
      );
    } on ApiError {
      await _saveLocalOnly(
        lexeme: lexeme,
        sourceBookFingerprint: sourceBookFingerprint,
        sourceBookTitle: sourceBookTitle,
        now: now,
      );
    } catch (_) {
      await _saveLocalOnly(
        lexeme: lexeme,
        sourceBookFingerprint: sourceBookFingerprint,
        sourceBookTitle: sourceBookTitle,
        now: now,
      );
    }
  }

  @visibleForTesting
  void setStateForTesting(SaveVocabularyState nextState) {
    _setState(nextState);
  }

  Future<void> _saveLocalOnly({
    required LookupLexeme lexeme,
    required String? sourceBookFingerprint,
    required String? sourceBookTitle,
    required DateTime? now,
  }) async {
    await _createLocalCard(
      lexeme: lexeme,
      serverCardId: null,
      sourceBookFingerprint: sourceBookFingerprint,
      sourceBookTitle: sourceBookTitle,
      syncStatus: 'local_only',
      now: now,
    );
    await _enqueueWordCardCreate(
      lexeme: lexeme,
      sourceBookFingerprint: sourceBookFingerprint,
      sourceBookTitle: sourceBookTitle,
    );
    _setState(const SaveVocabularyState.localOnly());
  }

  Future<void> _cacheLexeme(LookupLexeme lexeme) async {
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

  Future<void> _createLocalCard({
    required LookupLexeme lexeme,
    required String? serverCardId,
    required String? sourceBookFingerprint,
    required String? sourceBookTitle,
    required String syncStatus,
    required DateTime? now,
  }) async {
    final timestamp = (now ?? DateTime.now()).toUtc();
    await _wordCardRepository.upsert(
      LocalWordCard(
        id: _uuidV4(),
        serverCardId: serverCardId,
        ownerUserId: _ownerUserId,
        cardType: 'lexeme',
        lexemeId: lexeme.id,
        sourceBookFingerprint: sourceBookFingerprint,
        sourceBookTitle: sourceBookTitle,
        reviewStatus: 'new',
        reviewCount: 0,
        syncStatus: syncStatus,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await _incrementCardsCreated(timestamp);
  }

  Future<void> _incrementCardsCreated(DateTime now) {
    return _statsRepository.increment(
      ownerUserId: _ownerUserId,
      statDate: DateTime.utc(now.year, now.month, now.day),
      readingMinutes: 0,
      lookupCount: 0,
      paragraphTranslationCount: 0,
      cardsCreated: 1,
      cardsReviewed: 0,
    );
  }

  Future<void> _enqueueWordCardCreate({
    required LookupLexeme lexeme,
    required String? sourceBookFingerprint,
    required String? sourceBookTitle,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = <String, Object?>{
      'cardType': 'lexeme',
      'lexemeId': lexeme.id,
      'surface': lexeme.surface,
      'reading': lexeme.reading,
      'entryType': lexeme.entryType,
      'partOfSpeech': lexeme.partOfSpeech,
      'definition': lexeme.definition,
      'shortDefinition': lexeme.shortDefinition,
      'sourceBookFingerprint': sourceBookFingerprint,
      'sourceBookTitle': sourceBookTitle,
    };
    await _pendingRepository.insert(
      PendingSyncEvent(
        id: _uuidV4(),
        ownerUserId: _ownerUserId,
        eventType: 'word_card_create',
        aggregateKey: lexeme.id,
        payloadJson: jsonEncode(payload),
        status: 'pending',
        attemptCount: 0,
        lastErrorCode: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  void _setState(SaveVocabularyState nextState) {
    state = nextState;
    notifyListeners();
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

class _NoopLocalLexemeRepository implements LocalLexemeRepository {
  @override
  Future<LocalLexeme?> findById(String id) async => null;

  @override
  Future<void> upsert(LocalLexeme lexeme) async {}
}

class _NoopLocalWordCardRepository implements LocalWordCardRepository {
  @override
  Future<LocalWordCard?> findByOwnerUserIdAndLexemeId({
    required String ownerUserId,
    required String lexemeId,
  }) async {
    return null;
  }

  @override
  Future<LocalWordCard?> findById(String id) async => null;

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async => [];

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    return [];
  }

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    return [];
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

class _NoopPendingSyncEventRepository implements PendingSyncEventRepository {
  @override
  Future<int> insert(PendingSyncEvent event) async => 1;

  @override
  Future<List<PendingSyncEvent>> findPendingByOwnerUserId(
    String ownerUserId,
  ) async {
    return [];
  }
}

class _NoopStudyStatsRepository implements LocalStudyStatsRepository {
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
    throw StateError('SaveVocabularyController.test cannot increment stats.');
  }
}
