import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/book_file_type.dart';
import 'book_fingerprint_service.dart';
import 'stored_book_file.dart';

class BookFileStorageService {
  BookFileStorageService({
    Directory? privateRootDirectory,
    BookFingerprintService fingerprintService = const BookFingerprintService(),
  }) : _privateRootDirectory = privateRootDirectory,
       _fingerprintService = fingerprintService;

  final Directory? _privateRootDirectory;
  final BookFingerprintService _fingerprintService;

  Future<StoredBookFile> store(File sourceFile) async {
    final fileType = BookFileType.fromPath(sourceFile.path);
    final fingerprint = await _fingerprintService.fingerprint(sourceFile);
    final rootDirectory =
        _privateRootDirectory ?? await getApplicationDocumentsDirectory();
    final booksDirectory = Directory(p.join(rootDirectory.path, 'books'));
    if (!await booksDirectory.exists()) {
      await booksDirectory.create(recursive: true);
    }

    final originalFilename = p.basename(sourceFile.path);
    final storedFilename = '$fingerprint.${fileType.extension}';
    final destination = File(p.join(booksDirectory.path, storedFilename));
    await sourceFile.copy(destination.path);

    return StoredBookFile(
      localPath: destination.path,
      originalFilename: originalFilename,
      fileType: fileType,
      fingerprint: fingerprint,
    );
  }
}
