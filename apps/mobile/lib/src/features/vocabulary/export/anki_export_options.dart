enum AnkiExportScope {
  allCards,
  dueCards,
  privateSentenceCards,
}

class AnkiExportOptions {
  const AnkiExportOptions({
    required this.scope,
    this.includeExamples = true,
    this.includeSourceMetadata = true,
    this.deckName = 'StudyForRead::Japanese',
    this.noteType = 'StudyForRead Japanese',
  });

  final AnkiExportScope scope;
  final bool includeExamples;
  final bool includeSourceMetadata;
  final String deckName;
  final String noteType;

  AnkiExportOptions copyWith({
    AnkiExportScope? scope,
    bool? includeExamples,
    bool? includeSourceMetadata,
    String? deckName,
    String? noteType,
  }) {
    return AnkiExportOptions(
      scope: scope ?? this.scope,
      includeExamples: includeExamples ?? this.includeExamples,
      includeSourceMetadata:
          includeSourceMetadata ?? this.includeSourceMetadata,
      deckName: deckName ?? this.deckName,
      noteType: noteType ?? this.noteType,
    );
  }
}
