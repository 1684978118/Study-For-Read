import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'book_parse_result.dart';

class TxtBookParser {
  const TxtBookParser();

  Future<ParsedBook> parseFile(File file) async {
    final bytes = await file.readAsBytes();
    final text = _decodeUtf8(bytes);
    final normalized = _normalizeNewlines(_stripBom(text));

    if (normalized.trim().isEmpty) {
      throw const EmptyBookParseException();
    }

    final chapters = _splitChapters(normalized);
    return ParsedBook(
      title: _titleFromFile(file),
      author: null,
      fileType: 'txt',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      chapters: chapters,
    );
  }

  String _decodeUtf8(List<int> bytes) {
    try {
      return const Utf8Decoder(allowMalformed: false).convert(bytes);
    } on FormatException {
      throw const InvalidBookEncodingException();
    }
  }

  String _stripBom(String text) {
    if (text.startsWith('\ufeff')) {
      return text.substring(1);
    }
    return text;
  }

  String _normalizeNewlines(String text) {
    return text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  }

  List<ParsedChapter> _splitChapters(String text) {
    final lines = text.split('\n');
    final chapters = <_ChapterDraft>[];
    _ChapterDraft? current;
    final fallbackLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (_isHeading(trimmed)) {
        if (current != null) {
          chapters.add(current);
        }
        current = _ChapterDraft(title: trimmed, lines: <String>[]);
      } else if (current != null) {
        current.lines.add(line);
      } else {
        fallbackLines.add(line);
      }
    }

    if (current != null) {
      chapters.add(current);
    }

    if (chapters.isEmpty) {
      return [
        _buildChapter(
          chapterIndex: 0,
          title: 'Chapter 1',
          lines: fallbackLines,
        ),
      ];
    }

    return [
      for (var i = 0; i < chapters.length; i++)
        _buildChapter(
          chapterIndex: i,
          title: chapters[i].title,
          lines: chapters[i].lines,
        ),
    ];
  }

  bool _isHeading(String line) {
    if (line.isEmpty) {
      return false;
    }
    return line == '序章' ||
        RegExp(r'^第[一二三四五六七八九十百千万〇零]+章$').hasMatch(line) ||
        RegExp(r'^第\d+章$').hasMatch(line) ||
        RegExp(r'^Chapter\s+\d+$', caseSensitive: false).hasMatch(line);
  }

  ParsedChapter _buildChapter({
    required int chapterIndex,
    required String title,
    required List<String> lines,
  }) {
    final content = _normalizeContent(lines);
    final paragraphs = _splitParagraphs(content);

    return ParsedChapter(
      chapterIndex: chapterIndex,
      title: title,
      content: content,
      paragraphs: paragraphs,
    );
  }

  String _normalizeContent(List<String> lines) {
    return lines.join('\n').trim().replaceAll(RegExp(r'\n\s*\n+'), '\n\n');
  }

  List<String> _splitParagraphs(String content) {
    if (content.trim().isEmpty) {
      return const [];
    }
    return content
        .split(RegExp(r'\n\s*\n+'))
        .map((paragraph) => paragraph.trim())
        .where((paragraph) => paragraph.isNotEmpty)
        .toList(growable: false);
  }

  String _titleFromFile(File file) {
    final basename = p.basenameWithoutExtension(file.path).trim();
    return basename.isEmpty ? 'Untitled' : basename;
  }
}

class _ChapterDraft {
  _ChapterDraft({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;
}
