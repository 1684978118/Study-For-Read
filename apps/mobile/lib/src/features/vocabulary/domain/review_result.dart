class ReviewResult {
  const ReviewResult({
    required this.reviewStatus,
    required this.reviewCount,
    required this.nextReviewAt,
    required this.lastReviewedAt,
  });

  final String reviewStatus;
  final int reviewCount;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  DateTime get reviewedAt => lastReviewedAt;
}
