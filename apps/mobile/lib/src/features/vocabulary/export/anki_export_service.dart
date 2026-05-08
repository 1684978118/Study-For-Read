import 'anki_export_options.dart';

class AnkiExportCard {
  const AnkiExportCard({
    required this.id,
    required this.front,
    this.reading,
    required this.meaning,
    this.example,
    this.source,
    this.tags = const [],
    this.audioFilename,
  });

  final String id;
  final String front;
  final String? reading;
  final String meaning;
  final String? example;
  final String? source;
  final List<String> tags;
  final String? audioFilename;
}

class AnkiExportService {
  const AnkiExportService();

  String exportText({
    required Iterable<AnkiExportCard> cards,
    required AnkiExportOptions options,
  }) {
    final columns = _columns(options);
    final buffer = StringBuffer()
      ..writeln('#separator:Tab')
      ..writeln('#html:true')
      ..writeln('#deck:${_cleanHeader(options.deckName)}')
      ..writeln('#notetype:${_cleanHeader(options.noteType)}')
      ..writeln('#columns:${columns.join('\t')}');

    for (final card in cards) {
      buffer.writeln(_row(card, options).join('\t'));
    }

    return buffer.toString();
  }

  List<String> _columns(AnkiExportOptions options) {
    return [
      'id',
      'front',
      'reading',
      'meaning',
      if (options.includeExamples) 'example',
      if (options.includeSourceMetadata) 'source',
      'tags',
      'audio',
    ];
  }

  List<String> _row(AnkiExportCard card, AnkiExportOptions options) {
    return [
      _cleanField(card.id),
      _cleanField(card.front),
      _cleanField(card.reading),
      _cleanField(card.meaning),
      if (options.includeExamples) _cleanField(card.example),
      if (options.includeSourceMetadata) _cleanField(_safeSource(card.source)),
      _cleanField(card.tags.join(' ')),
      _cleanField(_audioReference(card.audioFilename)),
    ];
  }

  String _cleanHeader(String value) {
    return value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
  }

  String _cleanField(String? value) {
    if (value == null) {
      return '';
    }
    return value.replaceAll(RegExp(r'[\r\n\t]+'), ' ').trim();
  }

  String? _safeSource(String? source) {
    if (source == null) {
      return null;
    }
    final normalized = source.replaceAll('\\', '/');
    final looksLikePath =
        normalized.contains('/') || RegExp(r'^[A-Za-z]:').hasMatch(source);
    if (looksLikePath) {
      return null;
    }
    return source;
  }

  String? _audioReference(String? audioFilename) {
    if (audioFilename == null || audioFilename.trim().isEmpty) {
      return null;
    }
    final filename = audioFilename.replaceAll(RegExp(r'[\r\n\t/\\]+'), '');
    if (filename.isEmpty) {
      return null;
    }
    return '[sound:$filename]';
  }
}
