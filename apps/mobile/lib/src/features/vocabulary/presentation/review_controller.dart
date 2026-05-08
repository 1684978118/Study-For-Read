import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../auth/data/auth_token_store.dart';
import '../../stats/data/local_study_stats_repository.dart';
import '../../sync/data/pending_sync_event_repository.dart';
import '../../sync/domain/pending_sync_event.dart';
import '../data/local_word_card_repository.dart';
import '../domain/review_result.dart';
import '../domain/review_scheduler.dart';

class ReviewController extends ChangeNotifier {
  ReviewController({
    required String ownerUserId,
    required LocalWordCardRepository wordCardRepository,
    required PendingSyncEventRepository pendingRepository,
    required LocalStudyStatsRepository statsRepository,
    ReviewScheduler scheduler = const ReviewScheduler(),
    DateTime Function()? now,
  }) : _ownerUserId = ownerUserId,
       _wordCardRepository = wordCardRepository,
       _pendingRepository = pendingRepository,
       _statsRepository = statsRepository,
       _scheduler = scheduler,
       _now = now ?? DateTime.now;

  final String _ownerUserId;
  final LocalWordCardRepository _wordCardRepository;
  final PendingSyncEventRepository _pendingRepository;
  final LocalStudyStatsRepository _statsRepository;
  final ReviewScheduler _scheduler;
  final DateTime Function() _now;

  bool _isReviewing = false;
  String? _errorMessage;

  bool get isReviewing => _isReviewing;
  String? get errorMessage => _errorMessage;

  static Future<ReviewController> local() async {
    final ownerUserId = await _readCurrentUserId(SecureAuthTokenStore());
    final database = await MobileDatabase().open();
    return ReviewController(
      ownerUserId: ownerUserId,
      wordCardRepository: LocalWordCardRepository(database),
      pendingRepository: PendingSyncEventRepository(database),
      statsRepository: LocalStudyStatsRepository(database),
    );
  }

  Future<ReviewResult> reviewCard({
    required String cardId,
    required bool known,
  }) async {
    _isReviewing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final card = await _wordCardRepository.findById(cardId);
      if (card == null || card.ownerUserId != _ownerUserId) {
        throw StateError('Card not found for current user');
      }

      final reviewedAt = _now().toUtc();
      final result = _scheduler.schedule(
        known: known,
        currentReviewCount: card.reviewCount,
        reviewedAt: reviewedAt,
      );

      final updatedRows = await _wordCardRepository.updateReviewState(
        id: card.id,
        reviewStatus: result.reviewStatus,
        reviewCount: result.reviewCount,
        nextReviewAt: result.nextReviewAt,
        lastReviewedAt: result.lastReviewedAt,
        syncStatus: 'dirty',
        updatedAt: reviewedAt,
      );
      if (updatedRows != 1) {
        throw StateError('Card not found for current user');
      }

      await _enqueueReview(
        cardId: card.id,
        serverCardId: card.serverCardId,
        known: known,
        result: result,
        createdAt: reviewedAt,
      );
      await _incrementCardsReviewed(reviewedAt);
      return result;
    } catch (error) {
      _errorMessage = 'Could not review this card.';
      rethrow;
    } finally {
      _isReviewing = false;
      notifyListeners();
    }
  }

  Future<void> _enqueueReview({
    required String cardId,
    required String? serverCardId,
    required bool known,
    required ReviewResult result,
    required DateTime createdAt,
  }) {
    final payload = <String, Object?>{
      'cardId': cardId,
      'serverCardId': serverCardId,
      'known': known,
      'reviewedAt': result.reviewedAt.toIso8601String(),
      'reviewStatus': result.reviewStatus,
      'reviewCount': result.reviewCount,
      'nextReviewAt': result.nextReviewAt.toIso8601String(),
      'lastReviewedAt': result.lastReviewedAt.toIso8601String(),
    };
    return _pendingRepository.insert(
      PendingSyncEvent(
        id: _uuidV4(),
        ownerUserId: _ownerUserId,
        eventType: 'word_card_review',
        aggregateKey: serverCardId ?? cardId,
        payloadJson: jsonEncode(payload),
        status: 'pending',
        attemptCount: 0,
        lastErrorCode: null,
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
  }

  Future<void> _incrementCardsReviewed(DateTime reviewedAt) {
    return _statsRepository.increment(
      ownerUserId: _ownerUserId,
      statDate: DateTime.utc(reviewedAt.year, reviewedAt.month, reviewedAt.day),
      readingMinutes: 0,
      lookupCount: 0,
      paragraphTranslationCount: 0,
      cardsCreated: 0,
      cardsReviewed: 1,
    );
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

  static Future<String> _readCurrentUserId(AuthTokenStore tokenStore) async {
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Missing access token');
    }

    final parts = accessToken.split('.');
    if (parts.length != 3 || parts[0] != 'access') {
      throw StateError('Invalid access token');
    }

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final payloadParts = payload.split(':');
    if (payloadParts.length != 3 || payloadParts.first.isEmpty) {
      throw StateError('Invalid access token payload');
    }

    return payloadParts.first;
  }
}
