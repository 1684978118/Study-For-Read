import 'package:flutter/material.dart';

import '../domain/lookup_result.dart';
import '../../vocabulary/presentation/save_vocabulary_controller.dart';
import 'lookup_controller.dart';

class LookupBottomSheet extends StatelessWidget {
  const LookupBottomSheet({
    super.key,
    required this.controller,
    this.saveController,
    this.sourceBookFingerprint,
    this.sourceBookTitle,
    this.onSave,
  });

  final LookupController controller;
  final SaveVocabularyController? saveController;
  final String? sourceBookFingerprint;
  final String? sourceBookTitle;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final state = controller.state;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: switch (state.status) {
              LookupStatus.loading => const _LookupMessage(
                title: '正在查词...',
                body: '正在查询学习词典。',
              ),
              LookupStatus.success => _LookupResultView(
                state: state,
                saveController: saveController,
                sourceBookFingerprint: sourceBookFingerprint,
                sourceBookTitle: sourceBookTitle,
                onSave: onSave,
              ),
              LookupStatus.notFound => _LookupMessage(
                title: '未找到',
                body: state.message ?? '没有找到匹配词条。',
              ),
              LookupStatus.offline => _LookupMessage(
                title: '离线',
                body: state.message ?? '离线状态下暂时无法查词。',
              ),
              LookupStatus.error => _LookupMessage(
                title: '查词不可用',
                body: state.message ?? '查词失败。',
              ),
              LookupStatus.idle => const _LookupMessage(
                title: '查词',
                body: '选择文本后可以查词。',
              ),
            },
          );
        },
      ),
    );
  }
}

class _LookupResultView extends StatelessWidget {
  const _LookupResultView({
    required this.state,
    required this.saveController,
    required this.sourceBookFingerprint,
    required this.sourceBookTitle,
    required this.onSave,
  });

  final LookupState state;
  final SaveVocabularyController? saveController;
  final String? sourceBookFingerprint;
  final String? sourceBookTitle;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final result = state.result!;
    final lexeme = result.lexeme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(lexeme.surface, style: textTheme.headlineSmall),
                  if (lexeme.reading != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      lexeme.reading!,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              tooltip: '发音',
              onPressed: () {},
              icon: const Icon(Icons.volume_up_outlined),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(lexeme.entryType),
        if (lexeme.shortDefinition != null) ...[
          const SizedBox(height: 12),
          Text(lexeme.shortDefinition!, style: textTheme.titleMedium),
        ],
        const SizedBox(height: 8),
        Text(lexeme.definition),
        const SizedBox(height: 16),
        _SaveButton(
          saveController: saveController,
          lexeme: lexeme,
          sourceBookFingerprint: sourceBookFingerprint,
          sourceBookTitle: sourceBookTitle,
          onSave: onSave,
        ),
      ],
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({
    required this.saveController,
    required this.lexeme,
    required this.sourceBookFingerprint,
    required this.sourceBookTitle,
    required this.onSave,
  });

  final SaveVocabularyController? saveController;
  final LookupLexeme lexeme;
  final String? sourceBookFingerprint;
  final String? sourceBookTitle;
  final VoidCallback? onSave;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  @override
  Widget build(BuildContext context) {
    final saveController = widget.saveController;
    if (saveController == null) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: widget.onSave,
          child: const Text('保存'),
        ),
      );
    }

    return AnimatedBuilder(
      animation: saveController,
      builder: (context, _) {
        final state = saveController.state;
        return SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: state.status == SaveVocabularyStatus.saving
                ? null
                : () async {
                    widget.onSave?.call();
                    await saveController.saveLookupLexeme(
                      widget.lexeme,
                      sourceBookFingerprint: widget.sourceBookFingerprint,
                      sourceBookTitle: widget.sourceBookTitle,
                    );
                  },
            child: Text(_labelFor(state)),
          ),
        );
      },
    );
  }

  String _labelFor(SaveVocabularyState state) {
    return switch (state.status) {
      SaveVocabularyStatus.saving => '正在保存...',
      SaveVocabularyStatus.saved ||
      SaveVocabularyStatus.localOnly ||
      SaveVocabularyStatus.alreadySaved => '已保存',
      SaveVocabularyStatus.error => '重试',
      SaveVocabularyStatus.idle => '保存',
    };
  }
}

class _LookupMessage extends StatelessWidget {
  const _LookupMessage({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body),
      ],
    );
  }
}
