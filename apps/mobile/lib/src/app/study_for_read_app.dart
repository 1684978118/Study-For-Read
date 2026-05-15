import 'package:flutter/material.dart';

import 'app_router.dart';
import 'app_theme.dart';

class StudyForReadApp extends StatelessWidget {
  const StudyForReadApp({
    super.key,
    this.isSignedIn = false,
    this.initialLocation = _defaultInitialLocation,
    this.enableAcceptanceReader = _acceptanceReaderEnabled,
  });

  static const bool _acceptanceReaderEnabled = bool.fromEnvironment(
    'ENABLE_ACCEPTANCE_READER',
  );
  static const String _defaultInitialLocation = _acceptanceReaderEnabled
      ? '/acceptance/reader'
      : '/';

  final bool isSignedIn;
  final String initialLocation;
  final bool enableAcceptanceReader;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Study For Read',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: createAppRouter(
        isSignedIn: isSignedIn,
        initialLocation: initialLocation,
        enableAcceptanceReader: enableAcceptanceReader,
      ),
    );
  }
}
