import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/api_error.dart';
import '../../library/data/local_book_repository.dart';
import '../../reader/data/local_reading_position_repository.dart';
import '../../reading_sync/data/reading_sync_api_client.dart';
import '../../stats/data/stats_api_client.dart';
import '../../vocabulary/data/local_word_card_repository.dart';
import '../../vocabulary/data/vocabulary_api_client.dart';
import '../../vocabulary/domain/local_word_card.dart';
import '../domain/pending_sync_event.dart';
import 'pending_sync_event_repository.dart';

typedef MarkEventDone = Future<void> Function(PendingSyncEvent event);
typedef MarkEventFailed =
    Future<void> Function(PendingSyncEvent event, String errorCode);
typedef MarkWordCardSynced =
    Future<void> Function(LocalWordCard card, String serverCardId);

class LearningSyncWorker {
  LearningSyncWorker({
    required PendingSyncEventRepository pendingRepository,
    required ReadingSyncApiClient readingSyncApiClient,
    required StatsApiClient statsApiClient,
    required VocabularyApiClient vocabularyApiClient,
    required LocalBookRepository localBookRepository,
    required LocalReadingPositionRepository readingPositionRepository,
    required LocalWordCardRepository wordCardRepository,
    MarkEventDone? markEventDone,
    MarkEventFailed? markEventFailed,
    MarkWordCardSynced? markWordCardSynced,
    DateTime Function()? now,
  }) : _pendingRepository = pendingRepository,
       _readingSyncApiClient = readingSyncApiClient,
       _statsApiClient = statsApiClient,
       _vocabularyApiClient = vocabularyApiClient,
       _localBookRepository = localBookRepository,
       _readingPositionRepository = readingPositionRepository,
       _wordCardRepository = wordCardRepository,
       _markEventDone =
           markEventDone ??
           ((event) => markPendingSyncEventDone(pendingRepository, event)),
       _markEventFailed =
           markEventFailed ??
           ((event, errorCode) => markPendingSyncEventFailed(
             pendingRepository,
             event,
             errorCode: errorCode,
           )),
       _markWordCardSynced =
           markWordCardSynced ??
           ((card, serverCardId) => markLocalWordCardSyncedWithServerCardId(
             wordCardRepository,
             card: card,
             serverCardId: serverCardId,
             updatedAt: now?.call() ?? DateTime.now().toUtc(),
           ));

  final PendingSyncEventRepository _pendingRepository;
  final ReadingSyncApiClient _readingSyncApiClient;
  final StatsApiClient _statsApiClient;
  final VocabularyApiClient _vocabularyApiClient;
  // Kept as explicit dependencies so the worker never needs chapter content or
  // translation cache repositories.
  // ignore: unused_field
  final LocalBookRepository _localBookRepository;
  // ignore: unused_field
  final LocalReadingPositionRepository _readingPositionRepository;
  final LocalWordCardRepository _wordCardRepository;
  final MarkEventDone _markEventDone;
  final MarkEventFailed _markEventFailed;
  final MarkWordCardSynced _markWordCardSynced;

  Future<void> syncPendingEventsForCurrentUser(String ownerUserId) async {
    final events = await _pendingRepository.findPendingByOwnerUserId(
      ownerUserId,
    );
    for (final event in events) {
      try {
        final handled = await _handleEvent(ownerUserId, event);
        if (handled) {
          await _markEventDone(event);
        }
      } catch (error) {
        await _markEventFailed(event, _errorCode(error));
      }
    }
  }

  Future<bool> _handleEvent(String ownerUserId, PendingSyncEvent event) async {
    final payload = _payload(event);
    switch (event.eventType) {
      case 'book_metadata':
        await _syncBookMetadata(payload);
        return true;
      case 'reading_progress':
        await _syncReadingProgress(payload);
        return true;
      case 'word_card_create':
        await _syncWordCardCreate(ownerUserId, payload);
        return true;
      case 'word_card_review':
        return _syncWordCardReview(payload);
      case 'daily_stats':
        await _syncDailyStats(payload);
        return true;
      default:
        throw ApiError(
          code: 'UNSUPPORTED_SYNC_EVENT',
          message: 'Unsupported event type ${event.eventType}',
        );
    }
  }

  Future<void> _syncBookMetadata(Map<String, Object?> payload) {
    return _readingSyncApiClient.upsertBookMetadata(
      bookFingerprint: payload.string('bookFingerprint'),
      title: payload.string('title'),
      author: payload.optionalString('author'),
      fileType: payload.string('fileType'),
      sourceLang: payload.string('sourceLang'),
      targetLang: payload.string('targetLang'),
      chapterCount: payload.integer('chapterCount'),
    );
  }

