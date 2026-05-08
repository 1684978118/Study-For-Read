import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_chapter.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_controller.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_screen.dart';
import 'package:study_for_read_mobile/src/features/reading_sync/data/reading_sync_api_client.dart';
import 'package:study_for_read_mobile/src/features/stats/data/local_study_stats_repository.dart';
import 'package:study_for_read_mobile/src/features/stats/data/stats_api_client.dart';
import 'package:study_for_read_mobile/src/features/stats/domain/local_study_daily_stat.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_controller.dart';
import 'package:study_for_read_mobile/src/features/stats/presentation/stats_screen.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_lexeme_repository.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_translation_cache_repository.dart';
import 'package:study_for_read_mobile/src/features/study/data/study_api_client.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_lexeme.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_translation_cache_entry.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_bottom_sheet.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_controller.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/paragraph_translation_controller.dart';
import 'package:study_for_read_mobile/src/features/sync/data/learning_sync_worker.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/vocabulary_api_client.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/review_scheduler.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/vocabulary_card.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_options.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_service.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/review_controller.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/save_vocabulary_controller.dart';

void main() {
  const ownerUserId = 'signed-in-user-1';
  const fingerprint =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  testWidgets(
    'mobile learning loop stays local-first and syncs metadata only',
    (tester) async {
      final http = _LearningLoopHttp();
      final studyApiClient = StudyApiClient(dio: _dio(http));
      final vocabularyApiClient = _FakeVocabularyApiClient(
        requestBodies: http.requestBodies,
        reviewCardIds: http.reviewCardIds,
      );
      final statsRepository = _FakeStudyStatsRepository();
      final lexemeRepository = _FakeLexemeRepository();
      final translationCacheRepository = _FakeTranslationCacheRepository();
      final wordCardRepository = _FakeWordCardRepository();
      final pendingRepository = _FakePendingSyncEventRepository();

      final lookupController = LookupController(
        ownerUserId: ownerUserId,
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        apiClient: studyApiClient,
        lexemeRepository: lexemeRepository,
        statsRepository: statsRepository,
      );
      final translationController = ParagraphTranslationController(
        ownerUserId: ownerUserId,
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        apiClient: studyApiClient,
        cacheRepository: translationCacheRepository,
        statsRepository: statsRepository,
      );
      final readerController = ReaderController(
        bookId: 'book-1',
        bookRepository: _FakeBookRepository(book: _book(ownerUserId)),
        chapterRepository: _FakeChapterRepository(chapters: _chapters()),
        positionRepository: _FakeReadingPositionRepository(saved: _position()),
        lookupController: lookupController,
        paragraphTranslationController: translationController,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReaderScreen(bookId: 'book-1', controller: readerController),
        ),
      );
      await _pumpUi(tester);

      expect(find.textContaining('先生の心'), findsOneWidget);

      await tester.tap(find.textContaining('先生の心'));
      await _pumpUi(tester);

      expect(find.byType(LookupBottomSheet), findsOneWidget);
      expect(find.text('心'), findsWidgets);
      expect(find.text('こころ'), findsOneWidget);
      expect(find.byTooltip('Pronounce'), findsOneWidget);
      expect(http.lookupTexts, ['心']);
      expect(http.lookupContexts.single, '先生の心。');
      expect(http.lookupContexts.single, isNot(contains('今日は静かです')));

      Navigator.of(tester.element(find.byType(LookupBottomSheet))).pop();
      await _pumpUi(tester);

      final saveController = SaveVocabularyController(
        ownerUserId: ownerUserId,
        sourceLang: 'ja',
        targetLang: 'zh-CN',
        apiClient: vocabularyApiClient,
        lexemeRepository: lexemeRepository,
        wordCardRepository: wordCardRepository,
        pendingRepository: pendingRepository,
        statsRepository: statsRepository,
      );
      final lookupResult = lookupController.state.result!;
      await saveController.saveLookupLexeme(
        lookupResult.lexeme,
        sourceBookFingerprint: fingerprint,
        sourceBookTitle: 'Kokoro',
        now: DateTime.utc(2026, 5, 9, 10),
      );

      expect(wordCardRepository.cards, hasLength(1));
      expect(wordCardRepository.cards.single.lexemeId, 'lexeme-heart');
      expect(wordCardRepository.cards.single.syncStatus, 'synced');
      expect(lexemeRepository.lexemes['lexeme-heart']?.reading, 'こころ');

      await tester.tap(find.byKey(const Key('paragraph-translate-hotspot-1')));
      await _pumpUntil(
        tester,
        () =>
            translationCacheRepository.entries.isNotEmpty &&
            statsRepository.statsByDate.values.any(
              (stat) => stat.paragraphTranslationCount == 1,
            ),
      );

      expect(http.translatedParagraphTexts, ['今日は静かです。']);
      expect(http.translatedParagraphTexts.single, isNot(contains('先生の心')));
      expect(find.text('今天很安静。'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('Save'), findsNothing);
      expect(find.text('Collapse'), findsNothing);
      expect(find.text('+'), findsNWidgets(2));
      expect(translationCacheRepository.entries, hasLength(1));
      expect(
        translationCacheRepository.entries.single.translatedText,
        '今天很安静。',
      );

      final savedCard = wordCardRepository.cards.single;
      final reviewController = ReviewController(
        ownerUserId: ownerUserId,
        wordCardRepository: wordCardRepository,
        pendingRepository: pendingRepository,
        statsRepository: statsRepository,
        scheduler: const ReviewScheduler(),
        now: () => DateTime.utc(2026, 5, 9, 11),
      );

      await reviewController.reviewCard(cardId: savedCard.id, known: false);

      final reviewedCard = wordCardRepository.cards.single;
      expect(reviewedCard.reviewStatus, 'learning');
      expect(reviewedCard.reviewCount, 1);
      expect(reviewedCard.syncStatus, 'dirty');
      expect(pendingRepository.events.single.eventType, 'word_card_review');

      final exportText = const AnkiExportService().exportText(
        cards: [
          _ankiCardFrom(
            reviewedCard,
            lexemeRepository.lexemes['lexeme-heart']!,
          ),
        ],
        options: const AnkiExportOptions(
          scope: AnkiExportScope.allCards,
          includeExamples: false,
          includeSourceMetadata: true,
        ),
      );
      expect(exportText, startsWith('#separator:Tab\n#html:true\n'));
      expect(
        exportText,
        contains('#columns:id\tfront\treading\tmeaning\tsource\ttags\taudio\n'),
      );
      expect(exportText, contains('${reviewedCard.id}\t心\tこころ\t'));
      expect(exportText, isNot(contains('D:/private')));
      expect(exportText, isNot(contains('先生の心。')));
      expect(exportText, isNot(contains('今天很安静。')));

      final statsController = StatsController(
        ownerUserId: ownerUserId,
        repository: statsRepository,
        now: () => DateTime.utc(2026, 5, 9, 12),
      );
      await tester.pumpWidget(
        MaterialApp(home: StatsScreen(controller: statsController)),
      );
      await _pumpUntil(
        tester,
        () => find.text('Lookups').evaluate().isNotEmpty,
      );

      expect(find.text('Lookups'), findsWidgets);
      expect(find.text('Paragraph translations'), findsWidgets);
      expect(find.text('Cards created'), findsWidgets);
      expect(find.text('Cards reviewed'), findsWidgets);
      expect(statsController.allTime.lookupCount, 1);
      expect(statsController.allTime.paragraphTranslationCount, 1);
      expect(statsController.allTime.cardsCreated, greaterThanOrEqualTo(1));
      expect(statsController.allTime.cardsReviewed, 1);

      final syncWorker = LearningSyncWorker(
        pendingRepository: pendingRepository,
        readingSyncApiClient: _FakeReadingSyncApiClient(),
        statsApiClient: _FakeStatsApiClient(),
        vocabularyApiClient: vocabularyApiClient,
        localBookRepository: _FakeBookRepository(book: _book(ownerUserId)),
        readingPositionRepository: _FakeReadingPositionRepository(
          saved: _position(),
        ),
        wordCardRepository: wordCardRepository,
        markEventDone: pendingRepository.markDone,
        markEventFailed: pendingRepository.markFailed,
        markWordCardSynced: wordCardRepository.markSynced,
      );

      final requestCountBeforeSync = http.requestBodies.length;
      await syncWorker.syncPendingEventsForCurrentUser(ownerUserId);

      expect(pendingRepository.doneEventIds, [
        pendingRepository.events.single.id,
      ]);
      expect(http.reviewCardIds, ['server-card-1']);
      for (final payload in [
        pendingRepository.events.single.payloadJson,
        ...http.requestBodies.skip(requestCountBeforeSync).map(jsonEncode),
      ]) {
        _expectNoForbiddenSyncContent(payload);
      }
    },
  );
}

