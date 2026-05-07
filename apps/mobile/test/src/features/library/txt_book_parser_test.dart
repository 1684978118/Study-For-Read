import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_parse_result.dart';
import 'package:study_for_read_mobile/src/features/library/data/txt_book_parser.dart';

void main() {
  late Directory tempDir;
  late TxtBookParser parser;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('study_for_read_txt_');
    parser = const TxtBookParser();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('UTF-8 TXT without BOM parses successfully', () async {
    final file = await _writeText(
      tempDir,
      'kokoro.txt',
      '第一章\n先生と私\n\n次の段落',
    );

    final book = await parser.parseFile(file);

    expect(book.title, 'kokoro');
    expect(book.fileType, 'txt');
    expect(book.sourceLang, 'ja');
    expect(book.targetLang, 'zh-CN');
    expect(book.chapters, hasLength(1));
    expect(book.chapters.single.chapterIndex, 0);
    expect(book.chapters.single.title, '第一章');
    expect(book.chapters.single.paragraphs, ['先生と私', '次の段落']);
  });

  test('UTF-8 TXT with BOM removes BOM from first chapter text', () async {
    final file = File('${tempDir.path}/bom.txt');
    await file.writeAsBytes([0xEF, 0xBB, 0xBF, ...utf8.encode('序章\n本文')]);

    final book = await parser.parseFile(file);

    expect(book.chapters.single.title, '序章');
    expect(book.chapters.single.content, isNot(startsWith('\ufeff')));
    expect(book.chapters.single.paragraphs.single, '本文');
  });

  test('common chapter headings split chapters', () async {
    final file = await _writeText(
      tempDir,
      'headings.txt',
      [
        '序章',
        'はじめに',
        '',
        '第一章',
        '漢数字の章',
        '',
        '第1章',
        '数字の章',
        '',
        'Chapter 1',
        'English chapter',
      ].join('\r\n'),
    );

    final book = await parser.parseFile(file);

    expect(book.chapters.map((chapter) => chapter.title), [
      '序章',
      '第一章',
      '第1章',
      'Chapter 1',
    ]);
    expect(book.chapters.map((chapter) => chapter.chapterIndex), [0, 1, 2, 3]);
    expect(book.chapters[0].paragraphs, ['はじめに']);
    expect(book.chapters[3].paragraphs, ['English chapter']);
  });

  test('TXT without headings becomes one fallback chapter', () async {
    final file = await _writeText(
      tempDir,
      'plain.txt',
      'first paragraph\n\nsecond paragraph',
    );

    final book = await parser.parseFile(file);

    expect(book.chapters, hasLength(1));
    expect(book.chapters.single.title, 'Chapter 1');
    expect(book.chapters.single.paragraphs, [
      'first paragraph',
      'second paragraph',
    ]);
  });

  test('blank-line groups become paragraphs and CRLF becomes LF', () async {
    final file = await _writeText(
      tempDir,
      'paragraphs.txt',
      '第一章\r\nline one\r\nline two\r\n\r\n\r\nline three',
    );

    final book = await parser.parseFile(file);

    expect(book.chapters.single.paragraphs, ['line one\nline two', 'line three']);
    expect(book.chapters.single.content, 'line one\nline two\n\nline three');
  });

  test('empty or whitespace-only TXT returns typed import failure', () async {
    final file = await _writeText(tempDir, 'empty.txt', ' \r\n\t\n ');

    expect(
      () => parser.parseFile(file),
      throwsA(isA<EmptyBookParseException>()),
    );
  });

  test('invalid UTF-8 bytes return typed import failure', () async {
    final file = File('${tempDir.path}/invalid.txt');
    await file.writeAsBytes([0xC3, 0x28]);

    expect(
      () => parser.parseFile(file),
      throwsA(isA<InvalidBookEncodingException>()),
    );
  });
}

Future<File> _writeText(Directory directory, String filename, String text) async {
  final file = File('${directory.path}/$filename');
  return file.writeAsString(text, encoding: utf8);
}
