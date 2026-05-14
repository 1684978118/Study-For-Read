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
                  _TodayGlance(summary: controller.today),
                  const SizedBox(height: 20),
                  _SummarySection(title: '今天', summary: controller.today),
                  const SizedBox(height: 16),
                  _SummarySection(
                    title: '最近 7 天',
                    summary: controller.last7Days,
                  ),
                  const SizedBox(height: 16),
                  _SummarySection(title: '全部时间', summary: controller.allTime),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TodayGlance extends StatelessWidget {
  const _TodayGlance({required this.summary});

  final StudyStatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('今日概览', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _GlanceMetric(
                icon: Icons.schedule,
                value: '${summary.readingMinutes} 分钟',
                label: '阅读',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlanceMetric(
                icon: Icons.search,
                value: '${summary.lookupCount} 次查词',
                label: '查词',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GlanceMetric(
                icon: Icons.style_outlined,
                value: '${summary.cardsReviewed} 次复习',
                label: '复习',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlanceMetric extends StatelessWidget {
  const _GlanceMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      height: 144,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colorScheme.primary),
          const SizedBox(height: 14),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _StatsAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('统计'));
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
      _Metric('阅读分钟数', summary.readingMinutes),
      _Metric('查词次数', summary.lookupCount),
      _Metric('段落翻译次数', summary.paragraphTranslationCount),
      _Metric('创建词卡数', summary.cardsCreated),
      _Metric('复习词卡数', summary.cardsReviewed),
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
