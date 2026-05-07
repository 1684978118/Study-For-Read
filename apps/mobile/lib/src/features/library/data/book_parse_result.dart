class ParsedBook {
  const ParsedBook({
    required this.title,
    this.author,
    required this.fileType,
    required this.sourceLang,
    required this.targetLang,
    required this.chapters,
  });

  final String title;
  final String? author;
  final String fileType;
  final String sourceLang;
  final String targetLang;
  final List<ParsedChapter> chapters;
}

class ParsedChapter {
  const ParsedChapter({
    required this.chapterIndex,
    required this.title,
    required this.content,
    required this.paragraphs,
  });

  final int chapterIndex;
  final String title;
  final String content;
  final List<String> paragraphs;
}

sealed class BookParseException implements Exception {
  const BookParseException(this.message);

  final String message;

  @override
  String toString() => message;
}

class EmptyBookParseException extends BookParseException {
  const EmptyBookParseException() : super('TXT file is empty');
}

class InvalidBookEncodingException extends BookParseException {
  const InvalidBookEncodingException() : super('TXT file is not valid UTF-8');
}
