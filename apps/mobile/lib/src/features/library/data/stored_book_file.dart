import '../domain/book_file_type.dart';

class StoredBookFile {
  const StoredBookFile({
    required this.localPath,
    required this.originalFilename,
    required this.fileType,
    required this.fingerprint,
  });

  final String localPath;
  final String originalFilename;
  final BookFileType fileType;
  final String fingerprint;

  Map<String, Object?> toMap() {
    return {
      'localPath': localPath,
      'originalFilename': originalFilename,
      'fileType': fileType.extension,
      'fingerprint': fingerprint,
    };
  }
}
