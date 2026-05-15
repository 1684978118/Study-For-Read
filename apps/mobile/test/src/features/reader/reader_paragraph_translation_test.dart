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
import 'package:study_for_read_mobile/src/features/study/domain/paragraph_selection.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/paragraph_translation_controller.dart';

void main() {
  testWidgets('reader keeps paragraph translate plus near the text end', (
    tester,
  ) async {
    const paragraph =
        'This acceptance sentence wraps across multiple reader lines and ends '
        'with a short tail.';
    await tester.pumpWidget(_app(_controller(content: paragraph)));
    await tester.pumpAndSettle();

    final paragraphLeft = tester.getTopLeft(find.textContaining(paragraph)).dx;
    final hotspotLeft = tester
        .getTopLeft(find.byKey(const Key('paragraph-translate-hotspot-0')))
        .dx;

    expect(hotspotLeft, greaterThan(paragraphLeft + 120));
  });

  testWidgets('reader shows subtle paragraph action icons without plus text', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('paragraph-translate-hotspot-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('paragraph-translate-hotspot-1')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
    expect(find.text('+'), findsNothing);
  });

  testWidgets(
    'tapping plus translates one paragraph and inserts result inline',
    (tester) async {
      final translationController = _FakeParagraphTranslationController();
      await tester.pumpWidget(
        _app(_controller(translationController: translationController)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('paragraph-translate-hotspot-0')));
      await tester.pumpAndSettle();

      expect(translationController.selections, hasLength(1));
      expect(
        translationController.selections.single.selectedParagraphText,
        'first paragraph for translation.',
      );
      expect(translationController.selections.single.paragraphIndex, 0);
      expect(
        translationController.selections.single.selectedParagraphText,
        isNot(contains('second paragraph')),
      );
      expect(find.text('translated first paragraph'), findsOneWidget);
      expect(find.text('Copy'), findsNothing);
      expect(find.text('保存'), findsNothing);
      expect(find.text('Collapse'), findsNothing);
      expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
      expect(find.text('+'), findsNothing);
    },
  );

  testWidgets(
    'offline translation keeps plus and shows inline unavailable state',
    (tester) async {
      final translationController = _FakeParagraphTranslationController(
        nextState: const ParagraphTranslationState.offline(),
      );
      await tester.pumpWidget(
        _app(_controller(translationController: translationController)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('paragraph-translate-hotspot-1')));
      await tester.pumpAndSettle();

      expect(find.textContaining('离线'), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
      expect(find.text('+'), findsNothing);
    },
  );
}

Widget _app(ReaderController controller) {
  return MaterialApp(
    home: ReaderScreen(bookId: 'book-1', controller: controller),
  );
}

ReaderController _controller({
  _FakeParagraphTranslationController? translationController,
  String? content,
}) {
  return ReaderController(
    bookId: 'book-1',
    bookRepository: _FakeBookRepository(book: _book()),
    chapterRepository: _FakeChapterRepository(chapters: _chapters(content)),
    positionRepository: _FakeReadingPositionRepository(saved: _position()),
    paragraphTranslationController:
        translationController ?? _FakeParagraphTranslationController(),
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
    chapterCount: 1,
    metadataSyncStatus: 'local_only',
    lastOpenedAt: null,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

List<LocalChapter> _chapters([String? content]) {
  final now = DateTime.utc(2026, 5, 8);
  return [
    LocalChapter(
      id: 'chapter-1',
      bookId: 'book-1',
      chapterIndex: 0,
      title: 'Chapter 1',
      content:
          content ??
          'first paragraph for translation.\n\nsecond paragraph for translation.',
      paragraphCount: content == null ? 2 : 1,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

LocalReadingPosition _position() {
  final now = DateTime.utc(2026, 5, 8);
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

class _FakeParagraphTranslationController
    extends ParagraphTranslationController {
  _FakeParagraphTranslationController({
    this.nextState = const ParagraphTranslationState.success(
      translatedText: 'translated first paragraph',
      provider: 'fallback',
    ),
  }) : super.test();

  final ParagraphTranslationState nextState;
  final List<ParagraphSelection> selections = [];

  @override
  Future<void> translate(ParagraphSelection selection, {DateTime? now}) async {
    selections.add(selection);
    setStateForTesting(selection, nextState);
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
    return chapters.firstOrNull;
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

  @override
  Future<LocalReadingPosition?> findByBookId(String bookId) async => saved;

  @override
  Future<void> upsert(LocalReadingPosition position) async {}
}
