import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late PendingSyncEventRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    final db = await mobileDatabase.open();
    repository = PendingSyncEventRepository(db);
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('inserts and lists pending events for the current owner only', () async {
    await repository.insert(_event(id: 'event-1', ownerUserId: 'user-a'));
    await repository.insert(_event(id: 'event-2', ownerUserId: 'user-b'));

    final events = await repository.findPendingByOwnerUserId('user-a');

    expect(events, hasLength(1));
    expect(events.single.id, 'event-1');
  });

  test('payload_json rejects forbidden content field names', () async {
    const forbiddenPayloads = [
      '{"content":"chapter"}',
      '{"chapterContent":"chapter"}',
      '{"chapter_content":"chapter"}',
      '{"originalFile":"book.epub"}',
      '{"original_file":"book.epub"}',
      '{"filePath":"/tmp/book.txt"}',
      '{"file_path":"/tmp/book.txt"}',
      '{"rawText":"lookup"}',
      '{"raw_text":"lookup"}',
      '{"translatedText":"translation"}',
      '{"translated_text":"translation"}',
      '{"paragraphText":"paragraph"}',
      '{"paragraph_text":"paragraph"}',
      '{"nested":{"content":"chapter"}}',
    ];

    for (final payload in forbiddenPayloads) {
      expect(
        () => repository.insert(_event(id: payload, payloadJson: payload)),
        throwsArgumentError,
        reason: payload,
      );
    }
  });

  test('attempt count cannot be negative', () async {
    expect(
      () => repository.insert(_event(id: 'event-1', attemptCount: -1)),
      throwsArgumentError,
    );
  });
}

PendingSyncEvent _event({
  required String id,
  String ownerUserId = 'user-1',
  String payloadJson =
      '{"bookFingerprint":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","currentChapterIndex":0}',
  int attemptCount = 0,
}) {
  final now = DateTime.utc(2026, 5, 7);
  return PendingSyncEvent(
    id: id,
    ownerUserId: ownerUserId,
    eventType: 'reading_progress',
    aggregateKey:
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    payloadJson: payloadJson,
    status: 'pending',
    attemptCount: attemptCount,
    lastErrorCode: null,
    createdAt: now,
    updatedAt: now,
  );
}
