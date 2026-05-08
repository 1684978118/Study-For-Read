import 'package:flutter/material.dart';

import '../../study/domain/reader_text_selection.dart';
import '../../study/presentation/lookup_bottom_sheet.dart';
import 'reader_controller.dart';
import 'reading_text_view.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    this.bookId,
    ReaderController? controller,
  }) : _controller = controller;

  final String? bookId;
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
            onToggleControls: () {
              setState(() => _showControls = !_showControls);
            },
          );
        }
        return const Scaffold(body: Center(child: Text('Loading reader...')));
      },
    );
  }
}

class _ReaderContent extends StatelessWidget {
  const _ReaderContent({
    required this.controller,
    required this.showControls,
    required this.onToggleControls,
  });

  final ReaderController controller;
  final bool showControls;
  final VoidCallback onToggleControls;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading) {
            return const Center(child: Text('Loading reader...'));
          }
          if (controller.notFound || controller.currentChapter == null) {
            return const _ReaderNotFound();
          }

          final chapter = controller.currentChapter!;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  key: const Key('reader-tap-area'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggleControls,
                  child: SafeArea(
                    child: ReadingTextView(
                      text: chapter.content,
                      fontSize: controller.fontSize,
                      onLookup: (selection) {
                        _openLookup(context, controller, selection);
                      },
                    ),
                  ),
                ),
              ),
              if (showControls) _ReaderControls(controller: controller),
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
}

class _ReaderControls extends StatelessWidget {
  const _ReaderControls({required this.controller});

  final ReaderController controller;

  @override
  Widget build(BuildContext context) {
    final book = controller.book!;
    final chapter = controller.currentChapter!;
    final surface = Theme.of(context).colorScheme.surface.withValues(alpha: 0.94);

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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
          const Spacer(),
          Container(
            color: surface,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    TextButton(
                      onPressed: controller.canGoPrevious
                          ? controller.previousChapter
                          : null,
                      child: const Text('Previous'),
                    ),
                    Expanded(
                      child: Center(child: Text(controller.progressLabel)),
                    ),
                    TextButton(
                      onPressed: controller.canGoNext
                          ? controller.nextChapter
                          : null,
                      child: const Text('Next'),
                    ),
                  ],
                ),
                Slider(
                  key: const Key('reader-font-size-slider'),
                  min: ReaderController.minFontSize,
                  max: ReaderController.maxFontSize,
                  divisions: 6,
                  value: controller.fontSize,
                  label: controller.fontSize.round().toString(),
                  onChanged: controller.setFontSize,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReaderNotFound extends StatelessWidget {
  const _ReaderNotFound();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reader'),
              SizedBox(height: 8),
              Text('Local book not found'),
            ],
          ),
        ),
      ),
    );
  }
}
