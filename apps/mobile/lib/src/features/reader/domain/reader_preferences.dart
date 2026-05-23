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

enum TranslationEngine {
  localMachine('local_machine'),
  ai('ai');

  const TranslationEngine(this.storageValue);

  final String storageValue;

  static TranslationEngine fromStorageValue(String value) {
    return values.firstWhere(
      (engine) => engine.storageValue == value,
      orElse: () => TranslationEngine.ai,
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
    required this.lookupTranslationEngine,
    required this.paragraphTranslationEngine,
    required this.localTranslationModelsReady,
    required this.aiPrefetchPageCount,
    required this.furiganaEnabled,
  });

  static const defaults = ReaderPreferences(
    fontSize: 18,
    lineHeight: 1.55,
    paragraphSpacing: 10,
    backgroundTheme: ReaderBackgroundTheme.paperWhite,
    nightModeEnabled: false,
    previousBackgroundTheme: ReaderBackgroundTheme.paperWhite,
    brightness: 1.0,
    eyeProtectionEnabled: false,
    pageTurnMode: ReaderPageTurnMode.slide,
    volumeKeyPagingEnabled: false,
    lookupTranslationEngine: TranslationEngine.localMachine,
    paragraphTranslationEngine: TranslationEngine.ai,
    localTranslationModelsReady: false,
    aiPrefetchPageCount: 3,
    furiganaEnabled: false,
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
  final TranslationEngine lookupTranslationEngine;
  final TranslationEngine paragraphTranslationEngine;
  final bool localTranslationModelsReady;
  final int aiPrefetchPageCount;
  final bool furiganaEnabled;

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
    TranslationEngine? lookupTranslationEngine,
    TranslationEngine? paragraphTranslationEngine,
    bool? localTranslationModelsReady,
    int? aiPrefetchPageCount,
    bool? furiganaEnabled,
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
      lookupTranslationEngine:
          lookupTranslationEngine ?? this.lookupTranslationEngine,
      paragraphTranslationEngine:
          paragraphTranslationEngine ?? this.paragraphTranslationEngine,
      localTranslationModelsReady:
          localTranslationModelsReady ?? this.localTranslationModelsReady,
      aiPrefetchPageCount: aiPrefetchPageCount ?? this.aiPrefetchPageCount,
      furiganaEnabled: furiganaEnabled ?? this.furiganaEnabled,
    );
  }
}
