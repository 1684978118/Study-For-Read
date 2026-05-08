class AnnotationToken {
  const AnnotationToken({
    required this.text,
    this.reading,
    required this.dictionaryForm,
    required this.partOfSpeech,
  });

  final String text;
  final String? reading;
  final String dictionaryForm;
  final String partOfSpeech;

  factory AnnotationToken.fromJson(Map<String, dynamic> json) {
    return AnnotationToken(
      text: json['text'] as String,
      reading: json['reading'] as String?,
      dictionaryForm: json['dictionaryForm'] as String,
      partOfSpeech: json['partOfSpeech'] as String,
    );
  }
}
