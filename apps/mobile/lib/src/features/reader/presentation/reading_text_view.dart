import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../study/domain/paragraph_selection.dart';
import '../../study/domain/reader_text_selection.dart';
import '../../study/presentation/inline_paragraph_translation.dart';
import '../../study/presentation/paragraph_translation_controller.dart';
import '../domain/reader_preferences.dart';

class ReadingTextView extends StatefulWidget {
  const ReadingTextView({
    super.key,
    required this.text,
    required this.fontSize,
    this.lineHeight = 1.72,
    this.paragraphSpacing = 18,
    this.padding = const EdgeInsets.fromLTRB(24, 44, 24, 56),
    this.paginated = false,
    this.currentPageIndex = 0,
    this.pageTurnMode = ReaderPageTurnMode.slide,
    this.onPageChanged,
    this.onPageCountChanged,
    this.onLookup,
    this.onBlankTap,
    this.onTranslateParagraph,
    this.translationStateFor,
  });

  final String text;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final EdgeInsetsGeometry padding;
  final bool paginated;
  final int currentPageIndex;
  final ReaderPageTurnMode pageTurnMode;
  final ValueChanged<int>? onPageChanged;
  final ValueChanged<int>? onPageCountChanged;
  final ValueChanged<ReaderTextSelection>? onLookup;
  final VoidCallback? onBlankTap;
  final ValueChanged<ParagraphSelection>? onTranslateParagraph;
  final ParagraphTranslationState? Function(ParagraphSelection selection)?
  translationStateFor;

  @override
  State<ReadingTextView> createState() => _ReadingTextViewState();
}

