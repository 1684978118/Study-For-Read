import 'package:flutter/material.dart';

import '../../study/domain/reader_text_selection.dart';

class ReadingTextView extends StatelessWidget {
  const ReadingTextView({
    super.key,
    required this.text,
    required this.fontSize,
    this.onLookup,
  });

  final String text;
  final double fontSize;
  final ValueChanged<ReaderTextSelection>? onLookup;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 44, 24, 56),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onLookup == null ? null : () => onLookup!(_selectionFromText()),
        child: Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.72,
            letterSpacing: 0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  ReaderTextSelection _selectionFromText() {
    final paragraph = text
        .split(RegExp(r'\n\s*\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    final selectedText = _firstLookupToken(paragraph ?? text.trim());
    return ReaderTextSelection(
      selectedText: selectedText,
      paragraphContext: paragraph,
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
