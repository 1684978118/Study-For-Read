class LocalChapter {
  const LocalChapter({
    required this.id,
    required this.bookId,
    required this.chapterIndex,
    required this.title,
    required this.content,
    required this.paragraphCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String bookId;
  final int chapterIndex;
  final String title;
  final String content;
  final int paragraphCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'book_id': bookId,
      'chapter_index': chapterIndex,
      'title': title,
      'content': content,
      'paragraph_count': paragraphCount,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  factory LocalChapter.fromMap(Map<String, Object?> map) {
    return LocalChapter(
      id: map['id'] as String,
      bookId: map['book_id'] as String,
      chapterIndex: map['chapter_index'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      paragraphCount: map['paragraph_count'] as int,
      createdAt: DateTime.parse(map['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toUtc(),
    );
  }
}
