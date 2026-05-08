class TranslationResult {
  const TranslationResult({
    required this.translatedText,
    required this.provider,
    required this.cached,
    this.message,
  });

  final String translatedText;
  final String provider;
  final bool cached;
  final String? message;

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      translatedText: json['translatedText'] as String,
      provider: json['provider'] as String,
      cached: json['cached'] == true,
      message: json['message'] as String?,
    );
  }
}
