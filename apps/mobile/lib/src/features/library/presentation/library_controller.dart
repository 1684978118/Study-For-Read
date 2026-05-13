import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/database/mobile_database.dart';
import '../../auth/data/auth_token_store.dart';
import '../data/book_file_picker.dart';
import '../data/book_file_storage_service.dart';
import '../data/book_import_service.dart';
import '../data/epub_book_parser.dart';
import '../data/local_book_repository.dart';
import '../data/txt_book_parser.dart';
import '../domain/local_book.dart';

class LibraryController extends ChangeNotifier {
  LibraryController({
    required String ownerUserId,
    required LocalBookRepository bookRepository,
    required BookFilePicker filePicker,
    required BookImporter importService,
  })  : _ownerUserId = ownerUserId,
        _bookRepository = bookRepository,
        _filePicker = filePicker,
        _importService = importService;

  final String _ownerUserId;
  final LocalBookRepository _bookRepository;
  final BookFilePicker _filePicker;
  final BookImporter _importService;

  bool _isLoading = false;
  bool _isImporting = false;
  bool _hasLoaded = false;
  String? _errorMessage;
  List<LocalBook> _books = const [];

  bool get isLoading => _isLoading;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;
  List<LocalBook> get books => _books;

  static Future<LibraryController> local() async {
    final ownerUserId = await _readCurrentUserId(SecureAuthTokenStore());
    final database = await MobileDatabase().open();
    return LibraryController(
      ownerUserId: ownerUserId,
      bookRepository: LocalBookRepository(database),
      filePicker: const PlatformBookFilePicker(),
      importService: BookImportService(
        database: database,
        storageService: BookFileStorageService(),
        txtParser: const TxtBookParser(),
        epubParser: const EpubBookParser(),
      ),
    );
  }

  static Future<String> _readCurrentUserId(AuthTokenStore tokenStore) async {
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Missing access token');
    }

    final parts = accessToken.split('.');
    if (parts.length != 3 || parts[0] != 'access') {
      throw StateError('Invalid access token');
    }

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final payloadParts = payload.split(':');
    if (payloadParts.length != 3 || payloadParts.first.isEmpty) {
      throw StateError('Invalid access token payload');
    }

    return payloadParts.first;
  }

  Future<void> load() async {
    if (_hasLoaded && _isLoading) {
      return;
    }
    _hasLoaded = true;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _books = await _bookRepository.findByOwnerUserId(_ownerUserId);
    } catch (_) {
      _errorMessage = '无法加载本地书籍。';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importBook() async {
    _isImporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final file = await _filePicker.pickBookFile();
      if (file == null) {
        return;
      }
      await _importService.importBook(
        ownerUserId: _ownerUserId,
        sourceFile: file,
      );
      _books = await _bookRepository.findByOwnerUserId(_ownerUserId);
    } catch (_) {
      _errorMessage = '导入失败，请换一个 TXT 或 EPUB 文件重试。';
    } finally {
      _isImporting = false;
      notifyListeners();
    }
  }
}
