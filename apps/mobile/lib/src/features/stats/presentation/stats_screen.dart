import 'package:flutter/material.dart';

import '../domain/study_stats_summary.dart';
import 'stats_controller.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key, StatsController? controller})
    : _controller = controller;

  final StatsController? _controller;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  StatsController? _controller;
  Future<StatsController>? _controllerFuture;
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
      _controllerFuture = StatsController.local();
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
      return _StatsContent(controller: controller);
    }

    return FutureBuilder<StatsController>(
      future: _controllerFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _controller = snapshot.requireData;
          _controller!.load();
          return _StatsContent(controller: _controller!);
        }

        return const Scaffold(
          appBar: _StatsAppBar(),
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.controller});

  final StatsController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading &&
            controller.today == StudyStatsSummary.zero) {
          return const Scaffold(
            appBar: _StatsAppBar(),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: const _StatsAppBar(),
          body: RefreshIndicator(
            onRefresh: controller.load,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (controller.errorMessage != null)
                    _InlineError(message: controller.errorMessage!),
                  _SummarySection(title: 'Today', summary: controller.today),
                  const SizedBox(height: 16),
                  _SummarySection(
                    title: 'Last 7 days',
                    summary: controller.last7Days,
                  ),
                  const SizedBox(height: 16),
                  _SummarySection(
                    title: 'All time',
                    summary: controller.allTime,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StatsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StatsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Stats'));
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.title, required this.summary});

  final String title;
  final StudyStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      _Metric('Reading minutes', summary.readingMinutes),
      _Metric('Lookups', summary.lookupCount),
      _Metric('Paragraph translations', summary.paragraphTranslationCount),
      _Metric('Cards created', summary.cardsCreated),
      _Metric('Cards reviewed', summary.cardsReviewed),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final item in items)
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(item.label),
            trailing: Text(
              item.value.toString(),
              style: theme.textTheme.titleMedium,
            ),
          ),
      ],
    );
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

class _Metric {
  const _Metric(this.label, this.value);

  final String label;
  final int value;
}
