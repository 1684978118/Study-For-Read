import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/data/local_word_card_repository.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/domain/local_word_card.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late Database db;
  late LocalWordCardRepository repository;
  late PendingSyncEventRepository pendingSyncRepository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    repository = LocalWordCardRepository(db);
    pendingSyncRepository = PendingSyncEventRepository(db);
    await db.insert('local_lexeme_cache', _lexemeRow());
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('requires lexeme_id for lexeme cards', () async {
    expect(
      () => repository.upsert(_card(id: 'card-1', cardType: 'lexeme')),
      throwsArgumentError,
    );
  });

  test('requires private surface and definition for private sentence cards', () {
    expect(
      () => repository.upsert(
        _card(id: 'card-1', cardType: 'private_sentence'),
      ),
      throwsArgumentError,
    );

    expect(
      () => repository.upsert(
        _card(
          id: 'card-2',
          cardType: 'private_sentence',
          privateSurface: '先生と呼んでいた',
        ),
      ),
      throwsArgumentError,
    );
  });

  test('rejects duplicate owner and lexeme id for different cards', () async {
    await repository.upsert(
      _card(id: 'card-1', cardType: 'lexeme', lexemeId: 'lexeme-1'),
    );

    expect(
      () => repository.upsert(
        _card(id: 'card-2', cardType: 'lexeme', lexemeId: 'lexeme-1'),
      ),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('lists due cards for one owner only', () async {
    final dueAt = DateTime.utc(2026, 5, 8, 1);
    await repository.upsert(
      _card(
        id: 'card-1',
        cardType: 'lexeme',
        lexemeId: 'lexeme-1',
        nextReviewAt: dueAt,
      ),
    );
    await repository.upsert(
      _card(
        id: 'card-2',
        ownerUserId: 'user-2',
        cardType: 'private_sentence',
        privateSurface: '別の文',
        privateDefinition: 'other',
        nextReviewAt: dueAt,
      ),
    );

    final dueCards = await repository.findDueByOwnerUserId(
      ownerUserId: 'user-1',
      dueAt: dueAt,
    );

    expect(dueCards, hasLength(1));
    expect(dueCards.single.id, 'card-1');
  });

  test('pending sync allows vocabulary event types and rejects raw payloads', () async {
    await pendingSyncRepository.insert(
      _event(
        id: 'create-event',
        eventType: 'word_card_create',
        payloadJson: '{"cardId":"card-1","lexemeId":"lexeme-1"}',
      ),
    );
    await pendingSyncRepository.insert(
      _event(
        id: 'review-event',
        eventType: 'word_card_review',
        payloadJson: '{"cardId":"card-1","known":true}',
      ),
    );

    final pending = await pendingSyncRepository.findPendingByOwnerUserId(
      'user-1',
    );

    expect(pending.map((event) => event.eventType), [
      'word_card_create',
      'word_card_review',
    ]);
    expect(
      () => pendingSyncRepository.insert(
        _event(
          id: 'bad-event',
          eventType: 'word_card_create',
          payloadJson: '{"chapterContent":"raw chapter"}',
        ),
      ),
      throwsArgumentError,
    );
  });
}

Map<String, Object?> _lexemeRow() {
  return {
    'id': 'lexeme-1',
    'surface': '心',
    'reading': 'こころ',
    'source_lang': 'ja',
    'target_lang': 'zh-CN',
    'entry_type': 'word',
    'part_of_speech': 'noun',
    'definition': 'heart',
    'short_definition': 'heart',
    'cached_at': '2026-05-08T01:00:00.000Z',
    'updated_at': '2026-05-08T01:00:00.000Z',
  };
}

LocalWordCard _card({
  required String id,
  String ownerUserId = 'user-1',
  String cardType = 'lexeme',
  String? lexemeId,
  String? privateSurface,
  String? privateDefinition,
  DateTime? nextReviewAt,
}) {
  final now = DateTime.utc(2026, 5, 8, 1);
  return LocalWordCard(
    id: id,
    serverCardId: null,
    ownerUserId: ownerUserId,
    cardType: cardType,
    lexemeId: lexemeId,
    privateSurface: privateSurface,
    privateDefinition: privateDefinition,
    privateContext: null,
    sourceBookFingerprint: null,
    sourceBookTitle: null,
    reviewStatus: 'new',
    reviewCount: 0,
    nextReviewAt: nextReviewAt,
    lastReviewedAt: null,
    syncStatus: 'local_only',
    createdAt: now,
    updatedAt: now,
  );
}

PendingSyncEvent _event({
  required String id,
  required String eventType,
  required String payloadJson,
}) {
  final now = DateTime.utc(2026, 5, 8, 1);
  return PendingSyncEvent(
    id: id,
    ownerUserId: 'user-1',
    eventType: eventType,
    aggregateKey: 'card-1',
    payloadJson: payloadJson,
    status: 'pending',
    attemptCount: 0,
    lastErrorCode: null,
    createdAt: now,
    updatedAt: now,
  );
}
