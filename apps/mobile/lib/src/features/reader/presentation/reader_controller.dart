import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../library/data/local_book_repository.dart';
import '../../library/data/local_chapter_repository.dart';
import '../../library/domain/local_book.dart';
import '../../library/domain/local_chapter.dart';
import '../../library/domain/local_reading_position.dart';
import '../../study/presentation/paragraph_translation_controller.dart';
import '../../study/presentation/lookup_controller.dart';
import '../../stats/data/local_study_stats_repository.dart';
import '../../stats/data/study_stats_tracker.dart';
import '../data/local_reading_position_repository.dart';
import '../data/local_reader_preferences_repository.dart';
import '../domain/reader_preferences.dart';

class ReaderController extends ChangeNotifier {
  ReaderController({
    required String bookId,
    required LocalBookRepository bookRepository,
    required LocalChapterRepository chapterRepository,
    required LocalReadingPositionRepository positionRepository,
    LookupController? lookupController,
    ParagraphTranslationController? paragraphTranslationController,
    StudyStatsTracker? statsTracker,
    LocalStudyStatsRepository? statsRepository,
    ReaderPreferencesRepository? preferencesRepository,
    DateTime Function()? now,
  }) : _bookId = bookId,
       _bookRepository = bookRepository,
       _chapterRepository = chapterRepository,
       _positionRepository = positionRepository,
       _lookupController = lookupController,
       _paragraphTranslationController = paragraphTranslationController,
       _statsTracker = statsTracker,
       _statsRepository = statsRepository,
       _preferencesRepository = preferencesRepository,
       _now = now ?? DateTime.now;

  static const double minFontSize = 16;
  static const double maxFontSize = 28;
  static const double defaultFontSize = 20;
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.4;
  static const double minParagraphSpacing = 0;
  static const double maxParagraphSpacing = 36;

  final String _bookId;
  final LocalBookRepository _bookRepository;
  final LocalChapterRepository _chapterRepository;
  final LocalReadingPositionRepository _positionRepository;
  LookupController? _lookupController;
  ParagraphTranslationController? _paragraphTranslationController;
  StudyStatsTracker? _statsTracker;
  final LocalStudyStatsRepository? _statsRepository;
  final ReaderPreferencesRepository? _preferencesRepository;
  final DateTime Function() _now;

  bool _isLoading = false;
  bool _notFound = false;
  LocalBook? _book;
  List<LocalChapter> _chapters = const [];
  int _currentChapterIndex = 0;
  double _fontSize = defaultFontSize;
  ReaderPreferences _readerPreferences = ReaderPreferences.defaults;
  String? _positionId;
  DateTime? _positionCreatedAt;
  DateTime? _readingSessionStartedAt;

  bool get isLoading => _isLoading;
  bool get notFound => _notFound;
  LocalBook? get book => _book;
  List<LocalChapter> get chapters => List.unmodifiable(_chapters);
  LocalChapter? get currentChapter =>
      _chapters.isEmpty ? null : _chapters[_currentChapterIndex];
  int get currentChapterIndex => _currentChapterIndex;
  double get fontSize => _fontSize;
  ReaderPreferences get readerPreferences => _readerPreferences;
  bool get canGoPrevious => _currentChapterIndex > 0;
  bool get canGoNext => _currentChapterIndex < _chapters.length - 1;
  String get progressLabel => _chapters.isEmpty
      ? '0 / 0'
      : '${_currentChapterIndex + 1} / ${_chapters.length}';
  LookupController? get lookupController => _lookupController;
  ParagraphTranslationController? get paragraphTranslationController =>
      _paragraphTranslationController;

  static Future<ReaderController> local(String bookId) async {
    final database = await MobileDatabase().open();
    return ReaderController(
      bookId: bookId,
      bookRepository: LocalBookRepository(database),
      chapterRepository: LocalChapterRepository(database),
      positionRepository: LocalReadingPositionRepository(database),
      preferencesRepository: LocalReaderPreferencesRepository(database),
      statsRepository: LocalStudyStatsRepository(database),
    );
  }

