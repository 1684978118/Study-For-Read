enum ReaderBackgroundTheme {
  paperWhite('paper_white'),
  warmBeige('warm_beige'),
  eyeCareGreen('eye_care_green'),
  lightBlue('light_blue'),
  darkGray('dark_gray'),
  pureBlack('pure_black');

  const ReaderBackgroundTheme(this.storageValue);

  final String storageValue;

  static ReaderBackgroundTheme fromStorageValue(String value) {
    return values.firstWhere(
      (theme) => theme.storageValue == value,
      orElse: () => ReaderBackgroundTheme.paperWhite,
    );
  }
}

enum ReaderPageTurnMode {
  simulation('simulation'),
  cover('cover'),
  slide('slide'),
  vertical('vertical'),
  none('none');

  const ReaderPageTurnMode(this.storageValue);

  final String storageValue;

  static ReaderPageTurnMode fromStorageValue(String value) {
    return values.firstWhere(
      (mode) => mode.storageValue == value,
      orElse: () => ReaderPageTurnMode.slide,
    );
  }
}

class ReaderPreferences {
  const ReaderPreferences({
    required this.fontSize,
    required this.lineHeight,
    required this.paragraphSpacing,
    required this.backgroundTheme,
    required this.nightModeEnabled,
    required this.previousBackgroundTheme,
    required this.brightness,
    required this.eyeProtectionEnabled,
    required this.pageTurnMode,
    required this.volumeKeyPagingEnabled,
  });

  static const defaults = ReaderPreferences(
    fontSize: 20,
    lineHeight: 1.72,
    paragraphSpacing: 18,
    backgroundTheme: ReaderBackgroundTheme.paperWhite,
    nightModeEnabled: false,
    previousBackgroundTheme: ReaderBackgroundTheme.paperWhite,
    brightness: 1.0,
    eyeProtectionEnabled: false,
    pageTurnMode: ReaderPageTurnMode.slide,
    volumeKeyPagingEnabled: false,
  );

  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final ReaderBackgroundTheme backgroundTheme;
  final bool nightModeEnabled;
  final ReaderBackgroundTheme previousBackgroundTheme;
  final double brightness;
  final bool eyeProtectionEnabled;
  final ReaderPageTurnMode pageTurnMode;
  final bool volumeKeyPagingEnabled;

  ReaderPreferences copyWith({
    double? fontSize,
    double? lineHeight,
    double? paragraphSpacing,
    ReaderBackgroundTheme? backgroundTheme,
    bool? nightModeEnabled,
    ReaderBackgroundTheme? previousBackgroundTheme,
    double? brightness,
    bool? eyeProtectionEnabled,
    ReaderPageTurnMode? pageTurnMode,
    bool? volumeKeyPagingEnabled,
  }) {
    return ReaderPreferences(
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      backgroundTheme: backgroundTheme ?? this.backgroundTheme,
      nightModeEnabled: nightModeEnabled ?? this.nightModeEnabled,
      previousBackgroundTheme:
          previousBackgroundTheme ?? this.previousBackgroundTheme,
      brightness: brightness ?? this.brightness,
      eyeProtectionEnabled:
          eyeProtectionEnabled ?? this.eyeProtectionEnabled,
      pageTurnMode: pageTurnMode ?? this.pageTurnMode,
      volumeKeyPagingEnabled:
          volumeKeyPagingEnabled ?? this.volumeKeyPagingEnabled,
    );
  }
}
