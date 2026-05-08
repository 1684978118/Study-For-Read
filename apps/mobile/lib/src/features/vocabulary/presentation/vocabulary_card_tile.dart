import 'package:flutter/material.dart';

import 'vocabulary_controller.dart';

class VocabularyCardTile extends StatelessWidget {
  const VocabularyCardTile({
    super.key,
    required this.card,
    this.onKnown,
    this.onUnknown,
  });

  final VocabularyCardView card;
  final Future<void> Function(String cardId)? onKnown;
  final Future<void> Function(String cardId)? onUnknown;

  @override
  Widget build(BuildContext context) {
    final reading = card.reading;
    final privateContext = card.privateContext;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      title: Text(card.surface),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reading != null && reading.isNotEmpty) Text(reading),
            Text(card.definition),
            if (card.isPrivateSentence &&
                privateContext != null &&
                privateContext.isNotEmpty)
              Text(
                privateContext,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                Text(_typeLabel(card.cardType)),
                Text(_reviewLabel(card.reviewStatus, card.reviewCount)),
                Text(_nextReviewLabel(card.nextReviewAt)),
                Text(_syncLabel(card.syncStatus)),
              ],
            ),
            if (onKnown != null && onUnknown != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => onUnknown!(card.id),
                    child: const Text('Unknown'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => onKnown!(card.id),
                    child: const Text('Known'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _typeLabel(String cardType) {
    return cardType == 'private_sentence' ? 'Private sentence' : 'Lexeme';
  }

  String _reviewLabel(String reviewStatus, int reviewCount) {
    return '$reviewStatus - $reviewCount reviews';
  }

  String _nextReviewLabel(DateTime? nextReviewAt) {
    if (nextReviewAt == null) {
      return 'Due now';
    }
    final local = nextReviewAt.toLocal();
    final date = local.toIso8601String().split('T').first;
    return 'Next review $date';
  }

  String _syncLabel(String syncStatus) {
    return switch (syncStatus) {
      'synced' => 'Synced',
      'dirty' => 'Pending sync',
      'failed' => 'Sync failed',
      _ => 'Local only',
    };
  }
}
