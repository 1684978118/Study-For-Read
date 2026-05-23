import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:study_for_read_mobile/src/core/database/mobile_database.dart';
import 'package:study_for_read_mobile/src/features/reader/data/local_reader_preferences_repository.dart';
import 'package:study_for_read_mobile/src/features/reader/domain/reader_preferences.dart';

void main() {
  late MobileDatabase mobileDatabase;
  late LocalReaderPreferencesRepository repository;

  setUp(() async {
    sqfliteFfiInit();
    mobileDatabase = MobileDatabase(
      databaseFactory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = LocalReaderPreferencesRepository(await mobileDatabase.open());
  });

  tearDown(() async {
    await mobileDatabase.close();
  });

  test('returns default preferences when no row exists', () async {
    final preferences = await repository.load();

    expect(preferences.fontSize, ReaderPreferences.defaults.fontSize);
    expect(preferences.fontSize, 18);
    expect(preferences.lineHeight, 1.55);
    expect(preferences.paragraphSpacing, 10);
    expect(preferences.backgroundTheme, ReaderBackgroundTheme.paperWhite);
    expect(preferences.nightModeEnabled, isFalse);
    expect(preferences.previousBackgroundTheme, ReaderBackgroundTheme.paperWhite);
    expect(preferences.brightness, 1.0);
    expect(preferences.eyeProtectionEnabled, isFalse);
    expect(preferences.pageTurnMode, ReaderPageTurnMode.slide);
    expect(preferences.volumeKeyPagingEnabled, isFalse);
    expect(preferences.lookupTranslationEngine, TranslationEngine.localMachine);
    expect(preferences.paragraphTranslationEngine, TranslationEngine.ai);
    expect(preferences.localTranslationModelsReady, isFalse);
    expect(preferences.aiPrefetchPageCount, 3);
    expect(preferences.furiganaEnabled, isFalse);
  });

  test('persists and reloads global reader preferences', () async {
    final saved = ReaderPreferences.defaults.copyWith(
      fontSize: 24,
      lineHeight: 1.9,
      paragraphSpacing: 28,
      backgroundTheme: ReaderBackgroundTheme.eyeCareGreen,
      nightModeEnabled: true,
      previousBackgroundTheme: ReaderBackgroundTheme.warmBeige,
      brightness: 0.62,
      eyeProtectionEnabled: true,
      pageTurnMode: ReaderPageTurnMode.cover,
      volumeKeyPagingEnabled: true,
      lookupTranslationEngine: TranslationEngine.ai,
      paragraphTranslationEngine: TranslationEngine.localMachine,
      localTranslationModelsReady: true,
      aiPrefetchPageCount: 3,
      furiganaEnabled: true,
    );

    await repository.save(saved);
    final reloaded = await repository.load();

    expect(reloaded.fontSize, 24);
    expect(reloaded.lineHeight, 1.9);
    expect(reloaded.paragraphSpacing, 28);
    expect(reloaded.backgroundTheme, ReaderBackgroundTheme.eyeCareGreen);
    expect(reloaded.nightModeEnabled, isTrue);
    expect(reloaded.previousBackgroundTheme, ReaderBackgroundTheme.warmBeige);
    expect(reloaded.brightness, 0.62);
    expect(reloaded.eyeProtectionEnabled, isTrue);
    expect(reloaded.pageTurnMode, ReaderPageTurnMode.cover);
    expect(reloaded.volumeKeyPagingEnabled, isTrue);
    expect(reloaded.lookupTranslationEngine, TranslationEngine.ai);
    expect(reloaded.paragraphTranslationEngine, TranslationEngine.localMachine);
    expect(reloaded.localTranslationModelsReady, isTrue);
    expect(reloaded.aiPrefetchPageCount, 3);
    expect(reloaded.furiganaEnabled, isTrue);
  });
}
