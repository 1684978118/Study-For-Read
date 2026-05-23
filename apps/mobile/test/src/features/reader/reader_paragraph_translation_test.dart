import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_chapter.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/domain/furigana_generator.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_controller.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_screen.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reading_text_view.dart';
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

    final paragraphLeft = tester
        .getTopLeft(find.byKey(const Key('reader-paragraph-0')))
        .dx;
    final hotspotLeft = tester
        .getTopLeft(find.byKey(const Key('paragraph-translate-hotspot-0')))
        .dx;

    expect(hotspotLeft, greaterThan(paragraphLeft + 120));
  });

  testWidgets('paragraph translate plus sits on the sentence end row', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(_controller(content: 'これは……キツいだろう。')),
    );
    await tester.pumpAndSettle();

    final paragraphRect = tester.getRect(
      find.byKey(const Key('reader-paragraph-0')),
    );
    final hotspotRect = tester.getRect(
      find.byKey(const Key('paragraph-translate-hotspot-0')),
    );

    expect(hotspotRect.center.dy, greaterThan(paragraphRect.top));
    expect(hotspotRect.center.dy, lessThan(paragraphRect.bottom));
    expect(hotspotRect.left, lessThan(paragraphRect.right + 72));
  });

  testWidgets('paragraph translate plus follows the final wrapped text row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ReadingTextView(
              text: '『飲んだくれアラサー女はキツい大作戦』。',
              fontSize: 36,
              lineHeight: 1.72,
              paragraphSpacing: 0,
              padding: EdgeInsets.zero,
              onTranslateParagraph: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraphRect = tester.getRect(
      find.byKey(const Key('reader-paragraph-0')),
    );
    final hotspotRect = tester.getRect(
      find.byKey(const Key('paragraph-translate-hotspot-0')),
    );

    expect(hotspotRect.center.dy, greaterThan(paragraphRect.center.dy));
    expect(hotspotRect.left, greaterThan(paragraphRect.left + 80));
    expect(hotspotRect.left, lessThan(paragraphRect.right + 60));
  });

  testWidgets('furigana paragraph translate plus stays after the final row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: ReadingTextView(
              text: '「こないだのワインの残り……一人で飲んじゃったんですか？」',
              fontSize: 36,
              lineHeight: 1.72,
              paragraphSpacing: 0,
              padding: EdgeInsets.zero,
              furiganaEnabled: true,
              furiganaGenerator: (_) async => const [
                FuriganaSegment(text: '「こないだのワインの残り……一'),
                FuriganaSegment(text: '人', reading: 'ひとり'),
                FuriganaSegment(text: 'で'),
                FuriganaSegment(text: '飲', reading: 'の'),
                FuriganaSegment(text: 'んじゃったんですか？」'),
              ],
              onTranslateParagraph: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraphRect = tester.getRect(
      find.byKey(const Key('reader-paragraph-0')),
    );
    final hotspotRect = tester.getRect(
      find.byKey(const Key('paragraph-translate-hotspot-0')),
    );

    expect(hotspotRect.center.dy, greaterThan(paragraphRect.center.dy));
  });

  testWidgets(
    'furigana paragraph translate plus stays out of the gap before next paragraph',
    (tester) async {
      const firstParagraph =
          'A long ruby paragraph wraps through several reader rows before it '
          'finishes with a short final tail nai.';
      const secondParagraph = 'And then.';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ReadingTextView(
                text: '$firstParagraph\n\n$secondParagraph',
                fontSize: 36,
                lineHeight: 1.72,
                paragraphSpacing: 20,
                padding: EdgeInsets.zero,
                furiganaEnabled: true,
                furiganaGenerator: (_) async => const [
                  FuriganaSegment(
                    text:
                        'A long ruby paragraph wraps through several reader rows before it ',
                  ),
                  FuriganaSegment(
                    text: 'finishes',
                    reading: 'reading',
                  ),
                  FuriganaSegment(text: ' with a short final tail nai.'),
                  FuriganaSegment(text: 'And then.'),
                ],
                onTranslateParagraph: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstTextRect = tester.getRect(
        find.byKey(const Key('reader-paragraph-0')),
      );
      final secondTextRect = tester.getRect(
        find.byKey(const Key('reader-paragraph-1')),
      );
      final firstHotspotRect = tester.getRect(
        find.byKey(const Key('paragraph-translate-hotspot-0')),
      );

      expect(firstHotspotRect.center.dy, lessThanOrEqualTo(secondTextRect.top));
      expect(
        firstHotspotRect.center.dy,
        greaterThan(firstTextRect.bottom - 140),
      );
      expect(
        firstHotspotRect.center.dy,
        lessThanOrEqualTo(firstTextRect.bottom + 12),
      );
    },
  );

  testWidgets(
    'furigana paragraph translate plus hugs rendered paragraph bottom before a large gap',
    (tester) async {
      const firstParagraph =
          '単なる気遣いだとしても、あるいは子供特有の無責任な発言だとしても、十分すぎるぐらいに嬉しかった。';
      const secondParagraph =
          '十歳になったばかりの子供が、追い詰められていた私の心を優しく温めてくれた。';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              child: ReadingTextView(
                text: '$firstParagraph\n\n$secondParagraph',
                fontSize: 36,
                lineHeight: 1.72,
                paragraphSpacing: 120,
                padding: EdgeInsets.zero,
                furiganaEnabled: true,
                furiganaGenerator: (_) async => const [
                  FuriganaSegment(text: firstParagraph),
                  FuriganaSegment(text: secondParagraph),
                ],
                onTranslateParagraph: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstTextRect = tester.getRect(
        find.byKey(const Key('reader-paragraph-0')),
      );
      final secondTextRect = tester.getRect(
        find.byKey(const Key('reader-paragraph-1')),
      );
      final firstHotspotRect = tester.getRect(
        find.byKey(const Key('paragraph-translate-hotspot-0')),
      );
      final gapMidpoint = firstTextRect.bottom +
          (secondTextRect.top - firstTextRect.bottom) / 2;

      expect(
        firstHotspotRect.center.dy,
        greaterThan(firstTextRect.bottom - 36),
      );
      expect(firstHotspotRect.top, lessThan(firstTextRect.bottom + 8));
      expect(firstHotspotRect.center.dy, lessThan(gapMidpoint));
    },
  );

  testWidgets('paragraph translate plus is positioned without changing text flow', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextView(
            text: '「うん、飲んじゃったの。酔っ払っちゃったのー」',
            fontSize: 36,
            lineHeight: 1.72,
            paragraphSpacing: 0,
            padding: EdgeInsets.zero,
            furiganaEnabled: true,
            furiganaGenerator: (_) async => const [
              FuriganaSegment(text: '「うん、'),
              FuriganaSegment(text: '飲', reading: 'の'),
              FuriganaSegment(text: 'んじゃったの。'),
              FuriganaSegment(text: '酔', reading: 'よ'),
              FuriganaSegment(text: 'っ払っちゃったのー」'),
            ],
            onTranslateParagraph: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final hotspot = find.byKey(const Key('paragraph-translate-hotspot-0'));

    expect(hotspot, findsOneWidget);
    expect(
      find.ancestor(of: hotspot, matching: find.byType(Stack)),
      findsWidgets,
    );
  });

  testWidgets('paginated furigana reader does not overflow on a short page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 620);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 430,
            child: ReadingTextView(
              text:
                  '私は、完全にできあがっていた。\n\n'
                  '「綾子さん。すみません、美羽がなんか飲み物が欲しいってーえっ！」\n\n'
                  '飲み物を取りに来たらしいタッくんは、リビングのドアを開いた。',
              fontSize: 36,
              lineHeight: 1.72,
              paragraphSpacing: 18,
              padding: const EdgeInsets.fromLTRB(24, 44, 24, 56),
              paginated: true,
              furiganaEnabled: true,
              furiganaGenerator: (_) async => const [
                FuriganaSegment(text: '私は、完全にできあがっていた。'),
                FuriganaSegment(text: '「綾子さん。すみません、美羽がなんか飲み物が欲しいってーえっ！」'),
                FuriganaSegment(text: '飲み物を取りに来たらしいタッくんは、リビングのドアを開いた。'),
              ],
              onTranslateParagraph: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
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

  testWidgets('inline translation does not overflow a short reader page', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final translationController = _FakeParagraphTranslationController(
      nextState: const ParagraphTranslationState.success(
        translatedText:
            'This translated paragraph is intentionally long enough to wrap '
            'onto several lines inside a short reader viewport.',
        provider: 'fallback',
      ),
    );
    await tester.pumpWidget(
      _app(
        _controller(
          translationController: translationController,
          content:
              'A compact original paragraph that fits before translation is '
              'inserted below it.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('paragraph-translate-hotspot-0')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('epub image page scales to the reader viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 560);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _app(_controller(content: '![epub-image](file:///missing-cover.png)')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

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
