import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'book_parse_result.dart';

class EpubBookParser {
  const EpubBookParser();

  Future<ParsedBook> parseFile(
    File file, {
    Directory? imageOutputDirectory,
  }) async {
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
      final chapterItem = manifest[idref];
      if (chapterItem == null ||
          chapterItem.mediaType != 'application/xhtml+xml') {
        throw EpubParseException(
          'EPUB spine item missing from manifest: $idref',
        );
      }
      final xhtmlText = _readTextEntry(archive, chapterItem.path);
      final chapter = await _parseChapter(
        archive: archive,
        manifest: manifest.values.toList(growable: false),
        chapterPath: chapterItem.path,
        xhtmlText: xhtmlText,
        chapterIndex: chapters.length,
        fallbackTitle: 'Chapter ${chapters.length + 1}',
        imageOutputDirectory: imageOutputDirectory,
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

  Map<String, _ManifestItem> _readManifest(
    XmlDocument document,
    String opfPath,
  ) {
    final opfDirectory = p.posix.dirname(opfPath);
    final items = document.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == 'item',
    );
    final manifest = <String, _ManifestItem>{};

    for (final item in items) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      final mediaType = item.getAttribute('media-type');
      if (id == null || href == null || mediaType == null) {
        continue;
      }
      manifest[id] = _ManifestItem(
        path: _normalizeZipPath(p.posix.join(opfDirectory, href)),
        mediaType: mediaType,
      );
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

  Future<ParsedChapter> _parseChapter({
    required Archive archive,
    required List<_ManifestItem> manifest,
    required String chapterPath,
    required String xhtmlText,
    required int chapterIndex,
    required String fallbackTitle,
    required Directory? imageOutputDirectory,
  }) async {
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
      final imageMarker = await _imagePageMarker(
        archive: archive,
        manifest: manifest,
        chapterPath: chapterPath,
        body: body,
        chapterIndex: chapterIndex,
        imageOutputDirectory: imageOutputDirectory,
      );
      if (imageMarker == null) {
        throw const EpubParseException('EPUB XHTML has no readable text');
      }
      return ParsedChapter(
        chapterIndex: chapterIndex,
        title: title,
        content: imageMarker,
        paragraphs: [imageMarker],
      );
    }
    final content = paragraphs.join('\n\n');

    return ParsedChapter(
      chapterIndex: chapterIndex,
      title: title,
      content: content,
      paragraphs: paragraphs,
    );
  }

  Future<String?> _imagePageMarker({
    required Archive archive,
    required List<_ManifestItem> manifest,
    required String chapterPath,
    required XmlElement body,
    required int chapterIndex,
    required Directory? imageOutputDirectory,
  }) async {
    if (imageOutputDirectory == null) {
      return null;
    }

    final imagePath = _firstLocalImagePath(body, chapterPath);
    if (imagePath == null ||
        !manifest.any(
          (item) =>
              item.path == imagePath && item.mediaType.startsWith('image/'),
        )) {
      return null;
    }

    final entry = archive.files
        .where((file) => file.isFile && file.name == imagePath)
        .firstOrNull;
    if (entry == null) {
      return null;
    }

    if (!await imageOutputDirectory.exists()) {
      await imageOutputDirectory.create(recursive: true);
    }

    final extension = p.extension(imagePath);
    final outputFile = File(
      p.join(
        imageOutputDirectory.path,
        'chapter_$chapterIndex${extension.isEmpty ? '.img' : extension}',
      ),
    );
    await outputFile.writeAsBytes(List<int>.from(entry.content as List<int>));
    return '![epub-image](${Uri.file(outputFile.path)})';
  }

  String? _firstLocalImagePath(XmlElement body, String chapterPath) {
    final imageElement = body.descendants.whereType<XmlElement>().where((
      element,
    ) {
      final name = element.name.local.toLowerCase();
      return name == 'img' || name == 'image';
    }).firstOrNull;
    if (imageElement == null) {
      return null;
    }

    final reference = _imageReference(imageElement);
    if (reference == null || !_isLocalReference(reference)) {
      return null;
    }

    final cleanReference = reference.split('#').first.split('?').first;
    if (cleanReference.trim().isEmpty) {
      return null;
    }

    return _normalizeZipPath(
      p.posix.join(p.posix.dirname(chapterPath), cleanReference),
    );
  }

  String? _imageReference(XmlElement element) {
    final direct = element.getAttribute('src') ?? element.getAttribute('href');
    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    for (final attribute in element.attributes) {
      if (attribute.name.local == 'href') {
        final value = attribute.value.trim();
        if (value.isNotEmpty) {
          return value;
        }
      }
    }
    return null;
  }

  bool _isLocalReference(String value) {
    final trimmed = value.trim().toLowerCase();
    return trimmed.isNotEmpty &&
        !trimmed.startsWith('data:') &&
        !trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('//');
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

class _ManifestItem {
  const _ManifestItem({required this.path, required this.mediaType});

  final String path;
  final String mediaType;
}
