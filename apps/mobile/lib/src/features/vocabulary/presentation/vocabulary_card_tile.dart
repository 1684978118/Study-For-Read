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
                    child: const Text('不认识'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => onKnown!(card.id),
                    child: const Text('认识'),
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
    return cardType == 'private_sentence' ? '私密例句' : '词条';
  }

  String _reviewLabel(String reviewStatus, int reviewCount) {
    final label = switch (reviewStatus) {
      'new' => '新卡',
      'learning' => '学习中',
      'known' => '已掌握',
      _ => reviewStatus,
    };
    return '$label - 已复习 $reviewCount 次';
  }

  String _nextReviewLabel(DateTime? nextReviewAt) {
    if (nextReviewAt == null) {
      return '现在可复习';
    }
    final local = nextReviewAt.toLocal();
    final date = local.toIso8601String().split('T').first;
    return '下次复习 $date';
  }

  String _syncLabel(String syncStatus) {
    return switch (syncStatus) {
      'synced' => '已同步',
      'dirty' => '待同步',
      'failed' => '同步失败',
      _ => '仅本地',
    };
  }
}
