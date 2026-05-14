import 'package:flutter/material.dart';

import '../../study/domain/paragraph_selection.dart';
import '../../study/domain/reader_text_selection.dart';
import '../../study/presentation/lookup_bottom_sheet.dart';
import '../domain/reader_preferences.dart';
import 'reader_controller.dart';
import 'reading_text_view.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    this.bookId,
    this.onClose,
    ReaderController? controller,
  }) : _controller = controller;

  final String? bookId;
  final VoidCallback? onClose;
  final ReaderController? _controller;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  ReaderController? _controller;
  Future<ReaderController>? _controllerFuture;
  bool _ownsController = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    final controller = widget._controller;
    if (controller != null) {
      _controller = controller;
      controller.load();
    } else {
      final bookId = widget.bookId;
      if (bookId != null && bookId.isNotEmpty) {
        _ownsController = true;
        _controllerFuture = ReaderController.local(bookId);
      }
    }
  }

  @override
  void dispose() {
    _controller?.saveProgress();
    if (_ownsController) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return _ReaderContent(
        controller: controller,
        showControls: _showControls,
        onClose: widget.onClose,
        onToggleControls: () {
          setState(() => _showControls = !_showControls);
        },
      );
    }

    final controllerFuture = _controllerFuture;
    if (controllerFuture == null) {
      return const _ReaderNotFound();
    }

    return FutureBuilder<ReaderController>(
      future: controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _controller = snapshot.requireData;
          _controller!.load();
          return _ReaderContent(
            controller: _controller!,
            showControls: _showControls,
            onClose: widget.onClose,
            onToggleControls: () {
              setState(() => _showControls = !_showControls);
            },
          );
        }
        return const Scaffold(body: Center(child: Text('正在打开阅读器...')));
      },
    );
  }
}

class _ReaderContent extends StatefulWidget {
  const _ReaderContent({
    required this.controller,
    required this.showControls,
    required this.onClose,
    required this.onToggleControls,
  });

  final ReaderController controller;
  final bool showControls;
  final VoidCallback? onClose;
  final VoidCallback onToggleControls;

  @override
  State<_ReaderContent> createState() => _ReaderContentState();
}

