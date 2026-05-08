import 'package:flutter/material.dart';

import 'lookup_controller.dart';

class LookupBottomSheet extends StatelessWidget {
  const LookupBottomSheet({
    super.key,
    required this.controller,
    this.onSave,
  });

  final LookupController controller;
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
                title: 'Looking up...',
                body: 'Searching the study dictionary.',
              ),
              LookupStatus.success => _LookupResultView(
                state: state,
                onSave: onSave,
              ),
              LookupStatus.notFound => _LookupMessage(
                title: 'Not found',
                body: state.message ?? 'No matching entry was found.',
              ),
              LookupStatus.offline => _LookupMessage(
                title: 'Offline',
                body: state.message ?? 'Lookup is unavailable offline.',
              ),
              LookupStatus.error => _LookupMessage(
                title: 'Lookup unavailable',
                body: state.message ?? 'Lookup failed.',
              ),
              LookupStatus.idle => const _LookupMessage(
                title: 'Lookup',
                body: 'Select text to look up.',
              ),
            },
          );
        },
      ),
    );
  }
}

class _LookupResultView extends StatelessWidget {
  const _LookupResultView({required this.state, required this.onSave});

  final LookupState state;
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
              tooltip: 'Pronounce',
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
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onSave,
            child: const Text('Save'),
          ),
        ),
      ],
    );
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