class _ReadingTextViewState extends State<ReadingTextView> {
  static const double _paginationSafetyInset = 12;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentPageIndex);
  }

  @override
  void didUpdateWidget(covariant ReadingTextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _pageController.dispose();
      _pageController = PageController(initialPage: widget.currentPageIndex);
      return;
    }
    if (oldWidget.currentPageIndex != widget.currentPageIndex &&
        _pageController.hasClients) {
      _pageController.jumpToPage(widget.currentPageIndex);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = _paragraphs();
    if (!widget.paginated) {
      return _buildScrollable(paragraphs);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedPadding = widget.padding.resolve(
          Directionality.of(context),
        );
        final pageWidth = math.max(
          1.0,
          constraints.maxWidth - resolvedPadding.horizontal,
        );
        final pageHeight = math.max(
          1.0,
          constraints.maxHeight - resolvedPadding.vertical,
        );
        final pages = _paginate(
          context: context,
          paragraphs: paragraphs,
          pageWidth: pageWidth,
          pageHeight: pageHeight,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onPageCountChanged?.call(pages.length);
          }
        });

        return Padding(
          padding: widget.padding,
          child: PageView.builder(
            key: const Key('reader-page-view'),
            controller: _pageController,
            scrollDirection: widget.pageTurnMode == ReaderPageTurnMode.vertical
                ? Axis.vertical
                : Axis.horizontal,
            physics: widget.pageTurnMode == ReaderPageTurnMode.none
                ? const NeverScrollableScrollPhysics()
                : null,
            itemCount: pages.length,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              return _wrapPageTurnMode(
                index: index,
                child: _buildParagraphColumn(pages[index]),
              );
            },
          ),
        );
      },
    );
  }

  Widget _wrapPageTurnMode({required int index, required Widget child}) {
    return switch (widget.pageTurnMode) {
      ReaderPageTurnMode.cover => KeyedSubtree(
        key: const Key('reader-page-turn-cover'),
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, _) {
            final page = _pageController.hasClients
                ? (_pageController.page ?? widget.currentPageIndex.toDouble())
                : widget.currentPageIndex.toDouble();
            final delta = (page - index).clamp(-1.0, 1.0);
            return Transform.translate(
              offset: Offset(delta * -18, 0),
              child: child,
            );
          },
        ),
      ),
      ReaderPageTurnMode.simulation => KeyedSubtree(
        key: const Key('reader-page-turn-simulation'),
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, _) {
            final page = _pageController.hasClients
                ? (_pageController.page ?? widget.currentPageIndex.toDouble())
                : widget.currentPageIndex.toDouble();
            final delta = (page - index).clamp(-1.0, 1.0);
            return Transform(
              alignment: delta >= 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(delta * 0.10),
              child: child,
            );
          },
        ),
      ),
      _ => child,
    };
  }

  Widget _buildScrollable(List<_Paragraph> paragraphs) {
    return SingleChildScrollView(
      padding: widget.padding,
      child: _buildParagraphColumn(paragraphs),
    );
  }

  Widget _buildParagraphColumn(List<_Paragraph> paragraphs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          _ParagraphView(
            paragraph: paragraph,
            fontSize: widget.fontSize,
            lineHeight: widget.lineHeight,
            paragraphSpacing: widget.paragraphSpacing,
            onLookup: widget.onLookup,
            onBlankTap: widget.onBlankTap,
            onTranslateParagraph: widget.onTranslateParagraph,
            translationStateFor: widget.translationStateFor,
          ),
      ],
    );
  }

  List<List<_Paragraph>> _paginate({
    required BuildContext context,
    required List<_Paragraph> paragraphs,
    required double pageWidth,
    required double pageHeight,
  }) {
    if (paragraphs.isEmpty) {
      return const [[]];
    }

    final textStyle = TextStyle(
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      letterSpacing: 0,
    );
    final pages = <List<_Paragraph>>[];
    var currentPage = <_Paragraph>[];
    var usedHeight = 0.0;
    final effectivePageHeight = math.max(
      1.0,
      pageHeight - _paginationSafetyInset,
    );

    for (final paragraph in paragraphs) {
      final paragraphHeight = paragraph.epubImageUri == null
          ? _measureParagraphHeight(
              context: context,
              paragraph: paragraph,
              style: textStyle,
              maxWidth: pageWidth,
            )
          : pageHeight;
      if (paragraph.epubImageUri == null &&
          paragraphHeight + widget.paragraphSpacing > effectivePageHeight) {
        if (currentPage.isNotEmpty) {
          pages.add(currentPage);
          currentPage = <_Paragraph>[];
          usedHeight = 0;
        }

        final splitParagraphs = _splitParagraphForPages(
          context: context,
          paragraph: paragraph,
          style: textStyle,
          maxWidth: pageWidth,
          maxHeight: math.max(
            1.0,
            effectivePageHeight - widget.paragraphSpacing,
          ),
        );
        for (final splitParagraph in splitParagraphs) {
          pages.add([splitParagraph]);
        }
        continue;
      }

      final blockHeight = math.min(
        effectivePageHeight,
        paragraphHeight + widget.paragraphSpacing,
      );
      final shouldStartNewPage =
          currentPage.isNotEmpty &&
          usedHeight + blockHeight > effectivePageHeight;
      if (shouldStartNewPage) {
        pages.add(currentPage);
        currentPage = <_Paragraph>[];
        usedHeight = 0;
      }

      currentPage.add(paragraph);
      usedHeight += blockHeight;

      if (paragraph.epubImageUri != null) {
        pages.add(currentPage);
        currentPage = <_Paragraph>[];
        usedHeight = 0;
      }
    }

    if (currentPage.isNotEmpty) {
      pages.add(currentPage);
    }
    return pages.isEmpty ? const [[]] : pages;
  }

  List<_Paragraph> _splitParagraphForPages({
    required BuildContext context,
    required _Paragraph paragraph,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
  }) {
    final chunks = <_Paragraph>[];
    var remaining = paragraph.text.trim();
    var chunkIndex = 0;

    while (remaining.isNotEmpty) {
      final splitEnd = _largestFittingTextEnd(
        context: context,
        text: remaining,
        style: style,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );
      final chunkText = remaining.substring(0, splitEnd).trim();
      if (chunkText.isNotEmpty) {
        chunks.add(
          _Paragraph(
            index: -((paragraph.index + 1) * 1000 + chunkIndex),
            sourceIndex: paragraph.sourceIndex,
            text: chunkText,
          ),
        );
        chunkIndex += 1;
      }
      remaining = remaining.substring(splitEnd).trimLeft();
    }

    return chunks.isEmpty ? [paragraph] : chunks;
  }

  int _largestFittingTextEnd({
    required BuildContext context,
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double maxHeight,
  }) {
    var low = 1;
    var high = text.length;
    var best = 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = text.substring(0, mid).trimRight();
      final height = _measureTextHeight(
        context: context,
        text: '\u3000$candidate',
        style: style,
        maxWidth: maxWidth,
      );
      if (height <= maxHeight) {
        best = mid;
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }

    return _preferredSplitEnd(text, best);
  }

  int _preferredSplitEnd(String text, int fallbackEnd) {
    final boundedEnd = fallbackEnd.clamp(1, text.length);
    const breakChars = '。！？!?、，,. ';
    for (var index = boundedEnd - 1; index > 0; index--) {
      if (breakChars.contains(text[index])) {
        return index + 1;
      }
    }
    return boundedEnd;
  }

  double _measureParagraphHeight({
    required BuildContext context,
    required _Paragraph paragraph,
    required TextStyle style,
    required double maxWidth,
  }) {
    return _measureTextHeight(
      context: context,
      text: paragraph.displayText,
      style: style,
      maxWidth: maxWidth,
    );
  }

  double _measureTextHeight({
    required BuildContext context,
    required String text,
    required TextStyle style,
    required double maxWidth,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return textPainter.height;
  }

  List<_Paragraph> _paragraphs() {
    final values = widget.text
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
    required this.lineHeight,
    required this.paragraphSpacing,
    this.onLookup,
    this.onBlankTap,
    this.onTranslateParagraph,
    this.translationStateFor,
  });

  final _Paragraph paragraph;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final ValueChanged<ReaderTextSelection>? onLookup;
  final VoidCallback? onBlankTap;
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
      paragraphIndex: paragraph.sourceIndex,
    );
    final translationState = translationStateFor?.call(selection);
    final textStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
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
            return GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: onBlankTap,
              child: SizedBox(
                width: constraints.maxWidth,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _LookupParagraphText(
                      text: paragraph.displayText,
                      style: textStyle,
                      onTap: onLookup == null
                          ? null
                          : () => onLookup!(_lookupSelection()),
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
                          padding: const EdgeInsets.fromLTRB(8, 2, 18, 8),
                          child: Icon(
                            Icons.add_circle_outline,
                            size: (fontSize * 0.78).clamp(14.0, 20.0),
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.18),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (translationState != null)
          InlineParagraphTranslation(
            state: translationState,
            fontSize: fontSize,
          ),
        if (translationState == null) SizedBox(height: paragraphSpacing),
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
      text: TextSpan(text: paragraph.displayText, style: style),
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
  const _Paragraph({
    required this.index,
    required this.text,
    int? sourceIndex,
  }) : sourceIndex = sourceIndex ?? index;

  final int index;
  final int sourceIndex;
  final String text;

  String get displayText => '\u3000$text';

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

class _LookupParagraphText extends StatefulWidget {
  const _LookupParagraphText({
    required this.text,
    required this.style,
    required this.onTap,
  });

  final String text;
  final TextStyle style;
  final VoidCallback? onTap;

  @override
  State<_LookupParagraphText> createState() => _LookupParagraphTextState();
}

class _LookupParagraphTextState extends State<_LookupParagraphText> {
  late final TapGestureRecognizer _recognizer;

  @override
  void initState() {
    super.initState();
    _recognizer = TapGestureRecognizer();
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _recognizer.onTap = widget.onTap;
    return Text.rich(
      TextSpan(
        text: widget.text,
        style: widget.style,
        recognizer: widget.onTap == null ? null : _recognizer,
      ),
    );
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
