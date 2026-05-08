import 'package:flutter/material.dart';

import 'paragraph_translation_controller.dart';

class InlineParagraphTranslation extends StatelessWidget {
  const InlineParagraphTranslation({
    super.key,
    required this.state,
    required this.fontSize,
  });

  final ParagraphTranslationState state;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final text = switch (state.status) {
      ParagraphTranslationStatus.loading => 'Translating...',
      ParagraphTranslationStatus.cached ||
      ParagraphTranslationStatus.success => state.translatedText,
      ParagraphTranslationStatus.offline => state.message,
      ParagraphTranslationStatus.error => state.message,
      ParagraphTranslationStatus.idle => null,
    };
    if (text == null || text.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 18),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          height: 1.64,
          letterSpacing: 0,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
