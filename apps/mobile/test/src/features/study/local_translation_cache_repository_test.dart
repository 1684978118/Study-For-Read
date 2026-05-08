import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/study/data/local_translation_cache_repository.dart';
import 'package:study_for_read_mobile/src/features/study/domain/local_translation_cache_entry.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late Database db;
  late LocalTranslationCacheRepository repository;
  late PendingSyncEventRepository pendingSyncRepository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    repository = LocalTranslationCacheRepository(db);
    pendingSyncRepository = PendingSyncEventRepository(db);
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('stores translated text locally and looks up by owner and hash', () async {
    await repository.upsert(_entry(translatedText: 'I always called him Sensei.'));

    final cached = await repository.findByOwnerAndLanguagePairAndSourceTextHash(
      ownerUserId: 'user-1',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      sourceTextHash:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    );

    expect(cached, isNotNull);
    expect(cached!.translatedText, 'I always called him Sensei.');
    expect(cached.sourceTextPreview, '先生と呼んでいた');
  });

  test('pending sync payload rejects translation cache fields', () async {
    const forbiddenPayloads = [
      '{"sourceTextPreview":"先生と呼んでいた"}',
      '{"source_text_preview":"先生と呼んでいた"}',
      '{"translatedText":"I always called him Sensei."}',
      '{"translated_text":"I always called him Sensei."}',
    ];

    for (final payload in forbiddenPayloads) {
      expect(
        () => pendingSyncRepository.insert(
          _event(id: payload, eventType: 'daily_stats', payloadJson: payload),
        ),
        throwsArgumentError,
        reason: payload,
      );
    }
  });
}

LocalTranslationCacheEntry _entry({required String translatedText}) {
  final now = DateTime.utc(2026, 5, 8, 1);
  return LocalTranslationCacheEntry(
    id: 'translation-1',
    ownerUserId: 'user-1',
    bookFingerprint:
        'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
    chapterIndex: 0,
    paragraphIndex: 2,
    sourceTextHash:
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    sourceTextPreview: '先生と呼んでいた',
    translatedText: translatedText,
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    provider: 'local_fallback',
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
    aggregateKey: 'stats-2026-05-08',
    payloadJson: payloadJson,
    status: 'pending',
    attemptCount: 0,
    lastErrorCode: null,
    createdAt: now,
    updatedAt: now,
  );
}
