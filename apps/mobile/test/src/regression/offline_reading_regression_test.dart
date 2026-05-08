import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_file_picker.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_file_storage_service.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_import_service.dart';
import 'package:study_for_read_mobile/src/features/library/data/epub_book_parser.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/txt_book_parser.dart';
import 'package:study_for_read_mobile/src/features/library/presentation/library_controller.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_controller.dart';
import 'package:study_for_read_mobile/src/features/sync/data/pending_sync_event_repository.dart';
import 'package:study_for_read_mobile/src/features/sync/domain/pending_sync_event.dart';

void main() {
  late Directory tempDir;
  late Directory privateRoot;
  late MobileDatabase mobileDatabase;
  late Database db;
  late LocalBookRepository bookRepository;
  late LocalChapterRepository chapterRepository;
  late LocalReadingPositionRepository positionRepository;
  late PendingSyncEventRepository pendingSyncRepository;
  late BookImportService importService;

  setUp(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp(
      'study_for_read_offline_regression_',
    );
    privateRoot = Directory('${tempDir.path}/private');
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    bookRepository = LocalBookRepository(db);
    chapterRepository = LocalChapterRepository(db);
    positionRepository = LocalReadingPositionRepository(db);
    pendingSyncRepository = PendingSyncEventRepository(db);
    importService = BookImportService(
      database: db,
      storageService: BookFileStorageService(privateRootDirectory: privateRoot),
      txtParser: const TxtBookParser(),
      epubParser: const EpubBookParser(),
    );
  });

  tearDown(() async {
    await mobileDatabase.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'imported TXT remains readable offline and sync payloads stay metadata-only',
    () async {
      final sourceFile = await _writeText(
        tempDir,
        'offline.txt',
        'Chapter 1\nfirst offline chapter\n\nChapter 2\nsecond offline chapter',
      );

      final imported = await importService.importBook(
        ownerUserId: 'user-1',
        sourceFile: sourceFile,
      );

      final libraryController = LibraryController(
        ownerUserId: 'user-1',
        bookRepository: bookRepository,
        filePicker: const _NoNetworkBookFilePicker(),
        importService: importService,
      );
      await libraryController.load();

      expect(libraryController.errorMessage, isNull);
      expect(libraryController.books, hasLength(1));
      expect(libraryController.books.single.id, imported.book.id);
      expect(libraryController.books.single.title, 'offline');

      final readerController = _readerController(
        bookId: imported.book.id,
        bookRepository: bookRepository,
        chapterRepository: chapterRepository,
        positionRepository: positionRepository,
      );
      await readerController.load();

      expect(readerController.notFound, isFalse);
      expect(readerController.currentChapter?.content, 'first offline chapter');

      await readerController.nextChapter();
      final savedPosition = await positionRepository.findByBookId(
        imported.book.id,
      );
      expect(savedPosition?.currentChapterIndex, 1);
      expect(savedPosition?.progressSyncStatus, 'dirty');

      final reopenedReaderController = _readerController(
        bookId: imported.book.id,
        bookRepository: bookRepository,
        chapterRepository: chapterRepository,
        positionRepository: positionRepository,
      );
      await reopenedReaderController.load();

      expect(reopenedReaderController.currentChapterIndex, 1);
      expect(
        reopenedReaderController.currentChapter?.content,
        'second offline chapter',
      );

      final metadataEvents = await pendingSyncRepository.findPendingByOwnerUserId(
        'user-1',
      );
      final metadataEvent = metadataEvents.singleWhere(
        (event) => event.eventType == 'book_metadata',
      );
      final metadataPayload =
          jsonDecode(metadataEvent.payloadJson) as Map<String, Object?>;

      expect(metadataPayload.keys, {
        'bookFingerprint',
        'title',
        'author',
        'fileType',
        'sourceLang',
        'targetLang',
        'chapterCount',
      });
      expect(metadataPayload['title'], 'offline');
      expect(metadataPayload['chapterCount'], 2);
      _expectNoRawContent(metadataEvent.payloadJson);

      final progressPayload = {
        'bookFingerprint': imported.book.bookFingerprint,
        'currentChapterIndex': savedPosition!.currentChapterIndex,
        'currentParagraphIndex': savedPosition.currentParagraphIndex,
        'currentCharOffset': savedPosition.currentCharOffset,
        'progressSyncStatus': savedPosition.progressSyncStatus,
      };
      await pendingSyncRepository.insert(
        PendingSyncEvent(
          id: 'reading-progress-event-1',
          ownerUserId: 'user-1',
          eventType: 'reading_progress',
          aggregateKey: imported.book.bookFingerprint,
          payloadJson: jsonEncode(progressPayload),
          status: 'pending',
          attemptCount: 0,
          lastErrorCode: null,
          createdAt: DateTime.utc(2026, 5, 8),
          updatedAt: DateTime.utc(2026, 5, 8),
        ),
      );

      final progressEvents = await pendingSyncRepository.findPendingByOwnerUserId(
        'user-1',
      );
      final progressEvent = progressEvents.singleWhere(
        (event) => event.eventType == 'reading_progress',
      );
      final decodedProgress =
          jsonDecode(progressEvent.payloadJson) as Map<String, Object?>;

      expect(decodedProgress.keys, {
        'bookFingerprint',
        'currentChapterIndex',
        'currentParagraphIndex',
        'currentCharOffset',
        'progressSyncStatus',
      });
      expect(decodedProgress['currentChapterIndex'], 1);
      expect(decodedProgress['progressSyncStatus'], 'dirty');
      _expectNoRawContent(progressEvent.payloadJson);
      expect(progressEvent.payloadJson, isNot(contains('first offline chapter')));
      expect(progressEvent.payloadJson, isNot(contains('second offline chapter')));
      expect(progressEvent.payloadJson, isNot(contains(sourceFile.path)));
    },
  );
}

ReaderController _readerController({
  required String bookId,
  required LocalBookRepository bookRepository,
  required LocalChapterRepository chapterRepository,
  required LocalReadingPositionRepository positionRepository,
}) {
  return ReaderController(
    bookId: bookId,
    bookRepository: bookRepository,
    chapterRepository: chapterRepository,
    positionRepository: positionRepository,
  );
}

Future<File> _writeText(
  Directory directory,
  String filename,
  String text,
) {
  return File('${directory.path}/$filename').writeAsString(text);
}

void _expectNoRawContent(String payloadJson) {
  const forbiddenFragments = [
    'content',
    'chapterContent',
    'chapter_content',
    'originalFile',
    'original_file',
    'filePath',
    'file_path',
    'rawText',
    'raw_text',
    'translatedText',
    'translated_text',
  ];
  for (final fragment in forbiddenFragments) {
    expect(payloadJson, isNot(contains(fragment)));
  }
}

class _NoNetworkBookFilePicker implements BookFilePicker {
  const _NoNetworkBookFilePicker();

  @override
  Future<File?> pickBookFile() async => null;
}
