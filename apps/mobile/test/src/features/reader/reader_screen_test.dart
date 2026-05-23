import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_chapter.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/domain/furigana_generator.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reader_preferences_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/domain/reader_preferences.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_controller.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_screen.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reading_text_view.dart';

void main() {
  testWidgets('default reader shows full-screen text without bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    expect(find.textContaining('first chapter text'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(find.text('Kokoro'), findsNothing);
    expect(find.text('上一章'), findsNothing);
    expect(find.text('下一章'), findsNothing);
    expect(find.text('目录'), findsNothing);
  });

  testWidgets('reader displays text paragraphs with a first-line indent', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    expect(find.textContaining('\u3000first chapter text'), findsOneWidget);
  });

  testWidgets('fresh reader uses dense novel typography by default', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    final textView = tester.widget<ReadingTextView>(
      find.byType(ReadingTextView),
    );
    expect(textView.fontSize, 18);
    expect(textView.lineHeight, 1.55);
    expect(textView.paragraphSpacing, 10);
  });

  testWidgets('long chapter renders as multiple reader pages', (tester) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-page-view')), findsOneWidget);
    expect(controller.currentPageCount, greaterThan(1));
    expect(controller.currentPageIndex, 0);
  });

  testWidgets(
    'long single furigana paragraph fills the page with visible lines',
    (tester) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = _controller(
        chapters: [
          _chapter(
            index: 0,
            title: 'Single Paragraph',
            content: _longSingleJapaneseParagraphForPagination(),
          ),
        ],
        preferencesRepository: _FakeReaderPreferencesRepository(
          saved: ReaderPreferences.defaults.copyWith(furiganaEnabled: true),
        ),
      );

      await tester.pumpWidget(_app(controller));
      await tester.pumpAndSettle();

      final textView = tester.widget<ReadingTextView>(
        find.byType(ReadingTextView),
      );
      expect(textView.text.length, greaterThan(360));
      expect(controller.currentPageCount, greaterThan(1));
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('short single paragraph stays top aligned with natural blank', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = _controller(
      chapters: [
        _chapter(
          index: 0,
          title: 'Short Single Paragraph',
          content: '単なる気遣いだとしても、あるいは子供特有の無責任な発言だとしても、十分すぎるぐらいに嬉しかった。',
        ),
      ],
      preferencesRepository: _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(furiganaEnabled: true),
      ),
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    final paragraphTop = tester
        .getTopLeft(find.byKey(const Key('reader-paragraph-0')))
        .dy;
    expect(paragraphTop, lessThan(220));
    expect(controller.currentPageCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paginated Japanese reader pages do not overflow at bottom', (
    tester,
  ) async {
    final previousErrorHandler = FlutterError.onError;
    final overflowErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('A RenderFlex overflowed')) {
        overflowErrors.add(details);
        return;
      }
      previousErrorHandler?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = previousErrorHandler;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;

    final controller = _controller(
      chapters: [
        _chapter(
          index: 0,
          title: 'Acceptance Sample',
          content: _overflowProneJapaneseText(),
        ),
      ],
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    FlutterError.onError = previousErrorHandler;
    expect(overflowErrors, isEmpty);
  });

  testWidgets('swiping reader page view updates current page index', (
    tester,
  ) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('reader-page-view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPageIndex, 1);
  });

  testWidgets('vertical page turn mode uses vertical reader paging', (
    tester,
  ) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
      preferencesRepository: _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(
          pageTurnMode: ReaderPageTurnMode.vertical,
        ),
      ),
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    final pageView = tester.widget<PageView>(
      find.byKey(const Key('reader-page-view')),
    );
    expect(pageView.scrollDirection, Axis.vertical);

    await tester.drag(
      find.byKey(const Key('reader-page-view')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPageIndex, 1);
  });

  testWidgets('none page turn mode disables swipe gestures', (tester) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
      preferencesRepository: _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(
          pageTurnMode: ReaderPageTurnMode.none,
        ),
      ),
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const Key('reader-page-view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(controller.currentPageIndex, 0);
  });

  testWidgets('cover and simulation modes use distinct page wrappers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        _controller(
          chapters: [
            _chapter(
              index: 0,
              title: 'Long Chapter',
              content: _longChapterText(),
            ),
          ],
          preferencesRepository: _FakeReaderPreferencesRepository(
            saved: ReaderPreferences.defaults.copyWith(
              pageTurnMode: ReaderPageTurnMode.cover,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader-page-turn-cover')), findsWidgets);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      _app(
        _controller(
          chapters: [
            _chapter(
              index: 0,
              title: 'Long Chapter',
              content: _longChapterText(),
            ),
          ],
          preferencesRepository: _FakeReaderPreferencesRepository(
            saved: ReaderPreferences.defaults.copyWith(
              pageTurnMode: ReaderPageTurnMode.simulation,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reader-page-turn-simulation')), findsWidgets);
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
    expect(find.text('上一章'), findsOneWidget);
    expect(find.text('下一章'), findsOneWidget);
    expect(find.text('1 / 3'), findsOneWidget);
    expect(
      find.byKey(const Key('reader-chapter-progress-slider')),
      findsOneWidget,
    );
    expect(find.text('目录'), findsOneWidget);
    expect(find.text('夜间'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    expect(find.text('上一章'), findsNothing);
    expect(find.text('下一章'), findsNothing);
    expect(find.text('目录'), findsNothing);
  });

  testWidgets(
    'directory lists real chapters and jumps to the selected chapter',
    (tester) async {
      final positionRepository = _FakeReadingPositionRepository(
        saved: _position(chapterIndex: 0),
      );
      await tester.pumpWidget(
        _app(_controller(positionRepository: positionRepository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reader-tap-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('目录'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reader-directory-sheet')), findsOneWidget);
      expect(find.text('Chapter 1'), findsWidgets);
      expect(find.text('Chapter 2'), findsOneWidget);
      expect(find.text('Chapter 3'), findsOneWidget);

      await tester.tap(find.text('Chapter 3'));
      await tester.pumpAndSettle();

      expect(find.textContaining('third chapter text'), findsOneWidget);
      expect(positionRepository.savedPositions.single.currentChapterIndex, 2);
      expect(
        positionRepository.savedPositions.single.progressSyncStatus,
        'dirty',
      );
    },
  );

  testWidgets(
    'night action persists night mode and changes reader presentation',
    (tester) async {
      final preferencesRepository = _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(
          backgroundTheme: ReaderBackgroundTheme.warmBeige,
        ),
      );
      await tester.pumpWidget(
        _app(_controller(preferencesRepository: preferencesRepository)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reader-tap-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('夜间'));
      await tester.pumpAndSettle();

      expect(find.text('日间'), findsOneWidget);
      expect(
        find.byKey(const Key('reader-night-mode-background')),
        findsOneWidget,
      );
      expect(preferencesRepository.saved.single.nightModeEnabled, isTrue);
      expect(
        preferencesRepository.saved.single.backgroundTheme,
        ReaderBackgroundTheme.pureBlack,
      );
    },
  );

  testWidgets('settings action opens the reader settings panel', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reader-settings-sheet')), findsOneWidget);
    expect(find.text('亮度'), findsOneWidget);
    expect(find.text('护眼模式'), findsOneWidget);
    expect(find.text('字号'), findsOneWidget);
    expect(find.text('背景'), findsOneWidget);
    expect(find.text('翻页'), findsOneWidget);
    expect(find.text('其他'), findsOneWidget);
  });

  testWidgets(
    'settings brightness slider is enabled for app-local brightness',
    (tester) async {
      await tester.pumpWidget(_app(_controller()));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('reader-tap-area')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('设置'));
      await tester.pumpAndSettle();

      final slider = tester.widget<Slider>(
        find.byKey(const Key('reader-brightness-slider')),
      );
      expect(slider.onChanged, isNotNull);
    },
  );

  testWidgets('brightness slider persists value and dims reader only', (
    tester,
  ) async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _app(_controller(preferencesRepository: preferencesRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    tester
        .widget<Slider>(find.byKey(const Key('reader-brightness-slider')))
        .onChanged!
        .call(0.5);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('reader-brightness-dim-overlay')),
      findsOneWidget,
    );
    expect(preferencesRepository.saved.single.brightness, 0.5);
  });

  testWidgets('settings font controls update reading text size', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-font-increase-button')));
    await tester.pumpAndSettle();

    final textView = tester.widget<ReadingTextView>(
      find.byType(ReadingTextView),
    );
    expect(textView.fontSize, 20);
  });

  testWidgets('settings background selection persists reader background', (
    tester,
  ) async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _app(_controller(preferencesRepository: preferencesRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('护眼绿'));
    await tester.pumpAndSettle();

    expect(
      preferencesRepository.saved.last.backgroundTheme,
      ReaderBackgroundTheme.eyeCareGreen,
    );
  });

  testWidgets('settings eye protection toggle changes reader presentation', (
    tester,
  ) async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _app(_controller(preferencesRepository: preferencesRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-eye-protection-switch')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('reader-eye-protection-overlay')),
      findsOneWidget,
    );
    expect(preferencesRepository.saved.last.eyeProtectionEnabled, isTrue);
  });

  testWidgets('settings layout sliders update reading layout values', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();

    tester
        .widget<Slider>(find.byKey(const Key('reader-line-height-slider')))
        .onChanged!
        .call(2.0);
    tester
        .widget<Slider>(
          find.byKey(const Key('reader-paragraph-spacing-slider')),
        )
        .onChanged!
        .call(30);
    await tester.pumpAndSettle();

    final textView = tester.widget<ReadingTextView>(
      find.byType(ReadingTextView),
    );
    expect(textView.lineHeight, 2.0);
    expect(textView.paragraphSpacing, 30);
  });

  testWidgets('settings volume key paging switch persists preference', (
    tester,
  ) async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _app(_controller(preferencesRepository: preferencesRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('reader-volume-key-paging-switch')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-volume-key-paging-switch')));
    await tester.pumpAndSettle();

    expect(preferencesRepository.saved.last.volumeKeyPagingEnabled, isTrue);
  });

  testWidgets('settings furigana switch persists preference', (tester) async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _app(_controller(preferencesRepository: preferencesRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-settings-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('reader-furigana-switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-furigana-switch')));
    await tester.pumpAndSettle();

    expect(preferencesRepository.saved.last.furiganaEnabled, isTrue);
  });

  testWidgets('volume down advances page when volume key paging is enabled', (
    tester,
  ) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
      preferencesRepository: _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(
          volumeKeyPagingEnabled: true,
        ),
      ),
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.audioVolumeDown);
    await tester.pumpAndSettle();

    expect(controller.currentPageIndex, 1);
  });

  testWidgets('volume up moves to previous page when enabled', (tester) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
      preferencesRepository: _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(
          volumeKeyPagingEnabled: true,
        ),
      ),
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await controller.nextPage();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.audioVolumeUp);
    await tester.pumpAndSettle();

    expect(controller.currentPageIndex, 0);
  });

  testWidgets('volume keys do nothing when volume key paging is disabled', (
    tester,
  ) async {
    final controller = _controller(
      chapters: [
        _chapter(index: 0, title: 'Long Chapter', content: _longChapterText()),
      ],
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.audioVolumeDown);
    await tester.pumpAndSettle();

    expect(controller.currentPageIndex, 0);
  });

  testWidgets('settings page turn mode selection persists selected mode', (
    tester,
  ) async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    await tester.pumpWidget(
      _app(_controller(preferencesRepository: preferencesRepository)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('覆盖'));
    await tester.pumpAndSettle();

    expect(
      preferencesRepository.saved.last.pageTurnMode,
      ReaderPageTurnMode.cover,
    );
  });

  testWidgets('reader-renders-epub-image-page-chapters-as-images', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextView(
            text:
                '![epub-image](${Uri.file('${Directory.systemTemp.path}/epub-page.png')})',
            fontSize: ReaderController.defaultFontSize,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('epub-image-page-0')), findsOneWidget);
    expect(find.textContaining('![epub-image]'), findsNothing);
  });

  testWidgets('reading text view shows ruby text when furigana is enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextView(
            text: '悲劇の最中',
            fontSize: ReaderController.defaultFontSize,
            furiganaEnabled: true,
            furiganaGenerator: _fakeFurigana,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ひげき'), findsOneWidget);
    expect(find.text('悲劇'), findsOneWidget);
    expect(find.text('さいちゅう'), findsOneWidget);
    expect(find.text('最中'), findsOneWidget);
  });

  testWidgets('furigana mode lookup still sends original text', (tester) async {
    final lookedUp = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextView(
            text: '悲劇の最中',
            fontSize: ReaderController.defaultFontSize,
            furiganaEnabled: true,
            furiganaGenerator: _fakeFurigana,
            onLookup: (selection) => lookedUp.add(selection.selectedText),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final paragraphRect = tester.getRect(
      find.byKey(const Key('reader-paragraph-0')),
    );
    await tester.tapAt(paragraphRect.centerLeft + const Offset(44, 0));
    await tester.pumpAndSettle();

    expect(lookedUp, ['悲劇']);
  });

  testWidgets('tapping an EPUB image page opens a larger preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReadingTextView(
            text:
                '![epub-image](${Uri.file('${Directory.systemTemp.path}/epub-page.png')})',
            fontSize: ReaderController.defaultFontSize,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const Key('epub-image-page-0')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('epub-image-preview')), findsOneWidget);
  });

  testWidgets('reader controls expose a close action', (tester) async {
    var closeCount = 0;
    await tester.pumpWidget(
      _app(_controller(), onClose: () => closeCount += 1),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reader-close-button')));
    await tester.pumpAndSettle();

    expect(closeCount, 1);
  });

  testWidgets('visible controls reserve space for reading text', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    final controlBottom = tester.getBottomLeft(find.text('Chapter 1')).dy;
    final readingTop = tester
        .getTopLeft(find.textContaining('first chapter text'))
        .dy;

    expect(readingTop, greaterThan(controlBottom + 16));
  });

  testWidgets('visible controls use opaque surfaces over reading text', (
    tester,
  ) async {
    await tester.pumpWidget(_app(_controller()));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reader-tap-area')));
    await tester.pumpAndSettle();

    expect(
      find.ancestor(
        of: find.byKey(const Key('reader-close-button')),
        matching: find.byWidgetPredicate(_isOpaqueContainer),
      ),
      findsWidgets,
    );
    expect(
      find.ancestor(
        of: find.byKey(const Key('reader-chapter-progress-slider')),
        matching: find.byWidgetPredicate(_isOpaqueContainer),
      ),
      findsWidgets,
    );
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

    await tester.tap(find.text('下一章'));
    await tester.pumpAndSettle();

    expect(find.textContaining('second chapter text'), findsOneWidget);
    expect(positionRepository.savedPositions.last.currentChapterIndex, 1);
    expect(positionRepository.savedPositions.last.progressSyncStatus, 'dirty');

    await tester.tap(find.text('上一章'));
    await tester.pumpAndSettle();

    expect(find.textContaining('first chapter text'), findsOneWidget);
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
      find.widgetWithText(TextButton, '上一章'),
    );
    expect(previous.onPressed, isNull);

    await tester.tap(find.text('下一章'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一章'));
    await tester.pumpAndSettle();

    final next = tester.widget<TextButton>(
      find.widgetWithText(TextButton, '下一章'),
    );
    expect(next.onPressed, isNull);
  });

  testWidgets('bottom progress slider jumps to chapters within bounds', (
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

    await tester.drag(
      find.byKey(const Key('reader-chapter-progress-slider')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('third chapter text'), findsOneWidget);
    expect(positionRepository.savedPositions, isNotEmpty);
  });

  testWidgets('missing local book id shows not found state', (tester) async {
    await tester.pumpWidget(_app(_controller(missingBook: true)));
    await tester.pumpAndSettle();

    expect(find.text('未找到本地书籍'), findsOneWidget);
    expect(find.text('first chapter text'), findsNothing);
  });
}

Future<List<FuriganaSegment>> _fakeFurigana(String text) async {
  return [
    for (final segment
        in text
            .splitMapJoin(
              RegExp('悲劇|最中'),
              onMatch: (match) => '\u0000${match.group(0)}\u0000',
              onNonMatch: (value) => value,
            )
            .split('\u0000')
            .where((value) => value.isNotEmpty))
      switch (segment) {
        '悲劇' => const FuriganaSegment(text: '悲劇', reading: 'ひげき'),
        '最中' => const FuriganaSegment(text: '最中', reading: 'さいちゅう'),
        _ => FuriganaSegment(text: segment),
      },
  ];
}

bool _isOpaqueContainer(Widget widget) {
  if (widget is! Container) {
    return false;
  }
  final color = widget.color;
  return color != null && color.a == 1;
}

Widget _app(ReaderController controller, {VoidCallback? onClose}) {
  return MaterialApp(
    home: ReaderScreen(
      bookId: 'book-1',
      controller: controller,
      onClose: onClose,
    ),
  );
}

ReaderController _controller({
  bool missingBook = false,
  List<LocalChapter>? chapters,
  _FakeReadingPositionRepository? positionRepository,
  ReaderPreferencesRepository? preferencesRepository,
}) {
  return ReaderController(
    bookId: 'book-1',
    bookRepository: _FakeBookRepository(book: missingBook ? null : _book()),
    chapterRepository: _FakeChapterRepository(
      chapters: chapters ?? _chapters(),
    ),
    positionRepository:
        positionRepository ??
        _FakeReadingPositionRepository(saved: _position(chapterIndex: 0)),
    preferencesRepository: preferencesRepository,
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

String _longChapterText() {
  return List<String>.generate(
    80,
    (index) => '这是第 $index 段测试文字，用来验证阅读器会按照手机屏幕高度分页显示，而不是把整章作为一个长滚动页面。',
  ).join('\n\n');
}

String _overflowProneJapaneseText() {
  return List<String>.filled(
    18,
    'そうそう。困っちゃうわよねー。就職決まったから、調子に乗って一人暮らし始めたんだけど……生まれてからずっと実家暮らしだったから、一人で生活するのが、寂しくて寂しくて。',
  ).join('');
}

String _longSingleJapaneseParagraphForPagination() {
  final body = List<String>.filled(
    16,
    'それでも夕方になると、台所から聞こえる包丁の音や、廊下に落ちる光の色だけは不思議なくらい鮮やかに思い出せた。',
  ).join();
  return '十歳になったころには、私はもう母の顔をよく覚えていなかった。$body';
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

class _FakeReaderPreferencesRepository implements ReaderPreferencesRepository {
  _FakeReaderPreferencesRepository({ReaderPreferences? saved})
    : _saved = saved ?? ReaderPreferences.defaults;

  ReaderPreferences _saved;
  final List<ReaderPreferences> saved = [];

  @override
  Future<ReaderPreferences> load() async => _saved;

  @override
  Future<void> save(ReaderPreferences preferences) async {
    _saved = preferences;
    saved.add(preferences);
  }
}
