class ParagraphSelection {
  const ParagraphSelection({
    required this.selectedParagraphText,
    this.bookFingerprint,
    this.chapterIndex,
    this.paragraphIndex,
  });

  final String selectedParagraphText;
  final String? bookFingerprint;
  final int? chapterIndex;
  final int? paragraphIndex;
}