  Future<void> load() async {
    _isLoading = true;
    _notFound = false;
    notifyListeners();

    final book = await findLocalBookById(_bookRepository, _bookId);
    if (book == null) {
      _markNotFound();
      return;
    }

    final chapters = await _chapterRepository.findByBookIdOrderByChapterIndex(
      book.id,
    );
    if (chapters.isEmpty) {
      _markNotFound();
      return;
    }

    final position = await _positionRepository.findByBookId(book.id);
    final preferences =
        await _preferencesRepository?.load() ?? ReaderPreferences.defaults;
    _positionId = position?.id;
    _positionCreatedAt = position?.createdAt;
    _book = book;
    _chapters = chapters;
    _statsTracker ??= _statsRepository == null
        ? null
        : StudyStatsTracker(
            ownerUserId: book.ownerUserId,
            repository: _statsRepository,
          );
    _readingSessionStartedAt = _now();
    _currentChapterIndex = (position?.currentChapterIndex ?? 0).clamp(
      0,
      chapters.length - 1,
    );
    _readerPreferences = preferences;
    _fontSize = preferences.fontSize.clamp(minFontSize, maxFontSize);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> nextChapter() async {
    if (!canGoNext) {
      return;
    }
    _currentChapterIndex += 1;
    notifyListeners();
    await saveProgress();
  }

  Future<void> previousChapter() async {
    if (!canGoPrevious) {
      return;
    }
    _currentChapterIndex -= 1;
    notifyListeners();
    await saveProgress();
  }

  Future<void> goToChapter(int chapterIndex) async {
    if (chapterIndex < 0 || chapterIndex >= _chapters.length) {
      return;
    }
    if (chapterIndex == _currentChapterIndex) {
      return;
    }
    _currentChapterIndex = chapterIndex;
    notifyListeners();
    await saveProgress();
  }

  Future<void> setFontSize(double value) {
    _fontSize = value.clamp(minFontSize, maxFontSize);
    _readerPreferences = _readerPreferences.copyWith(fontSize: _fontSize);
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> increaseFontSize() {
    return setFontSize(_fontSize + 2);
  }

  Future<void> decreaseFontSize() {
    return setFontSize(_fontSize - 2);
  }

  Future<void> toggleNightMode() {
    final current = _readerPreferences;
    if (current.nightModeEnabled) {
      _readerPreferences = current.copyWith(
        nightModeEnabled: false,
        backgroundTheme: current.previousBackgroundTheme,
      );
    } else {
      _readerPreferences = current.copyWith(
        nightModeEnabled: true,
        previousBackgroundTheme: current.backgroundTheme,
        backgroundTheme: ReaderBackgroundTheme.pureBlack,
      );
    }
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> setBackgroundTheme(ReaderBackgroundTheme theme) {
    _readerPreferences = _readerPreferences.copyWith(
      backgroundTheme: theme,
      previousBackgroundTheme: theme,
      nightModeEnabled: false,
    );
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> setEyeProtectionEnabled(bool value) {
    _readerPreferences = _readerPreferences.copyWith(
      eyeProtectionEnabled: value,
    );
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> setLineHeight(double value) {
    _readerPreferences = _readerPreferences.copyWith(
      lineHeight: value.clamp(minLineHeight, maxLineHeight),
    );
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> setParagraphSpacing(double value) {
    _readerPreferences = _readerPreferences.copyWith(
      paragraphSpacing: value.clamp(minParagraphSpacing, maxParagraphSpacing),
    );
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> setPageTurnMode(ReaderPageTurnMode mode) {
    _readerPreferences = _readerPreferences.copyWith(pageTurnMode: mode);
    notifyListeners();
    return _preferencesRepository?.save(_readerPreferences) ?? Future.value();
  }

  Future<void> saveProgress() async {
    final book = _book;
    if (book == null || _chapters.isEmpty) {
      return;
    }

    final now = DateTime.now().toUtc();
    await _positionRepository.upsert(
      LocalReadingPosition(
        id: _positionId ?? _uuidV4(),
        bookId: book.id,
        currentChapterIndex: _currentChapterIndex,
        currentParagraphIndex: 0,
        currentCharOffset: 0,
        progressSyncStatus: 'dirty',
        lastReadAt: now,
        lastSyncedAt: null,
        createdAt: _positionCreatedAt ?? now,
        updatedAt: now,
      ),
    );
  }

  Future<void> endReadingSession() async {
    final startedAt = _readingSessionStartedAt;
    final tracker = _statsTracker;
    if (startedAt == null || tracker == null) {
      return;
    }

    final endedAt = _now();
    _readingSessionStartedAt = endedAt;
    await tracker.recordReadingSession(endedAt.difference(startedAt));
  }

  Future<LookupController> ensureLookupController() async {
    final existing = _lookupController;
    if (existing != null) {
      return existing;
    }
    final book = _book;
    if (book == null) {
      throw StateError('Cannot create lookup controller without a book');
    }
    final created = await LookupController.local(
      ownerUserId: book.ownerUserId,
      sourceLang: book.sourceLang,
      targetLang: book.targetLang,
    );
    _lookupController = created;
    return created;
  }

  Future<ParagraphTranslationController>
  ensureParagraphTranslationController() async {
    final existing = _paragraphTranslationController;
    if (existing != null) {
      return existing;
    }
    final book = _book;
    if (book == null) {
      throw StateError(
        'Cannot create paragraph translation controller without a book',
      );
    }
    final created = await ParagraphTranslationController.local(
      ownerUserId: book.ownerUserId,
      sourceLang: book.sourceLang,
      targetLang: book.targetLang,
    );
    _paragraphTranslationController = created;
    return created;
  }

  void _markNotFound() {
    _book = null;
    _chapters = const [];
    _currentChapterIndex = 0;
    _notFound = true;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(endReadingSession());
    super.dispose();
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
