import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sweatline/database.dart';
import 'package:sweatline/models.dart';

import 'test_database.dart';

/// The exact schema that shipped as version 1, frozen here so the upgrade
/// path from real v1 installs stays tested even as the live schema moves on.
Future<void> _createV1Schema(Database db) async {
  await db.execute('''
    CREATE TABLE sessions(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      date TEXT NOT NULL,
      day_key TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE exercise_logs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
      exercise_id TEXT NOT NULL,
      position INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE set_logs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      exercise_log_id INTEGER NOT NULL
        REFERENCES exercise_logs(id) ON DELETE CASCADE,
      weight_kg REAL NOT NULL,
      reps INTEGER NOT NULL,
      position INTEGER NOT NULL
    )
  ''');
  await db.execute('''
    CREATE TABLE meta(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX idx_exercise_logs_session ON exercise_logs(session_id)',
  );
  await db.execute(
    'CREATE INDEX idx_exercise_logs_exercise ON exercise_logs(exercise_id)',
  );
  await db.execute(
    'CREATE INDEX idx_set_logs_log ON set_logs(exercise_log_id)',
  );
}

void main() {
  setUpAll(initTestDatabase);

  test('a v1 database upgrades to v2 keeping its data', () async {
    final dir = await Directory.systemTemp.createTemp('sweatline_migration');
    final path = '${dir.path}/sweatline.db';
    addTearDown(() => dir.delete(recursive: true));

    // Build a real v1 database with data, exactly like a 1.x install.
    final v1 = await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => _createV1Schema(db),
        singleInstance: false,
      ),
    );
    await v1.insert('sessions', {
      'date': DateTime(2026, 7, 20, 18).toIso8601String(),
      'day_key': 'push',
    });
    await v1.insert('meta', {'key': 'unit', 'value': 'lb'});
    await v1.close();

    // Opening through the app runs the v1 -> v2 upgrade.
    final upgraded = await AppDatabase.open(path: path, singleInstance: false);

    // Old data survives.
    final sessions = await upgraded.loadSessions();
    expect(sessions.single.dayKey, 'push');
    expect(await upgraded.getMeta('unit'), 'lb');

    // The new table exists and works.
    expect(await upgraded.loadBodyWeights(), isEmpty);
    await upgraded.insertBodyWeight(
      BodyWeightEntry(date: DateTime(2026, 7, 22), weightKg: 82.5),
    );
    expect((await upgraded.loadBodyWeights()).single.weightKg, 82.5);
    await upgraded.close();
  });
}
