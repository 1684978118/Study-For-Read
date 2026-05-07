import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/library/data/book_fingerprint_service.dart';

void main() {
  late Directory tempDir;
  late BookFingerprintService service;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'study_for_read_fingerprint_',
    );
    service = const BookFingerprintService();
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns stable lowercase SHA-256 hex for known bytes', () async {
    final file = File('${tempDir.path}/known.txt');
    await file.writeAsString('hello');

    final fingerprint = await service.fingerprint(file);

    expect(
      fingerprint,
      '2cf24dba5fb0a30e26e83b2ac5b9e29e'
      '1b161e5c1fa7425e73043362938b9824',
    );
    expect(fingerprint, hasLength(64));
    expect(fingerprint, fingerprint.toLowerCase());
  });

  test('same bytes always produce the same fingerprint', () async {
    final first = File('${tempDir.path}/first.txt');
    final second = File('${tempDir.path}/second.epub');
    await first.writeAsBytes([0, 1, 2, 3, 4, 255]);
    await second.writeAsBytes([0, 1, 2, 3, 4, 255]);

    expect(await service.fingerprint(first), await service.fingerprint(second));
  });
}
