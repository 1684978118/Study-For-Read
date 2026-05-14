import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../reader/data/local_reading_position_repository.dart';
import '../../sync/data/pending_sync_event_repository.dart';
import '../../sync/domain/pending_sync_event.dart';
import '../domain/book_file_type.dart';
import '../domain/local_book.dart';
import '../domain/local_chapter.dart';
import '../domain/local_reading_position.dart';
import 'book_file_storage_service.dart';
import 'book_parse_result.dart';
import 'epub_book_parser.dart';
import 'local_book_repository.dart';
import 'local_chapter_repository.dart';
import 'stored_book_file.dart';
import 'txt_book_parser.dart';

abstract interface class BookImporter {
  Future<BookImportResult> importBook({
    required String ownerUserId,
    required File sourceFile,
  });
}

class BookImportService implements BookImporter {
  const BookImportService({
    required Database database,
    required BookFileStorageService storageService,
    required TxtBookParser txtParser,
    required EpubBookParser epubParser,
  }) : _database = database,
       _storageService = storageService,
       _txtParser = txtParser,
       _epubParser = epubParser;

  final Database _database;
  final BookFileStorageService _storageService;
  final TxtBookParser _txtParser;
  final EpubBookParser _epubParser;

  @override
  Future<BookImportResult> importBook({
    required String ownerUserId,
    required File sourceFile,
  }) async {
    final storedFile = await _storageService.store(sourceFile);
    final parsedBook = await _parse(sourceFile, storedFile);
    final now = DateTime.now().toUtc();

    return _database.transaction((txn) async {
      final bookRepository = LocalBookRepository(txn);
      final chapterRepository = LocalChapterRepository(txn);
      final positionRepository = LocalReadingPositionRepository(txn);
      final pendingSyncRepository = PendingSyncEventRepository(txn);

      final existingBook = await bookRepository
          .findByOwnerUserIdAndBookFingerprint(
            ownerUserId: ownerUserId,
            bookFingerprint: storedFile.fingerprint,
          );
      final book = _localBook(
        existingBook: existingBook,
        ownerUserId: ownerUserId,
        storedFile: storedFile,
        parsedBook: parsedBook,
        now: now,
      );

      if (existingBook == null) {
        await bookRepository.insert(book);
      } else {
        await bookRepository.update(book);
      }

      await chapterRepository.deleteByBookId(book.id);
      for (final parsedChapter in parsedBook.chapters) {
        await chapterRepository.insert(
          LocalChapter(
            id: _uuidV4(),
            bookId: book.id,
            chapterIndex: parsedChapter.chapterIndex,
            title: parsedChapter.title,
            content: parsedChapter.content,
            paragraphCount: parsedChapter.paragraphs.length,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      final existingPosition = await positionRepository.findByBookId(book.id);
      if (existingPosition == null) {
        await positionRepository.upsert(
          LocalReadingPosition(
            id: _uuidV4(),
            bookId: book.id,
            currentChapterIndex: 0,
            currentParagraphIndex: 0,
            currentCharOffset: 0,
            progressSyncStatus: 'local_only',
            lastReadAt: null,
            lastSyncedAt: null,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await pendingSyncRepository.insert(
        PendingSyncEvent(
          id: _uuidV4(),
          ownerUserId: ownerUserId,
          eventType: 'book_metadata',
          aggregateKey: storedFile.fingerprint,
          payloadJson: jsonEncode(_metadataPayload(book, parsedBook)),
          status: 'pending',
          attemptCount: 0,
          lastErrorCode: null,
          createdAt: now,
          updatedAt: now,
        ),
      );

      return BookImportResult(book: book, storedFile: storedFile);
    });
  }

  Future<ParsedBook> _parse(File sourceFile, StoredBookFile storedFile) {
    return switch (storedFile.fileType) {
      BookFileType.txt => _txtParser.parseFile(sourceFile),
      BookFileType.epub => _epubParser.parseFile(
        sourceFile,
        imageOutputDirectory: Directory(
          p.join(
            p.dirname(storedFile.localPath),
            '${storedFile.fingerprint}_assets',
          ),
        ),
      ),
    };
  }

  LocalBook _localBook({
    required LocalBook? existingBook,
    required String ownerUserId,
    required StoredBookFile storedFile,
    required ParsedBook parsedBook,
    required DateTime now,
  }) {
    return LocalBook(
      id: existingBook?.id ?? _uuidV4(),
      ownerUserId: ownerUserId,
      bookFingerprint: storedFile.fingerprint,
      title: parsedBook.title,
      author: parsedBook.author,
      fileType: parsedBook.fileType,
      sourceLang: parsedBook.sourceLang,
      targetLang: parsedBook.targetLang,
      originalFilePath: storedFile.localPath,
      chapterCount: parsedBook.chapters.length,
      metadataSyncStatus: 'dirty',
      lastOpenedAt: existingBook?.lastOpenedAt,
      lastSyncedAt: existingBook?.lastSyncedAt,
      createdAt: existingBook?.createdAt ?? now,
      updatedAt: now,
    );
  }

  Map<String, Object?> _metadataPayload(LocalBook book, ParsedBook parsedBook) {
    return {
      'bookFingerprint': book.bookFingerprint,
      'title': book.title,
      'author': book.author,
      'fileType': book.fileType,
      'sourceLang': book.sourceLang,
      'targetLang': book.targetLang,
      'chapterCount': parsedBook.chapters.length,
    };
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

class BookImportResult {
  const BookImportResult({required this.book, required this.storedFile});

  final LocalBook book;
  final StoredBookFile storedFile;
}
