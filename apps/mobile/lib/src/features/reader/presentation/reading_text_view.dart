import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_ruby_text/flutter_ruby_text.dart';

import '../../study/domain/paragraph_selection.dart';
import '../../study/domain/reader_text_selection.dart';
import '../../study/presentation/inline_paragraph_translation.dart';
import '../../study/presentation/paragraph_translation_controller.dart';
import '../domain/furigana_generator.dart';
import '../domain/reader_preferences.dart';

typedef FuriganaGenerator = Future<List<FuriganaSegment>> Function(String text);

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
    this.onPageParagraphsChanged,
    this.onLookup,
    this.onBlankTap,
    this.onTranslateParagraph,
    this.translationStateFor,
    this.furiganaEnabled = false,
    this.furiganaGenerator,
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
  final ValueChanged<List<List<ParagraphSelection>>>? onPageParagraphsChanged;
  final ValueChanged<ReaderTextSelection>? onLookup;
  final VoidCallback? onBlankTap;
  final ValueChanged<ParagraphSelection>? onTranslateParagraph;
  final ParagraphTranslationState? Function(ParagraphSelection selection)?
  translationStateFor;
  final bool furiganaEnabled;
  final FuriganaGenerator? furiganaGenerator;

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
            widget.onPageParagraphsChanged?.call(
              pages
                  .map(
                    (page) => page
                        .map(
                          (paragraph) => ParagraphSelection(
                            selectedParagraphText: paragraph.text,
                            paragraphIndex: paragraph.sourceIndex,
                          ),
                        )
                        .toList(growable: false),
                  )
                  .toList(growable: false),
            );
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
                child: _buildPage(
                  context: context,
                  paragraphs: pages[index],
                  pageWidth: pageWidth,
                  pageHeight: pageHeight,
                ),
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

  Widget _buildPage({
    required BuildContext context,
    required List<_Paragraph> paragraphs,
    required double pageWidth,
    required double pageHeight,
  }) {
    final child = _buildParagraphColumn(paragraphs, maxImageHeight: pageHeight);
    final contentHeight = _measurePageContentHeight(
      context: context,
      paragraphs: paragraphs,
      maxWidth: pageWidth,
      pageHeight: pageHeight,
    );
    if (!widget.furiganaEnabled && contentHeight <= pageHeight) {
      return child;
    }

    return SingleChildScrollView(
      primary: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: pageHeight),
        child: child,
      ),
    );
  }

  Widget _buildParagraphColumn(
    List<_Paragraph> paragraphs, {
    double? maxImageHeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final paragraph in paragraphs)
          _ParagraphView(
            paragraph: paragraph,
            fontSize: widget.fontSize,
            lineHeight: widget.lineHeight,
            paragraphSpacing: widget.paragraphSpacing,
            maxImageHeight: maxImageHeight,
            onLookup: widget.onLookup,
            onBlankTap: widget.onBlankTap,
            onTranslateParagraph: widget.onTranslateParagraph,
            translationStateFor: widget.translationStateFor,
            furiganaEnabled: widget.furiganaEnabled,
            furiganaGenerator: widget.furiganaGenerator,
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
      if (paragraph.epubImageUri != null) {
        if (currentPage.isNotEmpty) {
          pages.add(currentPage);
          currentPage = <_Paragraph>[];
          usedHeight = 0;
        }
        pages.add([paragraph]);
        continue;
      }

      final paragraphHeight = _measureParagraphHeight(
        context: context,
        paragraph: paragraph,
        style: textStyle,
        maxWidth: pageWidth,
      );
      if (paragraphHeight + widget.paragraphSpacing > effectivePageHeight) {
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
      final height = _measureParagraphTextMetrics(
        text: '\u3000$candidate',
        style: style,
        maxWidth: maxWidth,
        textDirection: Directionality.of(context),
        furiganaEnabled: widget.furiganaEnabled,
      ).visualHeight;
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
    return _measureParagraphTextMetrics(
      text: paragraph.displayText,
      style: style,
      maxWidth: maxWidth,
      textDirection: Directionality.of(context),
      furiganaEnabled: widget.furiganaEnabled,
    ).visualHeight;
  }

  double _measurePageContentHeight({
    required BuildContext context,
    required List<_Paragraph> paragraphs,
    required double maxWidth,
    required double pageHeight,
  }) {
    final paragraphStyle = TextStyle(
      fontSize: widget.fontSize,
      height: widget.lineHeight,
      letterSpacing: 0,
    );
    return paragraphs.fold<double>(
      0,
      (total, paragraph) =>
          total +
          _measureParagraphBlockHeight(
            context: context,
            paragraph: paragraph,
            paragraphStyle: paragraphStyle,
            maxWidth: maxWidth,
            pageHeight: pageHeight,
          ),
    );
  }

  double _measureParagraphBlockHeight({
    required BuildContext context,
    required _Paragraph paragraph,
    required TextStyle paragraphStyle,
    required double maxWidth,
    required double pageHeight,
  }) {
    if (paragraph.epubImageUri != null) {
      return _boundedImageHeight(pageHeight) + 24;
    }

    final paragraphHeight = _measureParagraphHeight(
      context: context,
      paragraph: paragraph,
      style: paragraphStyle,
      maxWidth: maxWidth,
    );
    final translationState = widget.translationStateFor?.call(
      ParagraphSelection(
        selectedParagraphText: paragraph.text,
        paragraphIndex: paragraph.sourceIndex,
      ),
    );
    final translationText = translationState == null
        ? null
        : InlineParagraphTranslation.textForState(translationState);
    if (translationText == null || translationText.isEmpty) {
      return paragraphHeight + widget.paragraphSpacing;
    }

    final translationHeight = _measureTextHeight(
      context: context,
      text: translationText,
      style: TextStyle(
        fontSize: widget.fontSize,
        height: 1.64,
        letterSpacing: 0,
      ),
      maxWidth: maxWidth,
    );
    return paragraphHeight + 8 + translationHeight + 18;
  }

  double _boundedImageHeight(double pageHeight) {
    return math.max(1.0, math.min(520.0, pageHeight - 24));
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
    this.maxImageHeight,
    this.onLookup,
    this.onBlankTap,
    this.onTranslateParagraph,
    this.translationStateFor,
    this.furiganaEnabled = false,
    this.furiganaGenerator,
  });

  final _Paragraph paragraph;
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final double? maxImageHeight;
  final ValueChanged<ReaderTextSelection>? onLookup;
  final VoidCallback? onBlankTap;
  final ValueChanged<ParagraphSelection>? onTranslateParagraph;
  final ParagraphTranslationState? Function(ParagraphSelection selection)?
  translationStateFor;
  final bool furiganaEnabled;
  final FuriganaGenerator? furiganaGenerator;

  @override
  Widget build(BuildContext context) {
    final imageUri = paragraph.epubImageUri;
    if (imageUri != null) {
      return _EpubImagePage(
        paragraphIndex: paragraph.index,
        imageUri: imageUri,
        maxHeight: maxImageHeight,
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
            final metrics = _measureParagraphTextMetrics(
              text: paragraph.displayText,
              style: textStyle,
              maxWidth: constraints.maxWidth,
              textDirection: Directionality.of(context),
              furiganaEnabled: furiganaEnabled,
            );
            final iconSize = (fontSize * 0.78).clamp(14.0, 20.0);
            final hotspotOffset = metrics.hotspotOffset(
              iconSize: iconSize,
              maxWidth: constraints.maxWidth,
            );
            return furiganaEnabled
                ? SizedBox(
                    width: constraints.maxWidth,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _LookupParagraphText(
                          key: Key('reader-paragraph-${paragraph.index}'),
                          text: paragraph.displayText,
                          style: textStyle,
                          furiganaEnabled: furiganaEnabled,
                          furiganaGenerator: furiganaGenerator,
                          onBlankTap: onBlankTap,
                          onLookupText: onLookup == null
                              ? null
                              : (selectedText) =>
                                    onLookup!(_lookupSelection(selectedText)),
                        ),
                        Positioned(
                          left: metrics.hotspotLeft(
                            iconSize: iconSize,
                            maxWidth: constraints.maxWidth,
                          ),
                          bottom: 0,
                          child: _translateHotspot(context, selection),
                        ),
                      ],
                    ),
                  )
                : SizedBox(
                    width: constraints.maxWidth,
                    height: metrics.visualHeight,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        _LookupParagraphText(
                          key: Key('reader-paragraph-${paragraph.index}'),
                          text: paragraph.displayText,
                          style: textStyle,
                          furiganaEnabled: furiganaEnabled,
                          furiganaGenerator: furiganaGenerator,
                          onBlankTap: onBlankTap,
                          onLookupText: onLookup == null
                              ? null
                              : (selectedText) =>
                                    onLookup!(_lookupSelection(selectedText)),
                        ),
                        Positioned(
                          left: hotspotOffset.dx,
                          top: hotspotOffset.dy,
                          child: _translateHotspot(context, selection),
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
        if (translationState == null) SizedBox(height: paragraphSpacing),
      ],
    );
  }

  ReaderTextSelection _lookupSelection(String selectedText) {
    return ReaderTextSelection(
      selectedText: selectedText,
      paragraphContext: paragraph.text,
    );
  }

  Widget _translateHotspot(BuildContext context, ParagraphSelection selection) {
    final iconSize = (fontSize * 0.78).clamp(14.0, 20.0);
    final hitSize = math.max(24.0, iconSize + 4);
    return GestureDetector(
      key: Key('paragraph-translate-hotspot-${paragraph.index}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTranslateParagraph == null
          ? null
          : () => onTranslateParagraph!(selection),
      child: SizedBox.square(
        dimension: hitSize,
        child: Icon(
          Icons.add_circle_outline,
          size: iconSize,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.18),
        ),
      ),
    );
  }
}

