import 'package:flutter/material.dart';

import '../../vocabulary/presentation/anki_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SettingsSection(
            title: 'Account & languages',
            children: [
              _SettingsInfoTile(
                icon: Icons.translate_outlined,
                title: 'Japanese to Chinese',
                subtitle: 'Used by lookup, paragraph translation, and cards',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'Reading preferences',
            children: [
              _SettingsInfoTile(
                icon: Icons.format_size,
                title: 'Font size adjustable in Reader',
                subtitle: 'Tap the reading page, then use the Reader controls',
              ),
              _SettingsInfoTile(
                icon: Icons.menu_book_outlined,
                title: 'Immersive reading mode',
                subtitle: 'Reader opens without the main bottom navigation',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'Sync & privacy',
            children: [
              _SettingsInfoTile(
                icon: Icons.phone_android_outlined,
                title: 'Local books stay on this device',
                subtitle: 'Original files and chapter text are not uploaded',
              ),
              _SettingsInfoTile(
                icon: Icons.sync_outlined,
                title: 'Sync sends metadata only',
                subtitle: 'Progress, review state, and counters can be queued',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: 'Export',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('Export to Anki'),
                subtitle: const Text('Create a local UTF-8 TXT export'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AnkiExportScreen(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: 'Session',
            children: [
              ListTile(
                enabled: false,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout),
                title: Text('Sign out'),
                subtitle: Text('Available after auth wiring'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.42,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
