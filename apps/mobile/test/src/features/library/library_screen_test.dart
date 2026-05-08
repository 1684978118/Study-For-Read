import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_file_picker.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_import_service.dart';
import 'package:study_for_read_mobile/src/features/library/data/local_book_repository.dart';
import 'package:study_for_read_mobile/src/features/library/data/stored_book_file.dart';
import 'package:study_for_read_mobile/src/features/library/domain/book_file_type.dart';
import 'package:study_for_read_mobile/src/features/library/domain/local_book.dart';
import 'package:study_for_read_mobile/src/features/library/presentation/library_controller.dart';
import 'package:study_for_read_mobile/src/features/library/presentation/library_screen.dart';

void main() {
  testWidgets('empty Library shows import action and local-device copy', (
    tester,
  ) async {
    final controller = _controller(books: []);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('No local books yet'), findsOneWidget);
    expect(find.text('Import TXT or EPUB'), findsOneWidget);
    expect(
      find.text('Books stay on this device and remain available offline.'),
      findsOneWidget,
    );
  });

  testWidgets('shows loading state while local books load', (tester) async {
    final pendingBooks = Completer<List<LocalBook>>();
    final controller = _controller(loadBooks: (_) => pendingBooks.future);

    await tester.pumpWidget(_app(controller));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pendingBooks.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('import uses picker and import service then refreshes list', (
    tester,
  ) async {
    final sourceFile = File('D:/fixture/kokoro.txt');
    final picker = _FakeBookFilePicker(sourceFile);
    final importer = _FakeBookImporter(_book(title: 'Kokoro', fileType: 'txt'));
    final repository = _FakeLocalBookRepository(
      initialBooks: [],
      refreshedBooks: [_book(title: 'Kokoro', fileType: 'txt')],
    );
    final controller = LibraryController(
      ownerUserId: 'user-1',
      bookRepository: repository,
      filePicker: picker,
      importService: importer,
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import TXT or EPUB'));
    await tester.pumpAndSettle();

    expect(picker.pickCount, 1);
    expect(importer.importedFile, sourceFile);
    expect(importer.ownerUserId, 'user-1');
    expect(find.text('Kokoro'), findsOneWidget);
  });

  testWidgets('import failure shows inline error', (tester) async {
    final controller = LibraryController(
      ownerUserId: 'user-1',
      bookRepository: _FakeLocalBookRepository(initialBooks: []),
      filePicker: _FakeBookFilePicker(File('D:/fixture/broken.epub')),
      importService: _FakeBookImporter.failure(Exception('Import failed')),
    );

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import TXT or EPUB'));
    await tester.pumpAndSettle();

    expect(find.text('Import failed. Please try another TXT or EPUB file.'), findsOneWidget);
  });

  testWidgets('book list shows metadata and hides original path', (
    tester,
  ) async {
    final book = _book(
      title: '雪国',
      author: '川端康成',
      fileType: 'epub',
      syncStatus: 'dirty',
      originalFilePath: 'D:/private/books/secret.epub',
    );
    final controller = _controller(books: [book]);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();

    expect(find.text('雪国'), findsOneWidget);
    expect(find.text('川端康成'), findsOneWidget);
    expect(find.text('EPUB'), findsOneWidget);
    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.textContaining('D:/private/books'), findsNothing);
    expect(find.textContaining('secret.epub'), findsNothing);
  });

  testWidgets('tapping a book opens Reader with only the local book id', (
    tester,
  ) async {
    final controller = _controller(books: [_book(id: 'local-book-1')]);

    await tester.pumpWidget(_app(controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sample Book'));
    await tester.pumpAndSettle();

    expect(find.text('Reader local-book-1'), findsOneWidget);
    expect(find.textContaining('fingerprint'), findsNothing);
    expect(find.textContaining('path'), findsNothing);
  });
}

Widget _app(LibraryController controller) {
  final router = GoRouter(
    initialLocation: '/library',
    routes: [
      GoRoute(
        path: '/library',
        builder: (context, state) => LibraryScreen(controller: controller),
      ),
      GoRoute(
        path: '/reader/:bookId',
        builder: (context, state) =>
            Text('Reader ${state.pathParameters['bookId']}'),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: router);
}

LibraryController _controller({
  List<LocalBook>? books,
  Future<List<LocalBook>> Function(String ownerUserId)? loadBooks,
}) {
  return LibraryController(
    ownerUserId: 'user-1',
    bookRepository: _FakeLocalBookRepository(
      initialBooks: books ?? [],
      loadBooks: loadBooks,
    ),
    filePicker: _FakeBookFilePicker(null),
    importService: _FakeBookImporter(_book()),
  );
}

LocalBook _book({
  String id = 'book-1',
  String title = 'Sample Book',
  String? author,
  String fileType = 'txt',
  String syncStatus = 'local_only',
  String originalFilePath = 'D:/private/books/sample.txt',
}) {
  final now = DateTime.utc(2026, 1, 2);
  return LocalBook(
    id: id,
    ownerUserId: 'user-1',
    bookFingerprint: 'fingerprint-$id',
    title: title,
    author: author,
    fileType: fileType,
    sourceLang: 'ja',
    targetLang: 'zh-CN',
    originalFilePath: originalFilePath,
    chapterCount: 1,
    metadataSyncStatus: syncStatus,
    lastOpenedAt: null,
    lastSyncedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

class _FakeLocalBookRepository implements LocalBookRepository {
  _FakeLocalBookRepository({
    required List<LocalBook> initialBooks,
    List<LocalBook>? refreshedBooks,
    Future<List<LocalBook>> Function(String ownerUserId)? loadBooks,
  })  : _books = initialBooks,
        _refreshedBooks = refreshedBooks,
        _loadBooks = loadBooks;

  List<LocalBook> _books;
  final List<LocalBook>? _refreshedBooks;
  final Future<List<LocalBook>> Function(String ownerUserId)? _loadBooks;
  int _loadCount = 0;

  @override
  Future<List<LocalBook>> findByOwnerUserId(String ownerUserId) async {
    _loadCount += 1;
    final loadBooks = _loadBooks;
    if (loadBooks != null) {
      return loadBooks(ownerUserId);
    }
    if (_loadCount > 1 && _refreshedBooks != null) {
      _books = _refreshedBooks;
    }
    return _books;
  }

  @override
  Future<LocalBook?> findByOwnerUserIdAndBookFingerprint({
    required String ownerUserId,
    required String bookFingerprint,
  }) async {
    return null;
  }

  @override
  Future<int> insert(LocalBook book) async => 1;

  @override
  Future<int> update(LocalBook book) async => 1;
}

class _FakeBookFilePicker implements BookFilePicker {
  _FakeBookFilePicker(this.file);

  final File? file;
  int pickCount = 0;

  @override
  Future<File?> pickBookFile() async {
    pickCount += 1;
    return file;
  }
}

class _FakeBookImporter implements BookImporter {
  _FakeBookImporter(LocalBook book)
      : _book = book,
        _error = null;

  _FakeBookImporter.failure(Object error)
      : _book = null,
        _error = error;

  final LocalBook? _book;
  final Object? _error;
  String? ownerUserId;
  File? importedFile;

  @override
  Future<BookImportResult> importBook({
    required String ownerUserId,
    required File sourceFile,
  }) async {
    this.ownerUserId = ownerUserId;
    importedFile = sourceFile;
    final error = _error;
    if (error != null) {
      throw error;
    }
    return BookImportResult(
      book: _book!,
      storedFile: StoredBookFile(
        localPath: 'D:/private/books/stored.${_book.fileType}',
        originalFilename: 'source.${_book.fileType}',
        fileType: BookFileType.fromPath('source.${_book.fileType}'),
        fingerprint: _book.bookFingerprint,
      ),
    );
  }
}
