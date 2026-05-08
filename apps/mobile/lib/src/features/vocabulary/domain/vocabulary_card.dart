class VocabularyCardResult {
  const VocabularyCardResult({required this.card, required this.existing});

  final VocabularyCard card;
  final bool existing;
}

class VocabularyCard {
  const VocabularyCard({
    required this.id,
    required this.cardType,
    this.lexeme,
    this.surface,
    this.reading,
    this.definition,
    required this.reviewStatus,
    required this.reviewCount,
    this.nextReviewAt,
    this.lastReviewedAt,
  });

  final String id;
  final String cardType;
  final VocabularyLexeme? lexeme;
  final String? surface;
  final String? reading;
  final String? definition;
  final String reviewStatus;
  final int reviewCount;
  final DateTime? nextReviewAt;
  final DateTime? lastReviewedAt;

  factory VocabularyCard.fromJson(Map<String, dynamic> json) {
    final lexemeJson = json['lexeme'];
    final lexeme = lexemeJson is Map
        ? VocabularyLexeme.fromJson(Map<String, dynamic>.from(lexemeJson))
        : null;
    return VocabularyCard(
      id: json['id'] as String,
      cardType: json['cardType'] as String? ?? 'lexeme',
      lexeme: lexeme,
      surface: json['surface'] as String? ?? lexeme?.surface,
      reading: json['reading'] as String? ?? lexeme?.reading,
      definition: json['definition'] as String? ?? lexeme?.definition,
      reviewStatus: json['reviewStatus'] as String,
      reviewCount: json['reviewCount'] as int? ?? 0,
      nextReviewAt: _parseDateTime(json['nextReviewAt']),
      lastReviewedAt: _parseDateTime(json['lastReviewedAt']),
    );
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value).toUtc();
  }
}

class VocabularyLexeme {
  const VocabularyLexeme({
    required this.id,
    required this.surface,
    this.reading,
    required this.definition,
  });

  final String id;
  final String surface;
  final String? reading;
  final String definition;

  factory VocabularyLexeme.fromJson(Map<String, dynamic> json) {
    return VocabularyLexeme(
      id: json['id'] as String,
      surface: json['surface'] as String,
      reading: json['reading'] as String?,
      definition: json['definition'] as String,
    );
  }
}
