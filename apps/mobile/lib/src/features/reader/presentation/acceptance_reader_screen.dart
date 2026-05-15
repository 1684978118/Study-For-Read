import 'package:flutter/material.dart';

import '../../library/data/local_book_repository.dart';
import '../../library/data/local_chapter_repository.dart';
import '../../library/domain/local_book.dart';
import '../../library/domain/local_chapter.dart';
import '../../library/domain/local_reading_position.dart';
import '../data/local_reading_position_repository.dart';
import '../data/local_reader_preferences_repository.dart';
import '../domain/reader_preferences.dart';
import 'reader_controller.dart';
import 'reader_screen.dart';

class AcceptanceReaderScreen extends StatefulWidget {
  const AcceptanceReaderScreen({super.key});

  @override
  State<AcceptanceReaderScreen> createState() => _AcceptanceReaderScreenState();
}

class _AcceptanceReaderScreenState extends State<AcceptanceReaderScreen> {
  late final ReaderController _controller = ReaderController(
    bookId: _AcceptanceSeed.bookId,
    bookRepository: _AcceptanceBookRepository(),
    chapterRepository: _AcceptanceChapterRepository(),
    positionRepository: _AcceptancePositionRepository(),
    preferencesRepository: _AcceptancePreferencesRepository(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ReaderScreen(controller: _controller);
  }
}

class _AcceptanceSeed {
  static const bookId = 'acceptance-reader-seed-book';

  static final now = DateTime.utc(2026, 5, 15);

  static final book = LocalBook(
    id: bookId,
    ownerUserId: 'acceptance-user',
    bookFingerprint: 'acceptance-reader-seed-fingerprint',
    title: 'Acceptance Reader Seed',
    author: 'Study For Read',
    fileType: 'txt',
    sourceLang: 'ja',
    targetLang: 'zh',
    originalFilePath: '',
    chapterCount: chapters.length,
    metadataSyncStatus: 'local_only',
    lastOpenedAt: now,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );

  static final chapters = [
    LocalChapter(
      id: 'acceptance-chapter-1',
      bookId: bookId,
      chapterIndex: 0,
      title: '验收样章一',
      content: [
        'Acceptance Reader Seed chapter one. This synthetic paragraph is long enough to paginate on a phone emulator and lets visual QA inspect first-line indent, line spacing, and page turning.',
        '第二段是中文验收文本，用来观察段首缩进、段距、背景色、夜间模式、目录和设置面板是否符合移动阅读体验。',
        'Tap the blank reading area to open the Fanqie-style bottom controls, then open directory and settings for emulator screenshots.',
      ].join('\n\n'),
      paragraphCount: 3,
      createdAt: now,
      updatedAt: now,
    ),
    LocalChapter(
      id: 'acceptance-chapter-2',
      bookId: bookId,
      chapterIndex: 1,
      title: '验收样章二',
      content: [
        'Acceptance Reader Seed chapter two. The second chapter exists so the real directory and next chapter controls can be checked during emulator acceptance.',
        '这里仍然只使用合成文本，不包含用户导入书籍、原始路径、选中文本、翻译内容或后端同步 payload。',
      ].join('\n\n'),
      paragraphCount: 2,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

class _AcceptanceBookRepository implements LocalBookRepository {
  Future<LocalBook?> findById(String id) async {
    return id == _AcceptanceSeed.bookId ? _AcceptanceSeed.book : null;
  }

  @override
  Future<LocalBook?> findByOwnerUserIdAndBookFingerprint({
    required String ownerUserId,
    required String bookFingerprint,
  }) async {
    if (ownerUserId == _AcceptanceSeed.book.ownerUserId &&
        bookFingerprint == _AcceptanceSeed.book.bookFingerprint) {
      return _AcceptanceSeed.book;
    }
    return null;
  }

  @override
  Future<List<LocalBook>> findByOwnerUserId(String ownerUserId) async {
    return ownerUserId == _AcceptanceSeed.book.ownerUserId
        ? [_AcceptanceSeed.book]
        : const [];
  }

  @override
  Future<int> insert(LocalBook book) async => 1;

  @override
  Future<int> update(LocalBook book) async => 1;
}

class _AcceptanceChapterRepository implements LocalChapterRepository {
  @override
  Future<int> deleteByBookId(String bookId) async => 0;

  @override
  Future<LocalChapter?> findByBookIdAndChapterIndex({
    required String bookId,
    required int chapterIndex,
  }) async {
    if (bookId != _AcceptanceSeed.bookId) {
      return null;
    }
    for (final chapter in _AcceptanceSeed.chapters) {
      if (chapter.chapterIndex == chapterIndex) {
        return chapter;
      }
    }
    return null;
  }

  @override
  Future<List<LocalChapter>> findByBookIdOrderByChapterIndex(
    String bookId,
  ) async {
    return bookId == _AcceptanceSeed.bookId
        ? List.unmodifiable(_AcceptanceSeed.chapters)
        : const [];
  }

  @override
  Future<int> insert(LocalChapter chapter) async => 1;
}

class _AcceptancePositionRepository implements LocalReadingPositionRepository {
  LocalReadingPosition? _saved;

  @override
  Future<LocalReadingPosition?> findByBookId(String bookId) async {
    return bookId == _AcceptanceSeed.bookId ? _saved : null;
  }

  @override
  Future<void> upsert(LocalReadingPosition position) async {
    if (position.bookId == _AcceptanceSeed.bookId) {
      _saved = position;
    }
  }
}

class _AcceptancePreferencesRepository implements ReaderPreferencesRepository {
  ReaderPreferences _preferences = ReaderPreferences.defaults;

  @override
  Future<ReaderPreferences> load() async => _preferences;

  @override
  Future<void> save(ReaderPreferences preferences) async {
    _preferences = preferences;
  }
}