class _Paragraph {
  const _Paragraph({required this.index, required this.text, int? sourceIndex})
    : sourceIndex = sourceIndex ?? index;

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

_ParagraphTextMetrics _measureParagraphTextMetrics({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required TextDirection textDirection,
  required bool furiganaEnabled,
}) {
  final textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: textDirection,
    maxLines: null,
  )..layout(maxWidth: maxWidth);
  final lines = textPainter.computeLineMetrics();
  if (lines.isEmpty) {
    final fontSize = style.fontSize ?? 16;
    return _ParagraphTextMetrics(
      visualHeight: fontSize,
      lastLineEndX: 0,
      bodyCenterY: fontSize / 2,
    );
  }

  final fontSize = style.fontSize ?? 16;
  if (!furiganaEnabled) {
    final lastLine = lines.last;
    final bodyTop = lastLine.baseline - lastLine.ascent;
    return _ParagraphTextMetrics(
      visualHeight: textPainter.height,
      lastLineEndX: lastLine.left + lastLine.width,
      bodyCenterY: bodyTop + (lastLine.ascent + lastLine.descent) / 2,
    );
  }

  final rubyFontSize = fontSize * 0.48;
  final textLineHeight = fontSize * (style.height ?? 1.0);
  final lastLine = lines.last;
  final visualHeight = _estimateFuriganaVisualHeight(
    text: text,
    maxWidth: maxWidth,
    fontSize: fontSize,
    rubyFontSize: rubyFontSize,
    textLineHeight: textLineHeight,
  );
  final bodyTop = lastLine.baseline - lastLine.ascent;
  return _ParagraphTextMetrics(
    visualHeight: visualHeight,
    lastLineEndX: lastLine.left + lastLine.width,
    bodyCenterY: bodyTop + (lastLine.ascent + lastLine.descent) / 2,
  );
}

