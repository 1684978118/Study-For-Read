class StudyStatsSummary {
  const StudyStatsSummary({
    required this.readingMinutes,
    required this.lookupCount,
    required this.paragraphTranslationCount,
    required this.cardsCreated,
    required this.cardsReviewed,
  });

  static const zero = StudyStatsSummary(
    readingMinutes: 0,
    lookupCount: 0,
    paragraphTranslationCount: 0,
    cardsCreated: 0,
    cardsReviewed: 0,
  );

  final int readingMinutes;
  final int lookupCount;
  final int paragraphTranslationCount;
  final int cardsCreated;
  final int cardsReviewed;

  StudyStatsSummary operator +(StudyStatsSummary other) {
    return StudyStatsSummary(
      readingMinutes: readingMinutes + other.readingMinutes,
      lookupCount: lookupCount + other.lookupCount,
      paragraphTranslationCount:
          paragraphTranslationCount + other.paragraphTranslationCount,
      cardsCreated: cardsCreated + other.cardsCreated,
      cardsReviewed: cardsReviewed + other.cardsReviewed,
    );
  }
}
