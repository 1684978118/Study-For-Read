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
import 'package:study_for_read_mobile/src/features/reader/presentation/reading_text_view.dart';

void main() {
  testWidgets('default reader shows full-screen text without bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    expect(find.text('first chapter text'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Kokoro'), findsNothing);
    expect(find.text('Previous'), findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('tap blank reading space toggles temporary controls', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('Kokoro'), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('Previous'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.byKey(const Key('reader-font-size-slider')), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('Previous'), findsNothing);
    expect(find.text('Next'), findsNothing);
  });

  testWidgets('visible controls reserve space for reading text', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    final controlBottom = tester.getBottomLeft(find.text('Chapter 1')).dy;
    final readingTop = tester.getTopLeft(find.text('first chapter text')).dy;

    expect(readingTop, greaterThan(controlBottom + 16));
  });

  testWidgets('next and previous update chapter text and save progress', (
    tester,
  ) async {
    final positionRepository = _FakeReadingPositionRepository(
      saved: _position(chapterIndex: 0),
    );
    await tester.pumpWidget(
      _app(_controller(positionRepository: positionRepository)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('second chapter text'), findsOneWidget);
    expect(positionRepository.savedPositions.last.currentChapterIndex, 1);
    expect(positionRepository.savedPositions.last.progressSyncStatus, 'dirty');

    await tester.tap(find.text('Previous'));
    await tester.pumpAndSettle();

    expect(find.text('first chapter text'), findsOneWidget);
    expect(positionRepository.savedPositions.last.currentChapterIndex, 0);
    expect(positionRepository.savedPositions.last.progressSyncStatus, 'dirty');
  });

  testWidgets('previous and next buttons are disabled at chapter edges', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    final previous = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Previous'),
    );
    expect(previous.onPressed, isNull);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    final next = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Next'),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('font size control changes reading text size within bounds', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('reader-font-size-slider')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    var textView = tester.widget<ReadingTextView>(find.byType(ReadingTextView));
    expect(textView.fontSize, ReaderController.maxFontSize);

    await tester.drag(
      find.byKey(const Key('reader-font-size-slider')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    textView = tester.widget<ReadingTextView>(find.byType(ReadingTextView));
    expect(textView.fontSize, ReaderController.minFontSize);
  });

  testWidgets('missing local book id shows not found state', (tester) async {
    await tester.pumpWidget(_app(_controller(missingBook: true)));
    await tester.pumpAndSettle();

    expect(find.text('Local book not found'), findsOneWidget);
    expect(find.text('first chapter text'), findsNothing);
  });
}

Widget _app(ReaderController controller) {
  return MaterialApp(
    home: ReaderScreen(bookId: 'book-1', controller: controller),
  );
}

ReaderController _controller({
  bool missingBook = false,
  _FakeReadingPositionRepository? positionRepository,
}) {
  return ReaderController(
    bookId: 'book-1',
    bookRepository: _FakeBookRepository(book: missingBook ? null : _book()),
    chapterRepository: _FakeChapterRepository(chapters: _chapters()),
    positionRepository:
        positionRepository ??
        _FakeReadingPositionRepository(saved: _position(chapterIndex: 0)),
  );
}

LocalBook _book() {
  final now = DateTime.utc(2026, 5, 8);
  return LocalBook(
    id: 'book-1',
    ownerUserId: 'user-1',
    bookFingerprint:
        '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    title: 'Kokoro',
    author: 'Natsume Soseki',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFilePath: 'D:/private/books/kokoro.txt',
    chapterCount: 3,
    metadataSyncStatus: 'local_only',
    lastOpenedAt: null,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

List<LocalChapter> _chapters() {
  return [
    _chapter(index: 0, title: 'Chapter 1', content: 'first chapter text'),
    _chapter(index: 1, title: 'Chapter 2', content: 'second chapter text'),
    _chapter(index: 2, title: 'Chapter 3', content: 'third chapter text'),
  ];
}

LocalChapter _chapter({
  required int index,
  required String title,
  required String content,
}) {
  final now = DateTime.utc(2026, 5, 8);
  return LocalChapter(
    id: 'chapter-$index',
    bookId: 'book-1',
    chapterIndex: index,
    title: title,
    content: content,
    paragraphCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

LocalReadingPosition _position({required int chapterIndex}) {
  final now = DateTime.utc(2026, 5, 8);
  return LocalReadingPosition(
    id: 'position-1',
    bookId: 'book-1',
    currentChapterIndex: chapterIndex,
    currentParagraphIndex: 0,
    currentCharOffset: 0,
    progressSyncStatus: 'local_only',
    lastReadAt: now,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
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
    return null;
  }

  @override
  Future<List<LocalBook>> findByOwnerUserId(String ownerUserId) async => [];

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
        .where((chapter) => chapter.chapterIndex == chapterIndex)
        .firstOrNull;
  }

  @override
  Future<List<LocalChapter>> findByBookIdOrderByChapterIndex(
    String bookId,
  ) async {
    return chapters;
  }

  @override
  Future<int> insert(LocalChapter chapter) async => 1;
}

class _FakeReadingPositionRepository implements LocalReadingPositionRepository {
  _FakeReadingPositionRepository({required this.saved});

  final LocalReadingPosition? saved;
  final List<LocalReadingPosition> savedPositions = [];

  @override
  Future<LocalReadingPosition?> findByBookId(String bookId) async => saved;

  @override
  Future<void> upsert(LocalReadingPosition position) async {
    savedPositions.add(position);
  }
}
