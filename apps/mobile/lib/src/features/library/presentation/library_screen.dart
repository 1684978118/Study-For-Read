import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/local_book.dart';
import 'library_controller.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({
    super.key,
    LibraryController? controller,
    Future<LibraryController> Function()? controllerFactory,
  }) : _controller = controller,
       _controllerFactory = controllerFactory;

  final LibraryController? _controller;
  final Future<LibraryController> Function()? _controllerFactory;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryController? _controller;
  Future<LibraryController>? _controllerFuture;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    final controller = widget._controller;
    if (controller != null) {
      _controller = controller;
      controller.load();
    } else {
      _ownsController = true;
      _controllerFuture = _createLocalController();
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller != null) {
      return _LibraryContent(controller: controller);
    }

    return FutureBuilder<LibraryController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _controller = snapshot.requireData;
          _controller!.load();
          return _LibraryContent(controller: _controller!);
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: const _LibraryAppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('无法打开本地书库。'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {
                      setState(() {
                        _controllerFuture = _createLocalController();
                      });
                    },
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          appBar: _LibraryAppBar(),
          body: Center(child: Text('正在加载书库...')),
        );
      },
    );
  }

  Future<LibraryController> _createLocalController() {
    final controllerFactory =
        widget._controllerFactory ?? LibraryController.local;
    return controllerFactory();
  }
}

class _LibraryContent extends StatelessWidget {
  const _LibraryContent({required this.controller});

  final LibraryController controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _LibraryAppBar(),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          if (controller.isLoading && controller.books.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: controller.load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (controller.errorMessage != null)
                  _InlineError(message: controller.errorMessage!),
                if (controller.books.isEmpty)
                  _EmptyLibrary(
                    isImporting: controller.isImporting,
                    onImport: controller.importBook,
                  )
                else ...[
                  _ImportToolbar(
                    isImporting: controller.isImporting,
                    onImport: controller.importBook,
                  ),
                  const SizedBox(height: 12),
                  for (final book in controller.books)
                    _BookListItem(
                      book: book,
                      onTap: () =>
                          context.go('/reader/${Uri.encodeComponent(book.id)}'),
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LibraryAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LibraryAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('书库'));
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.isImporting, required this.onImport});

  final bool isImporting;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.menu_book_outlined,
                size: 56,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 18),
              Text(
                '还没有本地书籍',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                '书籍只保存在这台设备上，离线也可以阅读。',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: isImporting ? null : onImport,
                icon: isImporting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload_file),
                label: const Text('导入 TXT 或 EPUB'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportToolbar extends StatelessWidget {
  const _ImportToolbar({required this.isImporting, required this.onImport});

  final bool isImporting;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            '本地书库',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        FilledButton.icon(
          onPressed: isImporting ? null : onImport,
          icon: const Icon(Icons.upload_file),
          label: const Text('导入 TXT 或 EPUB'),
        ),
      ],
    );
  }
}

class _BookListItem extends StatelessWidget {
  const _BookListItem({required this.book, required this.onTap});

  final LocalBook book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final author = book.author;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      title: Text(book.title),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 10,
          runSpacing: 4,
          children: [
            if (author != null && author.isNotEmpty) Text(author),
            Text(book.fileType.toUpperCase()),
            Text(_syncStatusLabel(book.metadataSyncStatus)),
          ],
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  static String _syncStatusLabel(String status) {
    return switch (status) {
      'synced' => '已同步',
      'dirty' => '待同步',
      'failed' => '同步失败',
      _ => '仅本地',
    };
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}
