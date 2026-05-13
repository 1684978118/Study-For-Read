import 'package:flutter/material.dart';

import '../../study/domain/paragraph_selection.dart';
import '../../study/domain/reader_text_selection.dart';
import '../../study/presentation/inline_paragraph_translation.dart';
import '../../study/presentation/paragraph_translation_controller.dart';

class ReadingTextView extends StatelessWidget {
  const ReadingTextView({
    super.key,
    required this.text,
    required this.fontSize,
    this.padding = const EdgeInsets.fromLTRB(24, 44, 24, 56),
    this.onLookup,
    this.onTranslateParagraph,
    this.translationStateFor,
  });

  final String text;
  final double fontSize;
  final EdgeInsetsGeometry padding;
  final ValueChanged<ReaderTextSelection>? onLookup;
  final ValueChanged<ParagraphSelection>? onTranslateParagraph;
  final ParagraphTranslationState? Function(ParagraphSelection selection)?
  translationStateFor;

  @override
  Widget build(BuildContext context) {
    final paragraphs = _paragraphs();
    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final paragraph in paragraphs)
            _ParagraphView(
              paragraph: paragraph,
              fontSize: fontSize,
              onLookup: onLookup,
              onTranslateParagraph: onTranslateParagraph,
              translationStateFor: translationStateFor,
            ),
        ],
      ),
    );
  }

  List<_Paragraph> _paragraphs() {
    final values = text
        .split(RegExp(r'\n\s*\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (values.isEmpty) {
      return const [];
    }
    return [
      for (var index = 0; index < values.length; index++)
        _Paragraph(index: index, text: values[index]),
    ];
  }
}

class _ParagraphView extends StatelessWidget {
  const _ParagraphView({
    required this.paragraph,
    required this.fontSize,
    this.onLookup,
    this.onTranslateParagraph,
    this.translationStateFor,
  });

  final _Paragraph paragraph;
  final double fontSize;
  final ValueChanged<ReaderTextSelection>? onLookup;
  final ValueChanged<ParagraphSelection>? onTranslateParagraph;
  final ParagraphTranslationState? Function(ParagraphSelection selection)?
  translationStateFor;

  @override
  Widget build(BuildContext context) {
    final selection = ParagraphSelection(
      selectedParagraphText: paragraph.text,
      paragraphIndex: paragraph.index,
    );
    final translationState = translationStateFor?.call(selection);
    final textStyle = TextStyle(
      fontSize: fontSize,
      height: 1.72,
      letterSpacing: 0,
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.end,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onLookup == null
                  ? null
                  : () => onLookup!(_lookupSelection()),
              child: Text(paragraph.text, style: textStyle),
            ),
            GestureDetector(
              key: Key('paragraph-translate-hotspot-${paragraph.index}'),
              behavior: HitTestBehavior.opaque,
              onTap: onTranslateParagraph == null
                  ? null
                  : () => onTranslateParagraph!(selection),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 18, 4),
                child: Text(
                  '+',
                  style: textStyle.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.22),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (translationState != null)
          InlineParagraphTranslation(
            state: translationState,
            fontSize: fontSize,
          ),
        if (translationState == null) const SizedBox(height: 18),
      ],
    );
  }

  ReaderTextSelection _lookupSelection() {
    final selectedText = _firstLookupToken(paragraph.text);
    return ReaderTextSelection(
      selectedText: selectedText,
      paragraphContext: paragraph.text,
    );
  }

  String _firstLookupToken(String value) {
    final hanMatches = RegExp(
      r'[\p{Script=Han}]+',
      unicode: true,
    ).allMatches(value).toList(growable: false);
    if (hanMatches.isNotEmpty) {
      return hanMatches.last.group(0)!.characters.last;
    }

    final kanaMatch = RegExp(
      r'[\p{Script=Hiragana}\p{Script=Katakana}]+',
      unicode: true,
    ).firstMatch(value);
    return kanaMatch?.group(0) ?? value.trim();
  }
}

class _Paragraph {
  const _Paragraph({required this.index, required this.text});

  final int index;
  final String text;
}
