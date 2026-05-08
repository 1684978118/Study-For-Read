import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/core/network/api_error.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_chapter.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_controller.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_screen.dart';
import 'package:study_for_read_mobile/src/features/study/domain/lookup_result.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_bottom_sheet.dart';
import 'package:study_for_read_mobile/src/features/study/presentation/lookup_controller.dart';

void main() {
  testWidgets('tap reader text opens lookup bottom sheet with lexeme details', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('心'));
    await tester.pumpAndSettle();

    expect(find.byType(LookupBottomSheet), findsOneWidget);
    expect(find.text('心'), findsWidgets);
    expect(find.text('こころ'), findsOneWidget);
    expect(find.text('heart'), findsOneWidget);
    expect(find.text('heart; mind'), findsOneWidget);
    expect(find.text('word'), findsOneWidget);
    expect(find.byTooltip('Pronounce'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Save'), findsOneWidget);
  });

  testWidgets('reader lookup sends paragraph context, not full chapter text', (
    tester,
  ) async {
    final lookupController = _FakeLookupController();
    await tester.pumpWidget(_app(_controller(lookupController: lookupController)));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('心'));
    await tester.pumpAndSettle();

    expect(lookupController.selections, hasLength(1));
    expect(lookupController.selections.single.selectedText, '心');
    expect(lookupController.selections.single.paragraphContext, '先生の心。');
    expect(
      lookupController.selections.single.paragraphContext,
      isNot(contains('第二段落')),
    );
  });

  testWidgets('provider unavailable shows error sheet and reader remains usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _controller(
          lookupController: _FakeLookupController(
            error: const ApiError(
              code: 'STUDY_PROVIDER_UNAVAILABLE',
              message: 'Provider unavailable',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('心'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Provider unavailable'), findsOneWidget);
    expect(find.textContaining('先生の心'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('Kokoro'), findsOneWidget);
  });
}

Widget _app(ReaderController controller) {
  return MaterialApp(home: ReaderScreen(bookId: 'book-1', controller: controller));
}

ReaderController _controller({_FakeLookupController? lookupController}) {
  return ReaderController(
    bookId: 'book-1',
    bookRepository: _FakeBookRepository(book: _book()),
    chapterRepository: _FakeChapterRepository(chapters: _chapters()),
    positionRepository: _FakeReadingPositionRepository(saved: _position()),
    lookupController: lookupController ?? _FakeLookupController(),
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

List<LocalChapter> _chapters() {
  final now = DateTime.utc(2026, 5, 8);
  return [
    LocalChapter(
      id: 'chapter-1',
      bookId: 'book-1',
      chapterIndex: 0,
      title: 'Chapter 1',
      content: '先生の心。\n\n第二段落は送らない。',
      paragraphCount: 2,
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

class _FakeLookupController extends LookupController {
  _FakeLookupController({Object? error})
    : _error = error,
      super.test();

  final Object? _error;
  final List<dynamic> selections = [];

  @override
  Future<void> lookup(dynamic selection, {DateTime? now}) async {
    selections.add(selection);
    state = const LookupState.loading();
    notifyListeners();
    final error = _error;
    if (error is ApiError) {
      state = LookupState.error(error.message);
    } else {
      state = const LookupState.success(
        LookupResult(
          kind: 'lexeme',
          lexeme: LookupLexeme(
            id: 'lexeme-1',
            surface: '心',
            reading: 'こころ',
            entryType: 'word',
            partOfSpeech: 'noun',
            definition: 'heart; mind',
            shortDefinition: 'heart',
          ),
          provider: 'public_lexeme',
        ),
      );
    }
    notifyListeners();
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
