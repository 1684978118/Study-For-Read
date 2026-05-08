class LookupResult {
  const LookupResult({
    required this.kind,
    required this.lexeme,
    required this.provider,
    this.providerMessage,
  });

  final String kind;
  final LookupLexeme lexeme;
  final String provider;
  final String? providerMessage;

  factory LookupResult.fromJson(Map<String, dynamic> json) {
    final lexemeJson = json['lexeme'];
    if (lexemeJson is! Map) {
      throw const FormatException('Missing lookup lexeme');
    }
    return LookupResult(
      kind: json['kind'] as String,
      lexeme: LookupLexeme.fromJson(Map<String, dynamic>.from(lexemeJson)),
      provider: json['provider'] as String,
      providerMessage: json['providerMessage'] as String?,
    );
  }
}

class LookupLexeme {
  const LookupLexeme({
    required this.id,
    required this.surface,
    this.reading,
    required this.entryType,
    this.partOfSpeech,
    required this.definition,
    this.shortDefinition,
  });

  final String id;
  final String surface;
  final String? reading;
  final String entryType;
  final String? partOfSpeech;
  final String definition;
  final String? shortDefinition;

  factory LookupLexeme.fromJson(Map<String, dynamic> json) {
    return LookupLexeme(
      id: json['id'] as String,
      surface: json['surface'] as String,
      reading: json['reading'] as String?,
      entryType: json['entryType'] as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      definition: json['definition'] as String,
      shortDefinition: json['shortDefinition'] as String?,
    );
  }
}
