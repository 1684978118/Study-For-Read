import 'dart:io';

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
    final imageUri = paragraph.epubImageUri;
    if (imageUri != null) {
      return _EpubImagePage(
        paragraphIndex: paragraph.index,
        imageUri: imageUri,
      );
    }

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
        LayoutBuilder(
          builder: (context, constraints) {
            final hotspotOffset = _hotspotOffset(
              context: context,
              style: textStyle,
              maxWidth: constraints.maxWidth,
            );
            return SizedBox(
              width: constraints.maxWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onLookup == null
                        ? null
                        : () => onLookup!(_lookupSelection()),
                    child: Text(paragraph.text, style: textStyle),
                  ),
                  Positioned(
                    left: hotspotOffset.dx,
                    top: hotspotOffset.dy,
                    child: GestureDetector(
                      key: Key(
                        'paragraph-translate-hotspot-${paragraph.index}',
                      ),
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
                  ),
                ],
              ),
            );
          },
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

  Offset _hotspotOffset({
    required BuildContext context,
    required TextStyle style,
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: paragraph.text, style: style),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    final lines = textPainter.computeLineMetrics();
    if (lines.isEmpty) {
      return Offset.zero;
    }

    final lastLine = lines.last;
    final left = (lastLine.left + lastLine.width + 4).clamp(0.0, maxWidth - 44);
    final top = (lastLine.baseline - lastLine.ascent - 6).clamp(
      0.0,
      double.infinity,
    );
    return Offset(left, top);
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

  Uri? get epubImageUri {
    final match = RegExp(
      r'^!\[epub-image\]\((file://[^)]+)\)$',
    ).firstMatch(text);
    final value = match?.group(1);
    if (value == null) {
      return null;
    }
    return Uri.tryParse(value);
  }
}

class _EpubImagePage extends StatelessWidget {
  const _EpubImagePage({required this.paragraphIndex, required this.imageUri});

  final int paragraphIndex;
  final Uri imageUri;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        key: Key('epub-image-page-$paragraphIndex'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPreview(context),
        child: SizedBox(
          width: double.infinity,
          height: 520,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File.fromUri(imageUri),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: Center(child: Icon(Icons.broken_image_outlined)),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPreview(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog.fullscreen(
          key: const Key('epub-image-preview'),
          backgroundColor: Colors.black,
          child: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image.file(
                      File.fromUri(imageUri),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.broken_image_outlined,
                          color: Colors.white70,
                          size: 48,
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    tooltip: '关闭',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
