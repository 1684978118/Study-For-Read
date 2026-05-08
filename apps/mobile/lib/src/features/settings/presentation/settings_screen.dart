import 'package:flutter/material.dart';

import '../../vocabulary/presentation/anki_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: const Text('Export to Anki'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AnkiExportScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
