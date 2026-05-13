import 'package:flutter/material.dart';

import '../../vocabulary/presentation/anki_export_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SettingsSection(
            title: '账号与语言',
            children: [
              _SettingsInfoTile(
                icon: Icons.translate_outlined,
                title: '日语到中文',
                subtitle: '用于查词、段落翻译和词卡',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: '阅读偏好',
            children: [
              _SettingsInfoTile(
                icon: Icons.format_size,
                title: '阅读器内可调字体大小',
                subtitle: '轻点阅读页后，可使用阅读控制条调整',
              ),
              _SettingsInfoTile(
                icon: Icons.menu_book_outlined,
                title: '沉浸式阅读模式',
                subtitle: '阅读器会隐藏主底部导航',
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SettingsSection(
            title: '同步与隐私',
            children: [
              _SettingsInfoTile(
                icon: Icons.phone_android_outlined,
                title: '本地书籍只保存在这台设备上',
                subtitle: '不会上传原始文件和章节正文',
              ),
              _SettingsInfoTile(
                icon: Icons.sync_outlined,
                title: '同步只发送元数据',
                subtitle: '可排队同步进度、复习状态和计数',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SettingsSection(
            title: '导出',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('导出到 Anki'),
                subtitle: const Text('创建本地 UTF-8 TXT 导出文件'),
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
            title: '会话',
            children: [
              ListTile(
                enabled: false,
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.logout),
                title: Text('退出登录'),
                subtitle: Text('认证流程接入后可用'),
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
