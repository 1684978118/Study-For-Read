import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:study_for_read_mobile/src/features/settings/presentation/settings_screen.dart';
import 'package:study_for_read_mobile/src/features/vocabulary/presentation/anki_export_screen.dart';

void main() {
  testWidgets('Settings screen shows first-release acceptance sections', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('账号与语言'), findsOneWidget);
    expect(find.text('日语到中文'), findsOneWidget);
    expect(find.text('阅读偏好'), findsOneWidget);
    expect(find.text('阅读器内可调字体大小'), findsOneWidget);
    expect(find.text('同步与隐私'), findsOneWidget);
    expect(find.text('本地书籍只保存在这台设备上'), findsOneWidget);
    expect(find.text('同步只发送元数据'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('导出到 Anki'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('导出到 Anki'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('退出登录'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('退出登录'), findsOneWidget);
    expect(find.text('认证流程接入后可用'), findsOneWidget);
  });

  testWidgets('Settings export entry opens Anki export screen', (tester) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('导出到 Anki'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.ensureVisible(find.widgetWithText(ListTile, '导出到 Anki'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, '导出到 Anki'));
    await tester.pumpAndSettle();

    expect(find.byType(AnkiExportScreen), findsOneWidget);
    expect(find.text('导出范围'), findsOneWidget);
  });

  testWidgets('Settings sign out placeholder is disabled', (tester) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('退出登录'),
      180,
      scrollable: find.byType(Scrollable),
    );
    final signOutTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, '退出登录'),
    );

    expect(signOutTile.enabled, isFalse);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}

Widget _app(Widget child) {
  return MaterialApp(home: child);
}
