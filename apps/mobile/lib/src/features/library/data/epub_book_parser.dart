import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'book_parse_result.dart';

class EpubBookParser {
  const EpubBookParser();

  Future<ParsedBook> parseFile(File file) async {
    final archive = _decodeArchive(await file.readAsBytes());
    final opfPath = _findPackagePath(archive);
    final opfDocument = _parseXml(_readTextEntry(archive, opfPath));
    final manifest = _readManifest(opfDocument, opfPath);
    final spine = _readSpine(opfDocument);
    if (spine.isEmpty) {
      throw const EpubParseException('EPUB spine is empty');
    }

    final chapters = <ParsedChapter>[];
    for (final idref in spine) {
      final chapterPath = manifest[idref];
      if (chapterPath == null) {
        throw EpubParseException(
          'EPUB spine item missing from manifest: $idref',
        );
      }
      final xhtmlText = _readTextEntry(archive, chapterPath);
      final chapter = _parseChapter(
        xhtmlText: xhtmlText,
        chapterIndex: chapters.length,
        fallbackTitle: 'Chapter ${chapters.length + 1}',
      );
      chapters.add(chapter);
    }

    return ParsedBook(
      title: _metadataText(opfDocument, 'title') ?? _titleFromFile(file),
      author: _metadataText(opfDocument, 'creator'),
      fileType: 'epub',
      sourceLang: 'ja',
      targetLang: 'zh-CN',
      chapters: chapters,
    );
  }

  Archive _decodeArchive(List<int> bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } on Object {
      throw const EpubParseException('EPUB zip cannot be decoded');
    }
  }

  String _findPackagePath(Archive archive) {
    final container = _readTextEntry(archive, 'META-INF/container.xml');
    final document = _parseXml(container);
    final rootfile = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'rootfile')
        .firstOrNull;
    final fullPath = rootfile?.getAttribute('full-path')?.trim();
    if (fullPath == null || fullPath.isEmpty) {
      throw const EpubParseException('EPUB container has no package path');
    }
    return _normalizeZipPath(fullPath);
  }

  Map<String, String> _readManifest(XmlDocument document, String opfPath) {
    final opfDirectory = p.posix.dirname(opfPath);
    final items = document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'item',
    );
    final manifest = <String, String>{};

    for (final item in items) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      if (id == null || href == null || mediaType != 'application/xhtml+xml') {
        continue;
      }
      manifest[id] = _normalizeZipPath(p.posix.join(opfDirectory, href));
    }

    return manifest;
  }

  List<String> _readSpine(XmlDocument document) {
    return document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'itemref')
        .map((element) => element.getAttribute('idref')?.trim())
        .whereType<String>()
        .where((idref) => idref.isNotEmpty)
        .toList(growable: false);
  }

  ParsedChapter _parseChapter({
    required String xhtmlText,
    required int chapterIndex,
    required String fallbackTitle,
  }) {
    final document = _parseXml(xhtmlText);
    final body = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'body')
        .firstOrNull;
    if (body == null) {
      throw const EpubParseException('EPUB XHTML has no body');
    }

    final title = _chapterTitle(document) ?? fallbackTitle;
    final paragraphs = _visibleParagraphs(body);
    if (paragraphs.isEmpty) {
      throw const EpubParseException('EPUB XHTML has no readable text');
    }
    final content = paragraphs.join('\n\n');

    return ParsedChapter(
      chapterIndex: chapterIndex,
      title: title,
      content: content,
      paragraphs: paragraphs,
    );
  }

  List<String> _visibleParagraphs(XmlElement body) {
    final paragraphElements = body.descendants.whereType<XmlElement>().where(
      (element) => _isTextBlock(element.name.local),
    );

    final paragraphs = <String>[];
    for (final element in paragraphElements) {
      final text = _visibleText(element);
      if (text.isNotEmpty) {
        paragraphs.add(text);
      }
    }

    if (paragraphs.isNotEmpty) {
      return paragraphs;
    }

    final fallbackText = _visibleText(body);
    return fallbackText.isEmpty ? const [] : [fallbackText];
  }

  bool _isTextBlock(String localName) {
    return switch (localName.toLowerCase()) {
      'p' => true,
      _ => false,
    };
  }

  String _visibleText(XmlNode node) {
    if (node is XmlText) {
      return _collapseWhitespace(node.value);
    }
    if (node is XmlElement) {
      final name = node.name.local.toLowerCase();
      if (name == 'script' ||
          name == 'style' ||
          name == 'img' ||
          name == 'svg' ||
          name == 'rt') {
        return '';
      }
    }

    final pieces = <String>[];
    for (final child in node.children) {
      final text = _visibleText(child);
      if (text.isNotEmpty) {
        pieces.add(text);
      }
    }
    return _collapseWhitespace(pieces.join(' '));
  }

  String? _metadataText(XmlDocument document, String localName) {
    final value = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == localName)
        .map((element) => element.innerText.trim())
        .where((text) => text.isNotEmpty)
        .firstOrNull;
    return value;
  }

  String? _chapterTitle(XmlDocument document) {
    final bodyHeading = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local.toLowerCase() == 'h1')
        .map((element) => _visibleText(element))
        .where((text) => text.isNotEmpty)
        .firstOrNull;
    if (bodyHeading != null) {
      return bodyHeading;
    }

    return document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'title')
        .map((element) => element.innerText.trim())
        .where((text) => text.isNotEmpty)
        .firstOrNull;
  }

  XmlDocument _parseXml(String text) {
    try {
      return XmlDocument.parse(text);
    } on Object {
      throw const EpubParseException('EPUB XML cannot be parsed');
    }
  }

  String _readTextEntry(Archive archive, String path) {
    final normalizedPath = _normalizeZipPath(path);
    final file = archive.files
        .where((entry) => !entry.isFile ? false : entry.name == normalizedPath)
        .firstOrNull;
    if (file == null) {
      throw EpubParseException('EPUB entry missing: $normalizedPath');
    }

    try {
      return utf8.decode(file.content as List<int>, allowMalformed: false);
    } on Object {
      throw EpubParseException(
        'EPUB entry is not readable UTF-8: $normalizedPath',
      );
    }
  }

  String _normalizeZipPath(String value) {
    return p.posix.normalize(value.replaceAll('\\', '/'));
  }

  String _collapseWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _titleFromFile(File file) {
    final basename = p.basenameWithoutExtension(file.path).trim();
    return basename.isEmpty ? 'Untitled' : basename;
  }
}
