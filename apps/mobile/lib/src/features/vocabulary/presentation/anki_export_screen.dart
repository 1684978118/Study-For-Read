import 'package:flutter/material.dart';

import '../export/anki_export_options.dart';
import '../export/anki_export_service.dart';

class AnkiExportScreen extends StatefulWidget {
  const AnkiExportScreen({
    super.key,
    AnkiExportService service = const AnkiExportService(),
    List<AnkiExportCard> allCards = const [],
    List<AnkiExportCard> dueCards = const [],
    List<AnkiExportCard> privateSentenceCards = const [],
  }) : _service = service,
       _allCards = allCards,
       _dueCards = dueCards,
       _privateSentenceCards = privateSentenceCards;

  final AnkiExportService _service;
  final List<AnkiExportCard> _allCards;
  final List<AnkiExportCard> _dueCards;
  final List<AnkiExportCard> _privateSentenceCards;

  @override
  State<AnkiExportScreen> createState() => _AnkiExportScreenState();
}

class _AnkiExportScreenState extends State<AnkiExportScreen> {
  AnkiExportScope _scope = AnkiExportScope.allCards;
  bool _includeExamples = true;
  bool _includeSourceMetadata = true;
  bool _isComplete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导出到 Anki')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('导出范围', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<AnkiExportScope>(
            segments: const [
              ButtonSegment(
                value: AnkiExportScope.allCards,
                label: Text('全部词卡'),
              ),
              ButtonSegment(
                value: AnkiExportScope.dueCards,
                label: Text('待复习词卡'),
              ),
              ButtonSegment(
                value: AnkiExportScope.privateSentenceCards,
                label: Text('私密例句卡'),
              ),
            ],
            selected: {_scope},
            onSelectionChanged: (values) => _setScope(values.single),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: _includeExamples,
            onChanged: (value) => setState(() => _includeExamples = value),
            title: const Text('包含例句'),
          ),
          SwitchListTile(
            value: _includeSourceMetadata,
            onChanged: (value) =>
                setState(() => _includeSourceMetadata = value),
            title: const Text('包含来源元数据'),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _export,
            icon: const Icon(Icons.file_download_outlined),
            label: const Text('导出 UTF-8 TXT'),
          ),
          if (_isComplete) ...[
            const SizedBox(height: 20),
            const _ExportCompleteMessage(),
          ],
        ],
      ),
    );
  }

  void _setScope(AnkiExportScope scope) {
    setState(() => _scope = scope);
  }

  void _export() {
    widget._service.exportText(
      cards: _cardsForScope(_scope),
      options: AnkiExportOptions(
        scope: _scope,
        includeExamples: _includeExamples,
        includeSourceMetadata: _includeSourceMetadata,
      ),
    );
    setState(() => _isComplete = true);
  }

  List<AnkiExportCard> _cardsForScope(AnkiExportScope scope) {
    return switch (scope) {
      AnkiExportScope.allCards => widget._allCards,
      AnkiExportScope.dueCards => widget._dueCards,
      AnkiExportScope.privateSentenceCards => widget._privateSentenceCards,
    };
  }
}

class _ExportCompleteMessage extends StatelessWidget {
  const _ExportCompleteMessage();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('导出已准备好'),
            SizedBox(height: 4),
            Text('StudyForRead-Anki.txt'),
          ],
        ),
      ),
    );
  }
}