double _estimateFuriganaVisualHeight({
  required String text,
  required double maxWidth,
  required double fontSize,
  required double rubyFontSize,
  required double textLineHeight,
}) {
  final visibleRuneCount = text.runes
      .where((rune) => String.fromCharCode(rune).trim().isNotEmpty)
      .length;
  final estimatedUnitWidth = fontSize * 1.55 + 4;
  final estimatedCharsPerLine = math.max(
    1,
    (maxWidth / estimatedUnitWidth).floor(),
  );
  final estimatedLineCount = math.max(
    1,
    (visibleRuneCount / estimatedCharsPerLine).ceil(),
  );
  final hitSize = math.max(24.0, (fontSize * 0.78).clamp(14.0, 20.0) + 4);
  return estimatedLineCount * (rubyFontSize + textLineHeight + 16) + hitSize;
}

class _ParagraphTextMetrics {
  const _ParagraphTextMetrics({
    required this.visualHeight,
    required this.lastLineEndX,
    required this.bodyCenterY,
  });

  final double visualHeight;
  final double lastLineEndX;
  final double bodyCenterY;

  double hotspotLeft({required double iconSize, required double maxWidth}) {
    final hitSize = math.max(24.0, iconSize + 4);
    return (lastLineEndX + 3)
        .clamp(0.0, math.max(0.0, maxWidth - hitSize))
        .toDouble();
  }

  Offset hotspotOffset({required double iconSize, required double maxWidth}) {
    final hitSize = math.max(24.0, iconSize + 4);
    final left = hotspotLeft(iconSize: iconSize, maxWidth: maxWidth);
    final top = (bodyCenterY - hitSize / 2).clamp(
      0.0,
      math.max(0.0, visualHeight - hitSize),
    );
    return Offset(left, top.toDouble());
  }
}

class _LookupParagraphText extends StatefulWidget {
  const _LookupParagraphText({
    super.key,
    required this.text,
    required this.style,
    required this.furiganaEnabled,
    this.furiganaGenerator,
    required this.onBlankTap,
    required this.onLookupText,
  });

