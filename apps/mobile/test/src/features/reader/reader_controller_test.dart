import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_chapter_repository.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_chapter.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_reading_position.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reading_position_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reader_preferences_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/presentation/reader_controller.dart';
import 'package:study_for_read_mobile/src/features/reader/domain/reader_preferences.dart';

void main() {
  test('loads saved chapter index for a valid local book id', () async {
    final controller = _controller(savedChapterIndex: 1);

    await controller.load();

    expect(controller.book?.id, 'book-1');
    expect(controller.currentChapterIndex, 1);
    expect(controller.currentChapter?.title, 'Chapter 2');
    expect(controller.currentChapter?.content, 'second chapter text');
  });

  test('missing local book id becomes not found', () async {
    final controller = _controller(missingBook: true);

    await controller.load();

    expect(controller.notFound, isTrue);
    expect(controller.currentChapter, isNull);
  });

  test(
    'next and previous chapters save dirty local reading position',
    () async {
      final positionRepository = _FakeReadingPositionRepository(
        saved: _position(chapterIndex: 0),
      );
      final controller = _controller(positionRepository: positionRepository);

      await controller.load();
      await controller.nextChapter();
      await controller.previousChapter();

      expect(controller.currentChapterIndex, 0);
      expect(positionRepository.savedPositions, hasLength(2));
      expect(positionRepository.savedPositions.first.currentChapterIndex, 1);
      expect(
        positionRepository.savedPositions.first.progressSyncStatus,
        'dirty',
      );
      expect(positionRepository.savedPositions.last.currentChapterIndex, 0);
      expect(
        positionRepository.savedPositions.last.progressSyncStatus,
        'dirty',
      );
    },
  );

  test('chapter navigation is bounded by first and last chapters', () async {
    final controller = _controller(savedChapterIndex: 0);

    await controller.load();

    expect(controller.canGoPrevious, isFalse);
    expect(controller.canGoNext, isTrue);

    await controller.nextChapter();
    await controller.nextChapter();

    expect(controller.currentChapterIndex, 2);
    expect(controller.canGoPrevious, isTrue);
    expect(controller.canGoNext, isFalse);
  });

  test('page state is bounded when page count changes', () async {
    final controller = _controller(savedChapterIndex: 0);

    await controller.load();
    controller.setPageCount(4);
    controller.goToPage(3);
    controller.setPageCount(2);

    expect(controller.currentPageCount, 2);
    expect(controller.currentPageIndex, 1);

    controller.goToPage(99);
    expect(controller.currentPageIndex, 1);

    controller.goToPage(-1);
    expect(controller.currentPageIndex, 1);
  });

  test(
    'next and previous page cross chapter boundaries at page edges',
    () async {
      final positionRepository = _FakeReadingPositionRepository(
        saved: _position(chapterIndex: 0),
      );
      final controller = _controller(positionRepository: positionRepository);

      await controller.load();
      controller.setPageCount(3);
      await controller.nextPage();
      await controller.nextPage();

      expect(controller.currentChapterIndex, 0);
      expect(controller.currentPageIndex, 2);

      await controller.nextPage();

      expect(controller.currentChapterIndex, 1);
      expect(controller.currentPageIndex, 0);

      await controller.previousPage();

      expect(controller.currentChapterIndex, 0);
      expect(controller.currentPageIndex, 0);
      expect(positionRepository.savedPositions.last.currentChapterIndex, 0);
    },
  );

  test(
    'goToChapter jumps to a valid chapter and saves dirty progress',
    () async {
      final positionRepository = _FakeReadingPositionRepository(
        saved: _position(chapterIndex: 0),
      );
      final controller = _controller(positionRepository: positionRepository);

      await controller.load();
      await controller.goToChapter(2);

      expect(controller.currentChapterIndex, 2);
      expect(controller.currentChapter?.title, 'Chapter 3');
      expect(positionRepository.savedPositions.single.currentChapterIndex, 2);
      expect(
        positionRepository.savedPositions.single.progressSyncStatus,
        'dirty',
      );
    },
  );

  test('goToChapter ignores invalid chapter indexes', () async {
    final positionRepository = _FakeReadingPositionRepository(
      saved: _position(chapterIndex: 1),
    );
    final controller = _controller(positionRepository: positionRepository);

    await controller.load();
    await controller.goToChapter(99);
    await controller.goToChapter(-1);

    expect(controller.currentChapterIndex, 1);
    expect(controller.currentChapter?.title, 'Chapter 2');
    expect(positionRepository.savedPositions, isEmpty);
  });

  test('font size changes stay within configured min and max', () async {
    final controller = _controller();

    await controller.load();

    for (var i = 0; i < 20; i++) {
      controller.decreaseFontSize();
    }
    expect(controller.fontSize, ReaderController.minFontSize);

    for (var i = 0; i < 20; i++) {
      controller.increaseFontSize();
    }
    expect(controller.fontSize, ReaderController.maxFontSize);
  });

  test('fresh reader uses dense novel typography defaults', () async {
    final controller = _controller();

    await controller.load();

    expect(ReaderController.defaultFontSize, 18);
    expect(controller.fontSize, 18);
    expect(controller.readerPreferences.lineHeight, 1.55);
    expect(controller.readerPreferences.paragraphSpacing, 10);
  });

  test('loads persisted reader preferences on load', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository(
      saved: ReaderPreferences.defaults.copyWith(fontSize: 24),
    );
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();

    expect(controller.fontSize, 24);
  });

  test('setFontSize persists updated reader preferences', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();
    await controller.setFontSize(24);

    expect(preferencesRepository.saved.single.fontSize, 24);
  });

  test(
    'toggleNightMode persists dark mode and restores previous background',
    () async {
      final preferencesRepository = _FakeReaderPreferencesRepository(
        saved: ReaderPreferences.defaults.copyWith(
          backgroundTheme: ReaderBackgroundTheme.warmBeige,
          previousBackgroundTheme: ReaderBackgroundTheme.eyeCareGreen,
        ),
      );
      final controller = _controller(
        preferencesRepository: preferencesRepository,
      );

      await controller.load();
      await controller.toggleNightMode();

      expect(controller.readerPreferences.nightModeEnabled, isTrue);
      expect(
        controller.readerPreferences.backgroundTheme,
        ReaderBackgroundTheme.pureBlack,
      );
      expect(
        controller.readerPreferences.previousBackgroundTheme,
        ReaderBackgroundTheme.warmBeige,
      );

      await controller.toggleNightMode();

      expect(controller.readerPreferences.nightModeEnabled, isFalse);
      expect(
        controller.readerPreferences.backgroundTheme,
        ReaderBackgroundTheme.warmBeige,
      );
      expect(preferencesRepository.saved, hasLength(2));
    },
  );

  test('setBackgroundTheme persists selected day background', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository(
      saved: ReaderPreferences.defaults.copyWith(
        nightModeEnabled: true,
        backgroundTheme: ReaderBackgroundTheme.pureBlack,
        previousBackgroundTheme: ReaderBackgroundTheme.warmBeige,
      ),
    );
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();
    await controller.setBackgroundTheme(ReaderBackgroundTheme.eyeCareGreen);

    expect(controller.readerPreferences.nightModeEnabled, isFalse);
    expect(
      controller.readerPreferences.backgroundTheme,
      ReaderBackgroundTheme.eyeCareGreen,
    );
    expect(
      controller.readerPreferences.previousBackgroundTheme,
      ReaderBackgroundTheme.eyeCareGreen,
    );
    expect(
      preferencesRepository.saved.single.backgroundTheme,
      ReaderBackgroundTheme.eyeCareGreen,
    );
  });

  test(
    'reader layout preferences persist through controller methods',
    () async {
      final preferencesRepository = _FakeReaderPreferencesRepository();
      final controller = _controller(
        preferencesRepository: preferencesRepository,
      );

      await controller.load();
      await controller.setLineHeight(2.0);
      await controller.setParagraphSpacing(30);

      expect(controller.readerPreferences.lineHeight, 2.0);
      expect(controller.readerPreferences.paragraphSpacing, 30);
      expect(preferencesRepository.saved, hasLength(2));
      expect(preferencesRepository.saved.last.lineHeight, 2.0);
      expect(preferencesRepository.saved.last.paragraphSpacing, 30);
    },
  );

  test('setBrightness persists clamped app-local brightness', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();
    await controller.setBrightness(0.5);
    await controller.setBrightness(2.0);
    await controller.setBrightness(0.1);

    expect(preferencesRepository.saved.first.brightness, 0.5);
    expect(preferencesRepository.saved[1].brightness, 1.0);
    expect(preferencesRepository.saved.last.brightness, 0.3);
  });

  test('eye protection and page turn mode preferences persist', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();
    await controller.setEyeProtectionEnabled(true);
    await controller.setPageTurnMode(ReaderPageTurnMode.cover);

    expect(controller.readerPreferences.eyeProtectionEnabled, isTrue);
    expect(controller.readerPreferences.pageTurnMode, ReaderPageTurnMode.cover);
    expect(preferencesRepository.saved, hasLength(2));
    expect(preferencesRepository.saved.last.eyeProtectionEnabled, isTrue);
    expect(
      preferencesRepository.saved.last.pageTurnMode,
      ReaderPageTurnMode.cover,
    );
  });

  test('volume key paging preference persists', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();
    await controller.setVolumeKeyPagingEnabled(true);

    expect(controller.readerPreferences.volumeKeyPagingEnabled, isTrue);
    expect(preferencesRepository.saved.single.volumeKeyPagingEnabled, isTrue);
  });

  test('furigana preference persists', () async {
    final preferencesRepository = _FakeReaderPreferencesRepository();
    final controller = _controller(
      preferencesRepository: preferencesRepository,
    );

    await controller.load();
    await controller.setFuriganaEnabled(true);

    expect(controller.readerPreferences.furiganaEnabled, isTrue);
    expect(preferencesRepository.saved.single.furiganaEnabled, isTrue);
  });
}

ReaderController _controller({
  LocalBook? book,
  bool missingBook = false,
  int savedChapterIndex = 0,
  _FakeReadingPositionRepository? positionRepository,
  ReaderPreferencesRepository? preferencesRepository,
}) {
  return ReaderController(
    bookId: 'book-1',
    bookRepository: _FakeBookRepository(
      book: missingBook ? null : book ?? _book(),
    ),
    chapterRepository: _FakeChapterRepository(chapters: _chapters()),
    positionRepository:
        positionRepository ??
        _FakeReadingPositionRepository(
          saved: _position(chapterIndex: savedChapterIndex),
        ),
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
