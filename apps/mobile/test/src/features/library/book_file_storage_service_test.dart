import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_file_storage_service.dart';
import 'package:study_for_read_mobile/src/features/library/domain/book_file_type.dart';

void main() {
  late Directory tempDir;
  late Directory privateRoot;
  late BookFileStorageService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('study_for_read_storage_');
    privateRoot = Directory('${tempDir.path}/app_private');
    service = BookFileStorageService(privateRootDirectory: privateRoot);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('.txt maps to BookFileType.txt', () {
    expect(BookFileType.fromPath('kokoro.txt'), BookFileType.txt);
    expect(BookFileType.fromPath('KOKORO.TXT'), BookFileType.txt);
  });

  test('.epub maps to BookFileType.epub', () {
    expect(BookFileType.fromPath('book.epub'), BookFileType.epub);
    expect(BookFileType.fromPath('BOOK.EPUB'), BookFileType.epub);
  });

  test('unsupported extension returns typed import failure', () {
    expect(
      () => BookFileType.fromPath('book.pdf'),
      throwsA(isA<UnsupportedBookFileTypeException>()),
    );
  });

  test('copies file into app-private books directory', () async {
    final source = File('${tempDir.path}/kokoro.txt');
    await source.writeAsString('hello');

    final stored = await service.store(source);

    expect(stored.originalFilename, 'kokoro.txt');
    expect(stored.fileType, BookFileType.txt);
    expect(
      stored.fingerprint,
      '2cf24dba5fb0a30e26e83b2ac5b9e29e'
      '1b161e5c1fa7425e73043362938b9824',
    );
    expect(stored.localPath, startsWith('${privateRoot.path}${Platform.pathSeparator}books'));
    expect(await File(stored.localPath).exists(), isTrue);
    expect(await File(stored.localPath).readAsString(), 'hello');
  });

  test('stored model contains metadata only, not file bytes or content', () async {
    final source = File('${tempDir.path}/book.epub');
    await source.writeAsBytes([80, 75, 3, 4]);

    final stored = await service.store(source);

    expect(stored.toMap().keys, containsAll([
      'localPath',
      'originalFilename',
      'fileType',
      'fingerprint',
    ]));
    expect(stored.toMap().keys, isNot(contains('bytes')));
    expect(stored.toMap().keys, isNot(contains('content')));
    expect(stored.toMap().keys, isNot(contains('chapterText')));
    expect(stored.toMap().keys, isNot(contains('chapterContent')));
  });
}
