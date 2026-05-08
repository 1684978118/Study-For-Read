class LocalLexeme {
  const LocalLexeme({
    required this.id,
    required this.surface,
    this.reading,
    required this.sourceLang,
    required this.targetLang,
    required this.entryType,
    this.partOfSpeech,
    required this.definition,
    this.shortDefinition,
    required this.cachedAt,
    required this.updatedAt,
  });

  final String id;
  final String surface;
  final String? reading;
  final String sourceLang;
  final String targetLang;
  final String entryType;
  final String? partOfSpeech;
  final String definition;
  final String? shortDefinition;
  final DateTime cachedAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'surface': surface,
      'reading': reading,
      'source_lang': sourceLang,
      'target_lang': targetLang,
      'entry_type': entryType,
      'part_of_speech': partOfSpeech,
      'definition': definition,
      'short_definition': shortDefinition,
      'cached_at': cachedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalLexeme.fromMap(Map<String, Object?> map) {
    return LocalLexeme(
      id: map['id'] as String,
      surface: map['surface'] as String,
      reading: map['reading'] as String?,
      sourceLang: map['source_lang'] as String,
      targetLang: map['target_lang'] as String,
      entryType: map['entry_type'] as String,
      partOfSpeech: map['part_of_speech'] as String?,
      definition: map['definition'] as String,
      shortDefinition: map['short_definition'] as String?,
      cachedAt: DateTime.parse(map['cached_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }
}