class _ReaderContentState extends State<_ReaderContent> {
  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Center(child: Text('正在打开阅读器...'));
          }
          if (controller.notFound || controller.currentChapter == null) {
            return const _ReaderNotFound();
          }

          final chapter = controller.currentChapter!;
          final presentation = _ReaderPresentation.fromPreferences(
            controller.readerPreferences,
          );
          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  key: presentation.isNightMode
                      ? const Key('reader-night-mode-background')
                      : const Key('reader-reading-background'),
                  decoration: BoxDecoration(color: presentation.background),
                  child: Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: Theme.of(
                        context,
                      ).colorScheme.copyWith(onSurface: presentation.textColor),
                    ),
                    child: GestureDetector(
                      key: const Key('reader-tap-area'),
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onToggleControls,
                      child: SafeArea(
                        child: ReadingTextView(
                          text: chapter.content,
                          fontSize: controller.fontSize,
                          lineHeight: controller.readerPreferences.lineHeight,
                          paragraphSpacing:
                              controller.readerPreferences.paragraphSpacing,
                          padding: widget.showControls
                              ? const EdgeInsets.fromLTRB(24, 108, 24, 188)
                              : const EdgeInsets.fromLTRB(24, 44, 24, 56),
                          onLookup: (selection) {
                            _openLookup(context, controller, selection);
                          },
                          onBlankTap: widget.onToggleControls,
                          onTranslateParagraph: (selection) {
                            _translateParagraph(controller, selection);
                          },
                          translationStateFor: (selection) {
                            return controller.paragraphTranslationController
                                ?.stateFor(
                                  _selectionWithLocation(controller, selection),
                                );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.readerPreferences.eyeProtectionEnabled)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const Key('reader-eye-protection-overlay'),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDCA8).withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
              if (widget.showControls)
                _ReaderControls(
                  controller: controller,
                  onClose: widget.onClose,
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openLookup(
    BuildContext context,
    ReaderController controller,
    ReaderTextSelection selection,
  ) async {
    final lookupController = await controller.ensureLookupController();
    if (!context.mounted) {
      return;
    }
    await lookupController.lookup(selection);
    if (!context.mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => LookupBottomSheet(controller: lookupController),
    );
  }

  Future<void> _translateParagraph(
    ReaderController controller,
    ParagraphSelection selection,
  ) async {
    final translationController = await controller
        .ensureParagraphTranslationController();
    if (!mounted) {
      return;
    }
    final locatedSelection = _selectionWithLocation(controller, selection);
    setState(() {});
    await translationController.translate(locatedSelection);
    if (mounted) {
      setState(() {});
    }
  }

  ParagraphSelection _selectionWithLocation(
    ReaderController controller,
    ParagraphSelection selection,
  ) {
    return ParagraphSelection(
      selectedParagraphText: selection.selectedParagraphText,
      bookFingerprint: controller.book?.bookFingerprint,
      chapterIndex: controller.currentChapterIndex,
      paragraphIndex: selection.paragraphIndex,
    );
  }
}

class _ReaderControls extends StatelessWidget {
  const _ReaderControls({required this.controller, required this.onClose});

  final ReaderController controller;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final book = controller.book!;
    final chapter = controller.currentChapter!;
    final surface = Theme.of(context).colorScheme.surface;
    final chapterCount = controller.chapters.length;
    final sliderMax = chapterCount <= 1 ? 1.0 : (chapterCount - 1).toDouble();
    final currentSliderValue = controller.currentChapterIndex
        .clamp(0, sliderMax.toInt())
        .toDouble();
    final nightLabel = controller.readerPreferences.nightModeEnabled
        ? '日间'
        : '夜间';

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: surface,
            padding: const EdgeInsets.fromLTRB(4, 8, 16, 10),
            child: Row(
              children: [
                IconButton(
                  key: const Key('reader-close-button'),
                  tooltip: '返回书库',
                  onPressed: onClose,
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        book.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(chapter.title),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: controller.canGoPrevious
                          ? controller.previousChapter
                          : null,
                      child: const Text('上一章'),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Slider(
                            key: const Key('reader-chapter-progress-slider'),
                            min: 0,
                            max: sliderMax,
                            divisions: chapterCount > 1
                                ? chapterCount - 1
                                : null,
                            value: currentSliderValue,
                            label: controller.progressLabel,
                            onChanged: chapterCount > 1
                                ? (value) {
                                    controller.goToChapter(value.round());
                                  }
                                : null,
                          ),
                          Text(controller.progressLabel),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: controller.canGoNext
                          ? controller.nextChapter
                          : null,
                      child: const Text('下一章'),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      key: const Key('reader-directory-button'),
                      onPressed: () => _showDirectory(context),
                      icon: const Icon(Icons.format_list_bulleted),
                      label: const Text('目录'),
                    ),
                    TextButton.icon(
                      key: const Key('reader-night-toggle-button'),
                      onPressed: controller.toggleNightMode,
                      icon: Icon(
                        controller.readerPreferences.nightModeEnabled
                            ? Icons.wb_sunny_outlined
                            : Icons.nightlight_round,
                      ),
                      label: Text(nightLabel),
                    ),
                    TextButton.icon(
                      key: const Key('reader-settings-button'),
                      onPressed: () => _showSettings(context),
                      icon: const Icon(Icons.tune),
                      label: const Text('设置'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDirectory(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          key: const Key('reader-directory-sheet'),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: controller.chapters.length,
            itemBuilder: (context, index) {
              final chapter = controller.chapters[index];
              final isCurrent = index == controller.currentChapterIndex;
              return ListTile(
                selected: isCurrent,
                leading: Text('${index + 1}'),
                title: Text(chapter.title),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  await controller.goToChapter(index);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _showSettings(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ReaderSettingsSheet(controller: controller);
      },
    );
  }
}

class _ReaderSettingsSheet extends StatelessWidget {
  const _ReaderSettingsSheet({required this.controller});

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final preferences = controller.readerPreferences;
        return SafeArea(
          key: const Key('reader-settings-sheet'),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _SettingsTitle(
                  title: '亮度',
                  child: Slider(
                    key: const Key('reader-brightness-slider'),
                    value: preferences.brightness,
                    onChanged: null,
                  ),
                ),
                SwitchListTile(
                  key: const Key('reader-eye-protection-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: const Text('护眼模式'),
                  value: preferences.eyeProtectionEnabled,
                  onChanged: controller.setEyeProtectionEnabled,
                ),
                _SettingsTitle(
                  title: '字号',
                  child: Row(
                    children: [
                      IconButton(
                        key: const Key('reader-font-decrease-button'),
                        tooltip: '减小字号',
                        onPressed: controller.decreaseFontSize,
                        icon: const Icon(Icons.text_decrease),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(controller.fontSize.round().toString()),
                        ),
                      ),
                      IconButton(
                        key: const Key('reader-font-increase-button'),
                        tooltip: '增大字号',
                        onPressed: controller.increaseFontSize,
                        icon: const Icon(Icons.text_increase),
                      ),
                    ],
                  ),
                ),
                _SettingsTitle(
                  title: '背景',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _backgroundOptions)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: preferences.backgroundTheme == option.theme,
                          onSelected: (_) {
                            controller.setBackgroundTheme(option.theme);
                          },
                        ),
                    ],
                  ),
                ),
                _SettingsTitle(
                  title: '翻页',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in _pageTurnOptions)
                        ChoiceChip(
                          label: Text(option.label),
                          selected: preferences.pageTurnMode == option.mode,
                          onSelected: (_) {
                            controller.setPageTurnMode(option.mode);
                          },
                        ),
                    ],
                  ),
                ),
                _SettingsTitle(
                  title: '其他',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('行距'),
                      Slider(
                        key: const Key('reader-line-height-slider'),
                        min: ReaderController.minLineHeight,
                        max: ReaderController.maxLineHeight,
                        divisions: 6,
                        value: preferences.lineHeight,
                        onChanged: controller.setLineHeight,
                      ),
                      const Text('段距'),
                      Slider(
                        key: const Key('reader-paragraph-spacing-slider'),
                        min: ReaderController.minParagraphSpacing,
                        max: ReaderController.maxParagraphSpacing,
                        divisions: 6,
                        value: preferences.paragraphSpacing,
                        onChanged: controller.setParagraphSpacing,
                      ),
                    ],
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

class _SettingsTitle extends StatelessWidget {
  const _SettingsTitle({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _BackgroundOption {
  const _BackgroundOption(this.label, this.theme);

  final String label;
  final ReaderBackgroundTheme theme;
}

const _backgroundOptions = [
  _BackgroundOption('纸白', ReaderBackgroundTheme.paperWhite),
  _BackgroundOption('米色', ReaderBackgroundTheme.warmBeige),
  _BackgroundOption('护眼绿', ReaderBackgroundTheme.eyeCareGreen),
  _BackgroundOption('淡蓝', ReaderBackgroundTheme.lightBlue),
  _BackgroundOption('深灰', ReaderBackgroundTheme.darkGray),
  _BackgroundOption('纯黑', ReaderBackgroundTheme.pureBlack),
];

class _PageTurnOption {
  const _PageTurnOption(this.label, this.mode);

  final String label;
  final ReaderPageTurnMode mode;
}

const _pageTurnOptions = [
  _PageTurnOption('仿真', ReaderPageTurnMode.simulation),
  _PageTurnOption('覆盖', ReaderPageTurnMode.cover),
  _PageTurnOption('平移', ReaderPageTurnMode.slide),
  _PageTurnOption('上下', ReaderPageTurnMode.vertical),
  _PageTurnOption('无动画', ReaderPageTurnMode.none),
];

class _ReaderNotFound extends StatelessWidget {
  const _ReaderNotFound();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text('阅读器'), SizedBox(height: 8), Text('未找到本地书籍')],
          ),
        ),
      ),
    );
  }
}

