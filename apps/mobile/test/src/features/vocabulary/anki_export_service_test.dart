import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_options.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/export/anki_export_service.dart';

void main() {
  test('exports UTF-8 Anki text with headers and tab-separated rows', () {
    const service = AnkiExportService();
    const cards = [
      AnkiExportCard(
        id: 'card-1',
        front: '長い',
        reading: 'ながい',
        meaning: 'long',
        example: '長い道',
        source: 'Kokoro',
        tags: ['ja', 'adjective'],
        audioFilename: 'nagai.mp3',
      ),
    ];

    final content = service.exportText(
      cards: cards,
      options: const AnkiExportOptions(
        scope: AnkiExportScope.allCards,
        includeExamples: true,
        includeSourceMetadata: true,
        deckName: 'StudyForRead::Japanese',
        noteType: 'StudyForRead Japanese',
      ),
    );

    expect(utf8.decode(utf8.encode(content)), content);
    expect(content, startsWith('#separator:Tab\n#html:true\n'));
    expect(content, contains('#deck:StudyForRead::Japanese\n'));
    expect(content, contains('#notetype:StudyForRead Japanese\n'));
    expect(
      content,
      contains('#columns:id\tfront\treading\tmeaning\texample\tsource\ttags\taudio\n'),
    );

    final rows = content.trimRight().split('\n');
    expect(rows.last, 'card-1\t長い\tながい\tlong\t長い道\tKokoro\tja adjective\t[sound:nagai.mp3]');
    expect(rows.last.split('\t').first, 'card-1');
  });

  test('can omit examples and source metadata', () {
    const service = AnkiExportService();

    final content = service.exportText(
      cards: const [
        AnkiExportCard(
          id: 'card-2',
          front: '私の文',
          meaning: 'my sentence',
          example: 'should be omitted',
          source: 'should be omitted',
        ),
      ],
      options: const AnkiExportOptions(
        scope: AnkiExportScope.privateSentenceCards,
        includeExamples: false,
        includeSourceMetadata: false,
      ),
    );

    expect(content, contains('#columns:id\tfront\treading\tmeaning\ttags\taudio\n'));
    final dataRow = content
        .split('\n')
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .single;
    expect(dataRow, 'card-2\t私の文\t\tmy sentence\t\t');
    expect(content, isNot(contains('should be omitted')));
  });

  test('cleans tabs, newlines, and forbidden source content fields', () {
    const service = AnkiExportService();

    final content = service.exportText(
      cards: const [
        AnkiExportCard(
          id: 'card-3',
          front: 'front\twith\ttabs',
          reading: 'line\nbreak',
          meaning: 'meaning\r\nbreak',
          example: 'example\tone',
          source: 'D:/private/original-file.txt',
        ),
      ],
      options: const AnkiExportOptions(
        scope: AnkiExportScope.allCards,
        includeExamples: true,
        includeSourceMetadata: true,
      ),
    );

    final dataRows = content
        .split('\n')
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toList();

    expect(dataRows, hasLength(1));
    expect(dataRows.single.split('\t'), hasLength(8));
    expect(dataRows.single, contains('front with tabs'));
    expect(dataRows.single, contains('line break'));
    expect(dataRows.single, contains('meaning break'));
    expect(dataRows.single, contains('example one'));
    expect(dataRows.single, isNot(contains('D:/private')));
    expect(dataRows.single, isNot(contains('original-file.txt')));
  });
}
