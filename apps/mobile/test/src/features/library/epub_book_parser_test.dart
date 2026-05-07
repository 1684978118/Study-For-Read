import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_parse_result.dart';
import 'package:study_for_read_mobile/src/features/library/data/epub_book_parser.dart';

void main() {
  late Directory tempDir;
  late EpubBookParser parser;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('study_for_read_epub_');
    parser = const EpubBookParser();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('minimal EPUB parses metadata and spine-ordered chapters', () async {
    final file = await _writeEpub(tempDir, {
      'META-INF/container.xml': _containerXml('OEBPS/content.opf'),
      'OEBPS/content.opf': _opf(
        title: 'Kokoro',
        author: 'Natsume Soseki',
        manifestItems: [
          _manifestItem(id: 'chap2', href: 'chapters/chapter2.xhtml'),
          _manifestItem(id: 'style', href: 'style.css', mediaType: 'text/css'),
          _manifestItem(id: 'chap1', href: 'chapters/chapter1.xhtml'),
          _manifestItem(
            id: 'cover',
            href: 'cover.jpg',
            mediaType: 'image/jpeg',
          ),
        ],
        spineIds: ['chap1', 'chap2'],
      ),
      'OEBPS/chapters/chapter2.xhtml': _xhtml(
        title: 'Chapter Two',
        body: '<p>Second chapter first.</p><p>Second chapter second.</p>',
      ),
      'OEBPS/style.css': 'body { color: red; }',
      'OEBPS/chapters/chapter1.xhtml': _xhtml(
        title: 'Chapter One',
        body:
            '<p>First <ruby>visible<rt>ignored</rt></ruby> paragraph.</p>'
            '<script>hidden()</script>'
            '<img src="remote.jpg" alt="ignored" />'
            '<p>Another line.</p>',
      ),
      'OEBPS/cover.jpg': 'not really an image',
    });

    final book = await parser.parseFile(file);

    expect(book.title, 'Kokoro');
    expect(book.author, 'Natsume Soseki');
    expect(book.fileType, 'epub');
    expect(book.sourceLang, 'ja');
    expect(book.targetLang, 'zh-CN');
    expect(book.chapters.map((chapter) => chapter.title), [
      'Chapter One',
      'Chapter Two',
    ]);
    expect(book.chapters.map((chapter) => chapter.chapterIndex), [0, 1]);
    expect(book.chapters.first.paragraphs, [
      'First visible paragraph.',
      'Another line.',
    ]);
    expect(book.chapters.first.content, isNot(contains('<p>')));
    expect(book.chapters.first.content, isNot(contains('hidden')));
    expect(book.chapters.first.content, isNot(contains('remote.jpg')));
  });

  test('missing container file returns typed import failure', () async {
    final file = await _writeEpub(tempDir, {
      'OEBPS/content.opf': _opf(
        title: 'Kokoro',
        author: 'Natsume Soseki',
        manifestItems: [_manifestItem(id: 'chap1', href: 'chapter1.xhtml')],
        spineIds: ['chap1'],
      ),
      'OEBPS/chapter1.xhtml': _xhtml(title: 'Chapter One', body: '<p>Text</p>'),
    });

    expect(() => parser.parseFile(file), throwsA(isA<EpubParseException>()));
  });

  test('empty spine returns typed import failure', () async {
    final file = await _writeEpub(tempDir, {
      'META-INF/container.xml': _containerXml('OEBPS/content.opf'),
      'OEBPS/content.opf': _opf(
        title: 'Kokoro',
        author: 'Natsume Soseki',
        manifestItems: [_manifestItem(id: 'chap1', href: 'chapter1.xhtml')],
        spineIds: const [],
      ),
      'OEBPS/chapter1.xhtml': _xhtml(title: 'Chapter One', body: '<p>Text</p>'),
    });

    expect(() => parser.parseFile(file), throwsA(isA<EpubParseException>()));
  });

  test('unreadable XHTML returns typed import failure', () async {
    final file = await _writeEpub(tempDir, {
      'META-INF/container.xml': _containerXml('OEBPS/content.opf'),
      'OEBPS/content.opf': _opf(
        title: 'Kokoro',
        author: 'Natsume Soseki',
        manifestItems: [_manifestItem(id: 'chap1', href: 'missing.xhtml')],
        spineIds: ['chap1'],
      ),
    });

    expect(() => parser.parseFile(file), throwsA(isA<EpubParseException>()));
  });
}

Future<File> _writeEpub(
  Directory directory,
  Map<String, String> entries,
) async {
  final archive = Archive();
  for (final entry in entries.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  final file = File('${directory.path}/book.epub');
  await file.writeAsBytes(ZipEncoder().encode(archive));
  return file;
}

String _containerXml(String opfPath) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="$opfPath" media-type="application/oebps-package+xml" />
  </rootfiles>
</container>
''';
}

String _opf({
  required String title,
  required String author,
  required List<String> manifestItems,
  required List<String> spineIds,
}) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<package version="3.0" xmlns="http://www.idpf.org/2007/opf" unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$title</dc:title>
    <dc:creator>$author</dc:creator>
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

String _manifestItem({
  required String id,
  required String href,
  String mediaType = 'application/xhtml+xml',
}) {
  return '<item id="$id" href="$href" media-type="$mediaType" />';
}

String _xhtml({required String title, required String body}) {
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>$title</title>
  </head>
  <body>
    <h1>$title</h1>
    $body
  </body>
</html>
''';
}