class _ReaderPresentation {
  const _ReaderPresentation({
    required this.background,
    required this.textColor,
    required this.isNightMode,
  });

  final Color background;
  final Color textColor;
  final bool isNightMode;

  static _ReaderPresentation fromPreferences(ReaderPreferences preferences) {
    final background = switch (preferences.backgroundTheme) {
      ReaderBackgroundTheme.paperWhite => const Color(0xFFFAF7F0),
      ReaderBackgroundTheme.warmBeige => const Color(0xFFF3E4C8),
      ReaderBackgroundTheme.eyeCareGreen => const Color(0xFFDCE8D2),
      ReaderBackgroundTheme.lightBlue => const Color(0xFFDCE9F4),
      ReaderBackgroundTheme.darkGray => const Color(0xFF303030),
      ReaderBackgroundTheme.pureBlack => Colors.black,
    };
    final isDark =
        preferences.nightModeEnabled ||
        preferences.backgroundTheme == ReaderBackgroundTheme.darkGray ||
        preferences.backgroundTheme == ReaderBackgroundTheme.pureBlack;
    return _ReaderPresentation(
      background: background,
      textColor: isDark ? const Color(0xFFE6E1D8) : const Color(0xFF25211A),
      isNightMode: preferences.nightModeEnabled,
    );
  }
}
