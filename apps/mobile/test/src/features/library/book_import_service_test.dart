import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_file_storage_service.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_import_service.dart';
import 'package:study_for_read_mobile/src/features/library/data/epub_book_parser.dart';
import 'package:study_for_read_mobile/src/features/library/data/txt_book_parser.dart';

void main() {
  late Directory tempDir;
  late Directory privateRoot;
  late MobileDatabase mobileDatabase;
  late Database db;
  late BookImportService service;

  setUp(() async {
    sqfliteFfiInit();
    tempDir = await Directory.systemTemp.createTemp('study_for_read_import_');
    privateRoot = Directory('${tempDir.path}/private');
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    db = await mobileDatabase.open();
    service = BookImportService(
      database: db,
      storageService: BookFileStorageService(privateRootDirectory: privateRoot),
      txtParser: const TxtBookParser(),
      epubParser: const EpubBookParser(),
    );
  });

  tearDown(() async {
    await mobileDatabase.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('importing TXT stores book, chapters, and initial position', () async {
    final file = await _writeText(
      tempDir,
      'kokoro.txt',
      '第一章\nfirst paragraph\n\nsecond paragraph\n\n第二章\nnext chapter',
    );

    final imported = await service.importBook(
      ownerUserId: 'user-1',
      sourceFile: file,
    );

    final books = await db.query('local_books');
    final chapters = await db.query(
      'local_chapters',
      orderBy: 'chapter_index ASC',
    );
    final positions = await db.query('local_reading_positions');

    expect(imported.book.bookFingerprint, hasLength(64));
    expect(books, hasLength(1));
    expect(books.single['owner_user_id'], 'user-1');
    expect(books.single['file_type'], 'txt');
    expect(books.single['chapter_count'], 2);
    expect(chapters, hasLength(2));
    expect(chapters.first['title'], '第一章');
    expect(chapters.first['paragraph_count'], 2);
    expect(positions, hasLength(1));
    expect(positions.single['current_chapter_index'], 0);
    expect(positions.single['current_paragraph_index'], 0);
    expect(positions.single['current_char_offset'], 0);
  });

  test('importing EPUB uses the EPUB parser', () async {
    final file = await _writeEpub(tempDir, 'book.epub');

    await service.importBook(ownerUserId: 'user-1', sourceFile: file);

    final books = await db.query('local_books');
    final chapters = await db.query('local_chapters');
    expect(books.single['file_type'], 'epub');
    expect(books.single['title'], 'EPUB Title');
    expect(chapters.single['title'], 'EPUB Chapter');
  });

  test(
    'importing EPUB preserves image-only spine pages as image chapters',
    () async {
      final file = await _writeImageOnlyEpub(tempDir, 'image-book.epub');

      await service.importBook(ownerUserId: 'user-1', sourceFile: file);

      final chapters = await db.query(
        'local_chapters',
        orderBy: 'chapter_index ASC',
      );

      expect(chapters, hasLength(2));
      for (final chapter in chapters) {
        final content = chapter['content'] as String;
        expect(content, contains('![epub-image]('));
        expect(content, contains('file://'));
        final uri = Uri.parse(
          content.substring(content.indexOf('(') + 1, content.lastIndexOf(')')),
        );
        expect(await File.fromUri(uri).exists(), isTrue);
        expect(
          File.fromUri(uri).path.replaceAll('\\', '/'),
          startsWith(privateRoot.path.replaceAll('\\', '/')),
        );
      }
    },
  );

  test(
    're-importing same owner and fingerprint does not duplicate book',
    () async {
      final file = await _writeText(
        tempDir,
        'repeat.txt',
        'Chapter 1\nsame content',
      );

      await service.importBook(ownerUserId: 'user-1', sourceFile: file);
      await service.importBook(ownerUserId: 'user-1', sourceFile: file);

      expect(await db.query('local_books'), hasLength(1));
      expect(await db.query('local_chapters'), hasLength(1));
      expect(await db.query('local_reading_positions'), hasLength(1));
    },
  );

  test('pending metadata sync payload contains metadata only', () async {
    final file = await _writeText(
      tempDir,
      'metadata.txt',
      'Chapter 1\nprivate chapter content',
    );

    await service.importBook(ownerUserId: 'user-1', sourceFile: file);

    final events = await db.query('pending_sync_events');
    expect(events, hasLength(1));
    expect(events.single['event_type'], 'book_metadata');
    final payload =
        jsonDecode(events.single['payload_json'] as String)
            as Map<String, Object?>;

    expect(payload.keys, {
      'bookFingerprint',
      'title',
      'author',
      'fileType',
      'sourceLang',
      'targetLang',
      'chapterCount',
    });
    expect(payload['bookFingerprint'], hasLength(64));
    expect(payload['title'], 'metadata');
    expect(payload['fileType'], 'txt');
    expect(payload['sourceLang'], 'ja');
    expect(payload['targetLang'], 'zh-CN');
    expect(payload['chapterCount'], 1);

    final encodedPayload = jsonEncode(payload);
    expect(encodedPayload, isNot(contains('private chapter content')));
    expect(encodedPayload, isNot(contains(file.path)));
    expect(encodedPayload, isNot(contains('originalFile')));
    expect(encodedPayload, isNot(contains('filePath')));
    expect(encodedPayload, isNot(contains('bytes')));
    expect(encodedPayload, isNot(contains('content')));
  });

  test('parser failure does not insert partial rows', () async {
    final file = File('${tempDir.path}/invalid.txt');
    await file.writeAsBytes([0xC3, 0x28]);

    expect(
      () => service.importBook(ownerUserId: 'user-1', sourceFile: file),
      throwsA(isA<Exception>()),
    );

    expect(await db.query('local_books'), isEmpty);
    expect(await db.query('local_chapters'), isEmpty);
    expect(await db.query('local_reading_positions'), isEmpty);
    expect(await db.query('pending_sync_events'), isEmpty);
  });
}

Future<File> _writeText(Directory directory, String filename, String text) {
  final file = File('${directory.path}/$filename');
  return file.writeAsString(text, encoding: utf8);
}

Future<File> _writeEpub(Directory directory, String filename) async {
  final archive = Archive()
    ..addFile(_archiveFile('META-INF/container.xml', _containerXml()))
    ..addFile(_archiveFile('OEBPS/content.opf', _opf()))
    ..addFile(
      _archiveFile(
        'OEBPS/chapter.xhtml',
        _xhtml(title: 'EPUB Chapter', body: '<p>EPUB text.</p>'),
      ),
    );
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(ZipEncoder().encode(archive));
  return file;
}

Future<File> _writeImageOnlyEpub(Directory directory, String filename) async {
  final archive = Archive()
    ..addFile(_archiveFile('META-INF/container.xml', _containerXml()))
    ..addFile(
      _archiveFile(
        'OEBPS/content.opf',
        _opf(
          manifestItems: const [
            '<item id="titlepage" href="titlepage.xhtml" media-type="application/xhtml+xml" />',
            '<item id="image-page" href="text/part0000.html" media-type="application/xhtml+xml" />',
            '<item id="cover-image" href="images/cover.png" media-type="image/png" />',
          ],
          spineIds: const ['titlepage', 'image-page'],
        ),
      ),
    )
    ..addFile(
      _archiveFile(
        'OEBPS/titlepage.xhtml',
        _xhtmlBodyOnly(
          title: 'Cover',
          body:
              '<svg xmlns="http://www.w3.org/2000/svg" '
              'xmlns:xlink="http://www.w3.org/1999/xlink">'
              '<image xlink:href="images/cover.png" /></svg>',
        ),
      ),
    )
    ..addFile(
      _archiveFile(
        'OEBPS/text/part0000.html',
        _xhtmlBodyOnly(
          title: 'Image Page',
          body: '<p><img src="../images/cover.png" alt="page image" /></p>',
        ),
      ),
    )
    ..addFile(
      _binaryArchiveFile('OEBPS/images/cover.png', _transparentPngBytes()),
    );
  final file = File('${directory.path}/$filename');
  await file.writeAsBytes(ZipEncoder().encode(archive));
  return file;
}

ArchiveFile _archiveFile(String name, String content) {
  final bytes = utf8.encode(content);
  return ArchiveFile(name, bytes.length, bytes);
}

ArchiveFile _binaryArchiveFile(String name, List<int> bytes) {
  return ArchiveFile(name, bytes.length, bytes);
}

String _containerXml() {
  return '''
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" />
  </rootfiles>
</container>
''';
}

String _opf({
  List<String> manifestItems = const [
    '<item id="chapter" href="chapter.xhtml" media-type="application/xhtml+xml" />',
  ],
  List<String> spineIds = const ['chapter'],
}) {
  return '''
<package version="3.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>EPUB Title</dc:title>
    <dc:creator>EPUB Author</dc:creator>
  </metadata>
  <manifest>
    ${manifestItems.join('\n')}
  </manifest>
  <spine>
    ${spineIds.map((id) => '<itemref idref="$id" />').join('\n')}
  </spine>
</package>
''';
}

String _xhtml({required String title, required String body}) {
  return '''
<html xmlns="http://www.w3.org/1999/xhtml">
  <body>
    <h1>$title</h1>
    $body
  </body>
</html>
''';
}

String _xhtmlBodyOnly({required String title, required String body}) {
  return '''
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>$title</title>
  </head>
  <body>
    $body
  </body>
</html>
''';
}

List<int> _transparentPngBytes() {
  return const [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x60,
    0x00,
    0x00,
    0x00,
    0x02,
    0x00,
    0x01,
    0xE5,
    0x27,
    0xD4,
    0xA2,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];
}
