import 'package:path/path.dart' as p;

enum BookFileType {
  txt('txt'),
  epub('epub');

  const BookFileType(this.extension);

  final String extension;

  static BookFileType fromPath(String filePath) {
    final extension = p.extension(filePath).toLowerCase();
    return switch (extension) {
      '.txt' => BookFileType.txt,
      '.epub' => BookFileType.epub,
      _ => throw UnsupportedBookFileTypeException(filePath),
    };
  }
}

class UnsupportedBookFileTypeException implements Exception {
  const UnsupportedBookFileTypeException(this.filePath);

  final String filePath;

  @override
  String toString() => 'Unsupported book file type: $filePath';
}