Future<void> _pumpUi(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _pumpUntil(WidgetTester tester, bool Function() condition) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (condition()) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  fail('Timed out waiting for regression test condition.');
}

Dio _dio(HttpClientAdapter adapter) {
  return Dio(BaseOptions(baseUrl: 'https://api.example.test'))
    ..httpClientAdapter = adapter;
}

AnkiExportCard _ankiCardFrom(LocalWordCard card, LocalLexeme lexeme) {
  return AnkiExportCard(
    id: card.id,
    front: lexeme.surface,
    reading: lexeme.reading,
    meaning: lexeme.shortDefinition ?? lexeme.definition,
    source: card.sourceBookTitle,
    tags: [lexeme.sourceLang, lexeme.targetLang, lexeme.entryType],
  );
}

void _expectNoForbiddenSyncContent(String payload) {
  for (final forbidden in const [
    'originalFile',
    'original_file',
    'filePath',
    'file_path',
    'chapterContent',
    'chapter_content',
    'fullParagraph',
    'paragraphText',
    'translatedText',
    'D:/private',
    '先生の心。',
    '今日は静かです。',
    '今天很安静。',
  ]) {
    expect(payload, isNot(contains(forbidden)));
  }
}

LocalBook _book(String ownerUserId) {
  final now = DateTime.utc(2026, 5, 9);
  return LocalBook(
    id: 'book-1',
    ownerUserId: ownerUserId,
    bookFingerprint:
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    title: 'Kokoro',
    author: 'Natsume Soseki',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFilePath: 'D:/private/books/kokoro.txt',
    chapterCount: 1,
    metadataSyncStatus: 'local_only',
    lastOpenedAt: null,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

List<LocalChapter> _chapters() {
  final now = DateTime.utc(2026, 5, 9);
  return [
    LocalChapter(
      id: 'chapter-1',
      bookId: 'book-1',
      chapterIndex: 0,
      title: 'Chapter 1',
      content: '先生の心。\n\n今日は静かです。',
      paragraphCount: 2,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

LocalReadingPosition _position() {
  final now = DateTime.utc(2026, 5, 9);
  return LocalReadingPosition(
    id: 'position-1',
    bookId: 'book-1',
    currentChapterIndex: 0,
    currentParagraphIndex: 0,
    currentCharOffset: 0,
    progressSyncStatus: 'local_only',
    lastReadAt: now,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _LearningLoopHttp implements HttpClientAdapter {
  final lookupTexts = <String>[];
  final lookupContexts = <String?>[];
  final translatedParagraphTexts = <String>[];
  final reviewCardIds = <String>[];
  final requestBodies = <Map<String, Object?>>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final data = Map<String, Object?>.from((options.data as Map?) ?? {});
    requestBodies.add(data);

    if (options.path == '/api/v1/study/lookup') {
      lookupTexts.add(data['text'] as String);
      lookupContexts.add(data['context'] as String?);
      return _ok({
        'kind': 'lexeme',
        'provider': 'public_lexeme',
        'providerMessage': null,
        'lexeme': {
          'id': 'lexeme-heart',
          'surface': '心',
          'reading': 'こころ',
          'entryType': 'word',
          'partOfSpeech': 'noun',
          'definition': 'heart; mind',
          'shortDefinition': 'heart',
        },
      });
    }

    if (options.path == '/api/v1/study/translate-paragraph') {
      translatedParagraphTexts.add(data['text'] as String);
      return _ok({
        'translatedText': '今天很安静。',
        'provider': 'fake_provider',
        'cached': false,
        'message': null,
      });
    }

    if (options.path == '/api/v1/vocabulary/cards') {
      return _ok({
        'id': 'server-card-1',
        'cardType': 'lexeme',
        'reviewStatus': 'new',
        'reviewCount': 0,
      });
    }

    if (options.path == '/api/v1/vocabulary/cards/server-card-1/review') {
      reviewCardIds.add('server-card-1');
      return _ok({
        'id': 'server-card-1',
        'cardType': 'lexeme',
        'reviewStatus': 'learning',
        'reviewCount': 1,
        'lastReviewedAt': data['reviewedAt'],
      });
    }

    return _error('NOT_FOUND', 'Unexpected test request: ${options.path}');
  }

  ResponseBody _ok(Map<String, Object?> data) {
    return ResponseBody.fromString(
      jsonEncode({'success': true, 'data': data, 'error': null}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  ResponseBody _error(String code, String message) {
    return ResponseBody.fromString(
      jsonEncode({
        'success': false,
        'data': null,
        'error': {'code': code, 'message': message},
      }),
      404,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FakeVocabularyApiClient extends VocabularyApiClient {
  _FakeVocabularyApiClient({
    required this.requestBodies,
    required this.reviewCardIds,
  }) : super(dio: Dio());

  final List<Map<String, Object?>> requestBodies;
  final List<String> reviewCardIds;

  @override
  Future<VocabularyCardResult> createLexemeCard({
    required String lexemeId,
    String? sourceBookFingerprint,
    String? sourceBookTitle,
  }) async {
    requestBodies.add({
      'cardType': 'lexeme',
      'lexemeId': lexemeId,
      'sourceBookFingerprint': sourceBookFingerprint,
      'sourceBookTitle': sourceBookTitle,
    });
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

  @override
  Future<VocabularyCard> reviewCard({
    required String cardId,
    required bool known,
    required DateTime reviewedAt,
  }) async {
    reviewCardIds.add(cardId);
    requestBodies.add({
      'known': known,
      'reviewedAt': reviewedAt.toUtc().toIso8601String(),
    });
    return VocabularyCard(
      id: cardId,
      cardType: 'lexeme',
      reviewStatus: known ? 'known' : 'learning',
      reviewCount: 1,
      lastReviewedAt: reviewedAt.toUtc(),
    );
  }
}

class _FakeBookRepository implements LocalBookRepository {
  _FakeBookRepository({required this.book});

  final LocalBook? book;

  Future<LocalBook?> findById(String id) async => book;

  @override
  Future<LocalBook?> findByOwnerUserIdAndBookFingerprint({
    required String ownerUserId,
    required String bookFingerprint,
  }) async {
    return book?.ownerUserId == ownerUserId &&
            book?.bookFingerprint == bookFingerprint
        ? book
        : null;
  }

  @override
  Future<List<LocalBook>> findByOwnerUserId(String ownerUserId) async {
    final value = book;
    return value != null && value.ownerUserId == ownerUserId ? [value] : [];
  }

  @override
  Future<int> insert(LocalBook book) async => 1;

  @override
  Future<int> update(LocalBook book) async => 1;
}

class _FakeChapterRepository implements LocalChapterRepository {
  _FakeChapterRepository({required this.chapters});

  final List<LocalChapter> chapters;

  @override
  Future<int> deleteByBookId(String bookId) async => 0;

  @override
  Future<LocalChapter?> findByBookIdAndChapterIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    return chapters
        .where(
          (chapter) =>
              chapter.bookId == bookId && chapter.chapterIndex == chapterIndex,
        )
        .firstOrNull;
  }

  @override
  Future<List<LocalChapter>> findByBookIdOrderByChapterIndex(
    String bookId,
  ) async {
    return chapters
        .where((chapter) => chapter.bookId == bookId)
        .toList(growable: false);
  }

  @override
  Future<int> insert(LocalChapter chapter) async => 1;
}

class _FakeReadingPositionRepository implements LocalReadingPositionRepository {
  _FakeReadingPositionRepository({required this.saved});

  final LocalReadingPosition? saved;
  LocalReadingPosition? lastSaved;

  @override
  Future<LocalReadingPosition?> findByBookId(String bookId) async => saved;

  @override
  Future<void> upsert(LocalReadingPosition position) async {
    lastSaved = position;
  }
}

class _FakeLexemeRepository implements LocalLexemeRepository {
  final lexemes = <String, LocalLexeme>{};

  @override
  Future<LocalLexeme?> findById(String id) async => lexemes[id];

  @override
  Future<void> upsert(LocalLexeme lexeme) async {
    lexemes[lexeme.id] = lexeme;
  }
}

class _FakeTranslationCacheRepository
    implements LocalTranslationCacheRepository {
  final entries = <LocalTranslationCacheEntry>[];

  @override
  Future<LocalTranslationCacheEntry?>
  findByOwnerAndLanguagePairAndSourceTextHash({
    required String ownerUserId,
    required String sourceLang,
    required String targetLang,
    required String sourceTextHash,
  }) async {
    return entries
        .where(
          (entry) =>
              entry.ownerUserId == ownerUserId &&
              entry.sourceLang == sourceLang &&
              entry.targetLang == targetLang &&
              entry.sourceTextHash == sourceTextHash,
        )
        .firstOrNull;
  }

  @override
  Future<void> upsert(LocalTranslationCacheEntry entry) async {
    entries.add(entry);
  }
}

class _FakeWordCardRepository implements LocalWordCardRepository {
  final cards = <LocalWordCard>[];

  @override
  Future<LocalWordCard?> findById(String id) async {
    return cards.where((card) => card.id == id).firstOrNull;
  }

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
        .firstOrNull;
  }

  @override
  Future<List<LocalWordCard>> findByOwnerUserId(String ownerUserId) async {
    return cards
        .where((card) => card.ownerUserId == ownerUserId)
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findDueByOwnerUserId({
    required String ownerUserId,
    required DateTime dueAt,
  }) async {
    return cards
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              (card.nextReviewAt == null || !card.nextReviewAt!.isAfter(dueAt)),
        )
        .toList(growable: false);
  }

  @override
  Future<List<LocalWordCard>> findPrivateSentenceByOwnerUserId(
    String ownerUserId,
  ) async {
    return cards
        .where(
          (card) =>
              card.ownerUserId == ownerUserId &&
              card.cardType == 'private_sentence',
        )
        .toList(growable: false);
  }

  @override
  Future<void> upsert(LocalWordCard card) async {
    final index = cards.indexWhere((value) => value.id == card.id);
    if (index == -1) {
      cards.add(card);
    } else {
      cards[index] = card;
    }
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
    final index = cards.indexWhere((card) => card.id == id);
    if (index == -1) {
      return 0;
    }
    final card = cards[index];
    cards[index] = LocalWordCard(
      id: card.id,
      serverCardId: card.serverCardId,
      ownerUserId: card.ownerUserId,
      cardType: card.cardType,
      lexemeId: card.lexemeId,
      privateSurface: card.privateSurface,
      privateDefinition: card.privateDefinition,
      privateContext: card.privateContext,
      sourceBookFingerprint: card.sourceBookFingerprint,
      sourceBookTitle: card.sourceBookTitle,
      reviewStatus: reviewStatus,
      reviewCount: reviewCount,
      nextReviewAt: nextReviewAt,
      lastReviewedAt: lastReviewedAt,
      syncStatus: syncStatus,
      createdAt: card.createdAt,
      updatedAt: updatedAt,
    );
    return 1;
  }

  Future<void> markSynced(LocalWordCard card, String serverCardId) async {}
}

class _FakePendingSyncEventRepository implements PendingSyncEventRepository {
  final events = <PendingSyncEvent>[];
  final doneEventIds = <String>[];
  final failedEventIds = <String>[];

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
        .where(
          (event) =>
              event.ownerUserId == ownerUserId && event.status == 'pending',
        )
        .toList(growable: false);
  }

  Future<void> markDone(PendingSyncEvent event) async {
    doneEventIds.add(event.id);
  }

  Future<void> markFailed(PendingSyncEvent event, String errorCode) async {
    failedEventIds.add(event.id);
  }
}

class _FakeStudyStatsRepository implements LocalStudyStatsRepository {
  final statsByDate = <String, LocalStudyDailyStat>{};

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
    final key = LocalStudyDailyStat.dateString(statDate);
    final existing = statsByDate[key];
    final now = DateTime.utc(2026, 5, 9, 12);
    final next = LocalStudyDailyStat(
      id: existing?.id ?? 'stat-$key',
      ownerUserId: ownerUserId,
      statDate: statDate,
      readingMinutes: (existing?.readingMinutes ?? 0) + readingMinutes,
      lookupCount: (existing?.lookupCount ?? 0) + lookupCount,
      paragraphTranslationCount:
          (existing?.paragraphTranslationCount ?? 0) +
          paragraphTranslationCount,
      cardsCreated: (existing?.cardsCreated ?? 0) + cardsCreated,
      cardsReviewed: (existing?.cardsReviewed ?? 0) + cardsReviewed,
      syncStatus: 'dirty',
      lastSyncedAt: null,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    statsByDate[key] = next;
    return next;
  }

  @override
  Future<LocalStudyDailyStat?> findByOwnerUserIdAndStatDate({
    required String ownerUserId,
    required DateTime statDate,
  }) async {
    final stat = statsByDate[LocalStudyDailyStat.dateString(statDate)];
    return stat?.ownerUserId == ownerUserId ? stat : null;
  }

  @override
  Future<List<LocalStudyDailyStat>> findByOwnerUserId(
    String ownerUserId,
  ) async {
    return statsByDate.values
        .where((stat) => stat.ownerUserId == ownerUserId)
        .toList(growable: false);
  }
}

class _FakeReadingSyncApiClient extends ReadingSyncApiClient {}

class _FakeStatsApiClient extends StatsApiClient {}