  Future<void> _syncReadingProgress(Map<String, Object?> payload) {
    return _readingSyncApiClient.updateReadingProgress(
      bookFingerprint: payload.string('bookFingerprint'),
      currentChapterIndex: payload.integer('currentChapterIndex'),
      currentParagraphIndex: payload.integer('currentParagraphIndex'),
      currentCharOffset: payload.integer('currentCharOffset'),
      lastReadAt: payload.optionalDateTime('lastReadAt'),
    );
  }

  Future<void> _syncWordCardCreate(
    String ownerUserId,
    Map<String, Object?> payload,
  ) async {
    final cardType = payload.string('cardType');
    if (cardType == 'lexeme') {
      final lexemeId = payload.string('lexemeId');
      final result = await _vocabularyApiClient.createLexemeCard(
        lexemeId: lexemeId,
        sourceBookFingerprint: payload.optionalString('sourceBookFingerprint'),
        sourceBookTitle: payload.optionalString('sourceBookTitle'),
      );
      final localCard = await _wordCardRepository.findByOwnerUserIdAndLexemeId(
        ownerUserId: ownerUserId,
        lexemeId: lexemeId,
      );
      if (localCard != null) {
        await _markWordCardSynced(localCard, result.card.id);
      }
      return;
    }

    if (cardType == 'private_sentence') {
      final result = await _vocabularyApiClient.createPrivateSentenceCard(
        privateSurface: payload.string('privateSurface'),
        privateDefinition: payload.string('privateDefinition'),
        privateContext: payload.optionalString('privateContext'),
        sourceBookFingerprint: payload.optionalString('sourceBookFingerprint'),
        sourceBookTitle: payload.optionalString('sourceBookTitle'),
      );
      final localCardId = payload.optionalString('cardId');
      if (localCardId != null) {
        final localCard = await _wordCardRepository.findById(localCardId);
        if (localCard != null && localCard.ownerUserId == ownerUserId) {
          await _markWordCardSynced(localCard, result.card.id);
        }
      }
      return;
    }

    throw ApiError(
      code: 'UNSUPPORTED_WORD_CARD_TYPE',
      message: 'Unsupported card type $cardType',
    );
  }

  Future<bool> _syncWordCardReview(Map<String, Object?> payload) async {
    final serverCardId = payload.optionalString('serverCardId');
    if (serverCardId == null || serverCardId.isEmpty) {
      return false;
    }
    await _vocabularyApiClient.reviewCard(
      cardId: serverCardId,
      known: payload.boolean('known'),
      reviewedAt: payload.dateTime('reviewedAt'),
    );
    return true;
  }

  Future<void> _syncDailyStats(Map<String, Object?> payload) {
    return _statsApiClient.addDailyStats(
      statDate: payload.date('statDate'),
      readingMinutes: payload.integer('readingMinutes'),
      lookupCount: payload.integer('lookupCount'),
      paragraphTranslationCount: payload.integer('paragraphTranslationCount'),
      cardsCreated: payload.integer('cardsCreated'),
      cardsReviewed: payload.integer('cardsReviewed'),
    );
  }

  Map<String, Object?> _payload(PendingSyncEvent event) {
    final decoded = jsonDecode(event.payloadJson);
    if (decoded is! Map) {
      throw const ApiError(
        code: 'INVALID_SYNC_PAYLOAD',
        message: 'Pending sync payload must be an object',
      );
    }
    return Map<String, Object?>.from(decoded);
  }

  String _errorCode(Object error) {
    if (error is ApiError) {
      return error.code;
    }
    if (error is DioException) {
      return error.response?.statusCode == null
          ? 'NETWORK_UNAVAILABLE'
          : 'HTTP_${error.response!.statusCode}';
    }
    return 'SYNC_FAILED';
  }
}

extension _SyncPayload on Map<String, Object?> {
  String string(String key) {
    final value = this[key];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    throw ApiError(
      code: 'INVALID_SYNC_PAYLOAD',
      message: 'Missing string field $key',
    );
  }

  String? optionalString(String key) {
    final value = this[key];
    if (value == null) {
      return null;
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  int integer(String key) {
    final value = this[key];
    if (value is int) {
      return value;
    }
    throw ApiError(
      code: 'INVALID_SYNC_PAYLOAD',
      message: 'Missing integer field $key',
    );
  }

  bool boolean(String key) {
    final value = this[key];
    if (value is bool) {
      return value;
    }
    throw ApiError(
      code: 'INVALID_SYNC_PAYLOAD',
      message: 'Missing boolean field $key',
    );
  }

  DateTime dateTime(String key) => DateTime.parse(string(key)).toUtc();

  DateTime? optionalDateTime(String key) {
    final value = optionalString(key);
    return value == null ? null : DateTime.parse(value).toUtc();
  }

  DateTime date(String key) {
    final parts = string(key).split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
