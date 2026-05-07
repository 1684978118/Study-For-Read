import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_chapter.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late Database db;
  late LocalBookRepository bookRepository;
  late LocalChapterRepository chapterRepository;
  late LocalReadingPositionRepository positionRepository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    bookRepository = LocalBookRepository(db);
    chapterRepository = LocalChapterRepository(db);
    positionRepository = LocalReadingPositionRepository(db);
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('local_books enforces unique owner and book fingerprint', () async {
    await bookRepository.insert(_book(id: 'book-1'));

    expect(
      () => bookRepository.insert(_book(id: 'book-2')),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('lists books by owner without leaking other users books', () async {
    await bookRepository.insert(_book(id: 'book-1', ownerUserId: 'user-a'));
    await bookRepository.insert(
      _book(
        id: 'book-2',
        ownerUserId: 'user-b',
        fingerprint:
            'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      ),
    );

    final books = await bookRepository.findByOwnerUserId('user-a');

    expect(books, hasLength(1));
    expect(books.single.id, 'book-1');
  });

  test('chapters can be loaded by book and chapter index', () async {
    await bookRepository.insert(_book(id: 'book-1'));
    await chapterRepository.insert(_chapter(id: 'chapter-1'));

    final chapter = await chapterRepository.findByBookIdAndChapterIndex(
      bookId: 'book-1',
      chapterIndex: 0,
    );

    expect(chapter?.title, 'Chapter 1');
    expect(chapter?.content, 'local chapter content');
  });

  test('reading position upsert keeps one row per book', () async {
    await bookRepository.insert(_book(id: 'book-1', chapterCount: 3));

    await positionRepository.upsert(_position(currentChapterIndex: 0));
    await positionRepository.upsert(
      _position(
        id: 'position-2',
        currentChapterIndex: 2,
        currentParagraphIndex: 4,
        currentCharOffset: 10,
      ),
    );

    final positions = await db.query('local_reading_positions');
    final position = await positionRepository.findByBookId('book-1');
    expect(positions, hasLength(1));
    expect(position?.currentChapterIndex, 2);
    expect(position?.currentParagraphIndex, 4);
    expect(position?.currentCharOffset, 10);
  });

  test(
    'reading position rejects negative fields in repository validation',
    () async {
      await bookRepository.insert(_book(id: 'book-1'));

      expect(
        () => positionRepository.upsert(_position(currentChapterIndex: -1)),
        throwsArgumentError,
      );
      expect(
        () => positionRepository.upsert(_position(currentParagraphIndex: -1)),
        throwsArgumentError,
      );
      expect(
        () => positionRepository.upsert(_position(currentCharOffset: -1)),
        throwsArgumentError,
      );
    },
  );

  test(
    'reading position rejects chapter index outside book chapter count',
    () async {
      await bookRepository.insert(_book(id: 'book-1', chapterCount: 1));

      expect(
        () => positionRepository.upsert(_position(currentChapterIndex: 1)),
        throwsArgumentError,
      );
    },
  );
}

LocalBook _book({
  required String id,
  String ownerUserId = 'user-1',
  String fingerprint =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  int chapterCount = 1,
}) {
  final now = DateTime.utc(2026, 5, 7);
  return LocalBook(
    id: id,
    ownerUserId: ownerUserId,
    bookFingerprint: fingerprint,
    title: 'Kokoro',
    author: 'Natsume Soseki',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFilePath: '/app/books/$id.txt',
    chapterCount: chapterCount,
    metadataSyncStatus: 'local_only',
    lastOpenedAt: null,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

LocalChapter _chapter({required String id}) {
  final now = DateTime.utc(2026, 5, 7);
  return LocalChapter(
    id: id,
    bookId: 'book-1',
    chapterIndex: 0,
    title: 'Chapter 1',
    content: 'local chapter content',
    paragraphCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

LocalReadingPosition _position({
  String id = 'position-1',
  int currentChapterIndex = 0,
  int currentParagraphIndex = 0,
  int currentCharOffset = 0,
}) {
  final now = DateTime.utc(2026, 5, 7);
  return LocalReadingPosition(
    id: id,
    bookId: 'book-1',
    currentChapterIndex: currentChapterIndex,
    currentParagraphIndex: currentParagraphIndex,
    currentCharOffset: currentCharOffset,
    progressSyncStatus: 'local_only',
    lastReadAt: now,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}
