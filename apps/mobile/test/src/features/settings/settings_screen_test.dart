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

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Account & languages'), findsOneWidget);
    expect(find.text('Japanese to Chinese'), findsOneWidget);
    expect(find.text('Reading preferences'), findsOneWidget);
    expect(find.text('Font size adjustable in Reader'), findsOneWidget);
    expect(find.text('Sync & privacy'), findsOneWidget);
    expect(find.text('Local books stay on this device'), findsOneWidget);
    expect(find.text('Sync sends metadata only'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Export to Anki'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Export to Anki'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Sign out'),
      180,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('Available after auth wiring'), findsOneWidget);
  });

  testWidgets('Settings export entry opens Anki export screen', (tester) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Export to Anki'),
      180,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.text('Export to Anki'));
    await tester.pumpAndSettle();

    expect(find.byType(AnkiExportScreen), findsOneWidget);
    expect(find.text('Export range'), findsOneWidget);
  });

  testWidgets('Settings sign out placeholder is disabled', (tester) async {
    await tester.pumpWidget(_app(const SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Sign out'),
      180,
      scrollable: find.byType(Scrollable),
    );
    final signOutTile = tester.widget<ListTile>(
      find.widgetWithText(ListTile, 'Sign out'),
    );

    expect(signOutTile.enabled, isFalse);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });
}

Widget _app(Widget child) {
  return MaterialApp(home: child);
}
