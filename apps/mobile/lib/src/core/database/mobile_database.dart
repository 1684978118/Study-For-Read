import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import 'mobile_database_migrations.dart';

class MobileDatabase {
  MobileDatabase({sqflite.DatabaseFactory? databaseFactory, this.path})
    : _databaseFactory = databaseFactory ?? sqflite.databaseFactory;

  final sqflite.DatabaseFactory _databaseFactory;
  final String? path;

  sqflite.Database? _database;

  Future<sqflite.Database> open() async {
    final existingDatabase = _database;
    if (existingDatabase != null) {
      return existingDatabase;
    }

    final databasePath = path ?? await _defaultDatabasePath();
    final database = await _databaseFactory.openDatabase(
      databasePath,
      options: sqflite.OpenDatabaseOptions(
        version: MobileDatabaseMigrations.version,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      ),
    );
    _database = database;
    return database;
  }

  Future<void> close() async {
    final database = _database;
    _database = null;
    if (database != null && database.isOpen) {
      await database.close();
    }
  }

  Future<void> _onConfigure(sqflite.Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(sqflite.Database db, int version) async {
    await MobileDatabaseMigrations.create(db, version);
  }

  Future<String> _defaultDatabasePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, 'study_for_read_mobile.db');
  }
}
