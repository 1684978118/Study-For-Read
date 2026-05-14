import 'package:sqflite/sqflite.dart';

import '../domain/reader_preferences.dart';

abstract interface class ReaderPreferencesRepository {
  Future<ReaderPreferences> load();

  Future<void> save(ReaderPreferences preferences);
}

class LocalReaderPreferencesRepository implements ReaderPreferencesRepository {
  const LocalReaderPreferencesRepository(this._db);

  static const _table = 'local_reader_preferences';
  static const _globalId = 'global';

  final Database _db;

  @override
  Future<ReaderPreferences> load() async {
    final rows = await _db.query(
      _table,
      where: 'id = ?',
      whereArgs: const [_globalId],
      limit: 1,
    );
    if (rows.isEmpty) {
      return ReaderPreferences.defaults;
    }
    return _fromRow(rows.single);
  }

  @override
  Future<void> save(ReaderPreferences preferences) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final existingRows = await _db.query(
      _table,
      columns: const ['created_at'],
      where: 'id = ?',
      whereArgs: const [_globalId],
      limit: 1,
    );
    final createdAt = existingRows.isEmpty
        ? now
        : existingRows.single['created_at'] as String;

    await _db.insert(_table, {
      'id': _globalId,
      'font_size': preferences.fontSize,
      'line_height': preferences.lineHeight,
      'paragraph_spacing': preferences.paragraphSpacing,
      'background_theme': preferences.backgroundTheme.storageValue,
      'night_mode_enabled': _boolToInt(preferences.nightModeEnabled),
      'previous_background_theme':
          preferences.previousBackgroundTheme.storageValue,
      'brightness': preferences.brightness,
      'eye_protection_enabled': _boolToInt(preferences.eyeProtectionEnabled),
      'page_turn_mode': preferences.pageTurnMode.storageValue,
      'volume_key_paging_enabled':
          _boolToInt(preferences.volumeKeyPagingEnabled),
      'created_at': createdAt,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  ReaderPreferences _fromRow(Map<String, Object?> row) {
    return ReaderPreferences(
      fontSize: _asDouble(row['font_size']),
      lineHeight: _asDouble(row['line_height']),
      paragraphSpacing: _asDouble(row['paragraph_spacing']),
      backgroundTheme: ReaderBackgroundTheme.fromStorageValue(
        row['background_theme'] as String,
      ),
      nightModeEnabled: row['night_mode_enabled'] == 1,
      previousBackgroundTheme: ReaderBackgroundTheme.fromStorageValue(
        row['previous_background_theme'] as String,
      ),
      brightness: _asDouble(row['brightness']),
      eyeProtectionEnabled: row['eye_protection_enabled'] == 1,
      pageTurnMode: ReaderPageTurnMode.fromStorageValue(
        row['page_turn_mode'] as String,
      ),
      volumeKeyPagingEnabled: row['volume_key_paging_enabled'] == 1,
    );
  }

  double _asDouble(Object? value) {
    if (value is int) {
      return value.toDouble();
    }
    return value as double;
  }

  int _boolToInt(bool value) => value ? 1 : 0;
}
