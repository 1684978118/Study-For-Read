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
    title: '验收阅读样书',
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
      title: '第一章 验收阅读页',
      content: [
        '第一章的阅读验收文本，用来观察手机屏幕上的段首缩进、行距、段距和分页效果。文字全部为合成内容，不来自任何导入书籍。',
        '第二段继续模拟普通小说阅读场景。点击页面空白处会打开底部控制栏，可以检查目录、夜间模式和设置面板是否自然。',
        '第三段专门留给翻页和段落操作验收。段落旁边的轻量按钮只表示可翻译当前段落，不应该像正文字符一样抢眼。',
      ].join('\n\n'),
      paragraphCount: 3,
      createdAt: now,
      updatedAt: now,
    ),
    LocalChapter(
      id: 'acceptance-chapter-2',
      bookId: bookId,
      chapterIndex: 1,
      title: '第二章 目录跳转验收',
      content: [
        '第二章用于检查真实目录和下一章控制。进入这一章后，阅读器仍然应该保持全屏、无主底部导航，并保存本地阅读位置。',
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