  final String text;
  final TextStyle style;
  final bool furiganaEnabled;
  final FuriganaGenerator? furiganaGenerator;
  final VoidCallback? onBlankTap;
  final ValueChanged<String>? onLookupText;

  @override
  State<_LookupParagraphText> createState() => _LookupParagraphTextState();
}

class _LookupParagraphTextState extends State<_LookupParagraphText> {
  int? _selectionStart;
  int? _selectionEnd;
  Future<List<FuriganaSegment>>? _furiganaFuture;
  String? _furiganaText;

  @override
  void initState() {
    super.initState();
    _syncFuriganaFuture();
  }

  @override
  void didUpdateWidget(covariant _LookupParagraphText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.furiganaEnabled != widget.furiganaEnabled ||
        oldWidget.furiganaGenerator != widget.furiganaGenerator) {
      _syncFuriganaFuture();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTapUp: widget.onLookupText == null
              ? null
              : (details) => _lookupAt(
                  context: context,
                  maxWidth: constraints.maxWidth,
                  localPosition: details.localPosition,
                ),
          onLongPressStart: widget.onLookupText == null
              ? null
              : (details) {
                  final offset = _textOffsetAt(
                    context: context,
                    maxWidth: constraints.maxWidth,
                    localPosition: details.localPosition,
                  );
                  setState(() {
                    _selectionStart = offset;
                    _selectionEnd = offset;
                  });
                },
          onLongPressMoveUpdate: widget.onLookupText == null
              ? null
              : (details) {
                  final offset = _textOffsetAt(
                    context: context,
                    maxWidth: constraints.maxWidth,
                    localPosition: details.localPosition,
                  );
                  setState(() => _selectionEnd = offset);
                },
          onLongPressEnd: widget.onLookupText == null
              ? null
              : (_) => _lookupSelectedText(),
          child: _buildText(context),
        );
      },
    );
  }

  void _syncFuriganaFuture() {
    if (!widget.furiganaEnabled) {
      _furiganaText = null;
      _furiganaFuture = null;
      return;
    }

    _furiganaText = widget.text;
    _furiganaFuture =
        (widget.furiganaGenerator ?? const LocalFuriganaGenerator().generate)(
          widget.text,
        );
  }

  Widget _buildText(BuildContext context) {
    if (!widget.furiganaEnabled || _normalizedSelection() != null) {
      return _buildPlainText(context);
    }

    final future = _furiganaFuture;
    if (future == null || _furiganaText != widget.text) {
      return _buildPlainText(context);
    }

    return FutureBuilder<List<FuriganaSegment>>(
      future: future,
      builder: (context, snapshot) {
        final segments = snapshot.data;
        if (segments == null) {
          return _buildPlainText(context);
        }
        return RubyText(
          _rubyWords(segments),
          key: const Key('reader-ruby-text'),
          spacing: 0,
          style: widget.style,
          rubyStyle: widget.style.copyWith(
            fontSize: widget.style.fontSize == null
                ? null
                : widget.style.fontSize! * 0.48,
            height: 1.0,
            color: widget.style.color?.withValues(alpha: 0.72),
          ),
          textDirection: Directionality.of(context),
          softWrap: true,
          autoLetterSpacing: true,
        );
      },
    );
  }

  Widget _buildPlainText(BuildContext context) {
    if (_normalizedSelection() == null) {
      return Text(widget.text, style: widget.style);
    }
    return RichText(text: _textSpan(context));
  }

  List<RubyTextWord> _rubyWords(List<FuriganaSegment> segments) {
    return [
      for (final segment in segments)
        if (segment.reading == null)
          for (final rune in segment.text.runes)
            RubyTextWord(String.fromCharCode(rune))
        else
          RubyTextWord(segment.text, ruby: segment.reading),
    ];
  }

  TextSpan _textSpan(BuildContext context) {
    final selection = _normalizedSelection();
    if (selection == null) {
      return TextSpan(text: widget.text, style: widget.style);
    }

    final start = selection.$1;
    final end = selection.$2;
    final selectedStyle = widget.style.copyWith(
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.18),
    );
    return TextSpan(
      style: widget.style,
      children: [
        TextSpan(text: widget.text.substring(0, start)),
        TextSpan(text: widget.text.substring(start, end), style: selectedStyle),
        TextSpan(text: widget.text.substring(end)),
      ],
    );
  }

  (int, int)? _normalizedSelection() {
    final start = _selectionStart;
    final end = _selectionEnd;
    if (start == null || end == null || start == end) {
      return null;
    }
    final lower = math.min(start, end).clamp(0, widget.text.length).toInt();
    final upper = math.max(start, end).clamp(0, widget.text.length).toInt();
    if (lower == upper) {
      return null;
    }
    return (lower, upper);
  }

  void _lookupAt({
    required BuildContext context,
    required double maxWidth,
    required Offset localPosition,
  }) {
    final painter = _textPainter(context: context, maxWidth: maxWidth);
    final offset = painter.getPositionForOffset(localPosition).offset;
    final range = _tokenRangeAt(offset);
    if (range == null ||
        !_isInsideTokenBounds(
          painter,
          range,
          localPosition,
          horizontalOnly: widget.furiganaEnabled,
        )) {
      widget.onBlankTap?.call();
      return;
    }
    final token = widget.text.substring(range.$1, range.$2).trim();
    if (token.isNotEmpty) {
      widget.onLookupText!(token);
    }
  }

  void _lookupSelectedText() {
    final selection = _normalizedSelection();
    if (selection == null) {
      setState(() {
        _selectionStart = null;
        _selectionEnd = null;
      });
      return;
    }
    final text = widget.text.substring(selection.$1, selection.$2).trim();
    setState(() {
      _selectionStart = null;
      _selectionEnd = null;
    });
    if (text.isNotEmpty) {
      widget.onLookupText!(text);
    }
  }

  int _textOffsetAt({
    required BuildContext context,
    required double maxWidth,
    required Offset localPosition,
  }) {
    final painter = _textPainter(context: context, maxWidth: maxWidth);
    return painter.getPositionForOffset(localPosition).offset;
  }

  TextPainter _textPainter({
    required BuildContext context,
    required double maxWidth,
  }) {
    return TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      textDirection: Directionality.of(context),
      maxLines: null,
    )..layout(maxWidth: maxWidth);
  }

  (int, int)? _tokenRangeAt(int offset) {
    if (widget.text.trim().isEmpty) {
      return null;
    }
    final index = _nearestTokenIndex(offset);
    if (index == null) {
      return null;
    }
    final kind = _tokenKind(widget.text[index]);
    if (kind == _TokenKind.other) {
      return null;
    }

    var start = index;
    while (start > 0 && _tokenKind(widget.text[start - 1]) == kind) {
      start -= 1;
    }
    var end = index + 1;
    while (end < widget.text.length && _tokenKind(widget.text[end]) == kind) {
      end += 1;
    }
    return (start, end);
  }

  bool _isInsideTokenBounds(
    TextPainter painter,
    (int, int) range,
    Offset position, {
    bool horizontalOnly = false,
  }) {
    final boxes = painter.getBoxesForSelection(
      TextSelection(baseOffset: range.$1, extentOffset: range.$2),
    );
    if (horizontalOnly) {
      return boxes.any((box) {
        final rect = box.toRect().inflate(10);
        return position.dx >= rect.left && position.dx <= rect.right;
      });
    }
    return boxes.any((box) => box.toRect().inflate(8).contains(position));
  }

  int? _nearestTokenIndex(int offset) {
    final bounded = offset
        .clamp(0, math.max(0, widget.text.length - 1))
        .toInt();
    if (_tokenKind(widget.text[bounded]) != _TokenKind.other) {
      return bounded;
    }
    for (var distance = 1; distance <= 2; distance++) {
      final left = bounded - distance;
      if (left >= 0 && _tokenKind(widget.text[left]) != _TokenKind.other) {
        return left;
      }
      final right = bounded + distance;
      if (right < widget.text.length &&
          _tokenKind(widget.text[right]) != _TokenKind.other) {
        return right;
      }
    }
    return null;
  }

  _TokenKind _tokenKind(String char) {
    if (RegExp(
      r'[\p{Script=Hiragana}\p{Script=Katakana}]',
      unicode: true,
    ).hasMatch(char)) {
      return _TokenKind.kana;
    }
    if (RegExp(r'[\p{Script=Han}]', unicode: true).hasMatch(char)) {
      return _TokenKind.han;
    }
    if (RegExp(r'[A-Za-z0-9]').hasMatch(char)) {
      return _TokenKind.latin;
    }
    return _TokenKind.other;
  }
}

enum _TokenKind { kana, han, latin, other }

class _EpubImagePage extends StatelessWidget {
  const _EpubImagePage({
    required this.paragraphIndex,
    required this.imageUri,
    this.maxHeight,
  });

  final int paragraphIndex;
  final Uri imageUri;
  final double? maxHeight;

  @override
  Widget build(BuildContext context) {
    final height = math.max(1.0, math.min(520.0, (maxHeight ?? 544) - 24));
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        key: Key('epub-image-page-$paragraphIndex'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _openPreview(context),
        child: SizedBox(
          width: double.infinity,
          height: height,
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
