import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'models.dart';

/// SQLite storage for Sweatline.
///
/// Session history is normalized across three tables so logging a workout is
/// a handful of row inserts, never a rewrite of the whole history. Singular
/// values (plan, in-progress draft, settings) live in a small key-value
/// `meta` table as JSON or plain strings.
///
/// The schema version is SQLite's own `PRAGMA user_version`; add an
/// `onUpgrade` branch when the schema changes.
class AppDatabase {
  AppDatabase(this._db);

  final Database _db;

  static const _schemaVersion = 1;

  /// Opens the app database. Pass [path] (e.g. `inMemoryDatabasePath`) in
  /// tests; production uses the default app databases directory.
  ///
  /// [singleInstance] must be false for isolated in-memory test databases:
  /// with the default caching, every open of `inMemoryDatabasePath` returns
  /// the same shared database and state leaks between tests.
  static Future<AppDatabase> open({
    String? path,
    bool singleInstance = true,
  }) async {
    final dbPath = path ?? p.join(await getDatabasesPath(), 'sweatline.db');
    final db = await databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: _schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _createSchema(db),
        singleInstance: singleInstance,
      ),
    );
    return AppDatabase(db);
  }

  static Future<void> _createSchema(Database db) async {
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

  // ----- meta key-value -----

  Future<String?> getMeta(String key) async {
    final rows = await _db.query(
      'meta',
      columns: ['value'],
      where: 'key = ?',
      whereArgs: [key],
    );
    return rows.isEmpty ? null : rows.first['value'] as String;
  }

  Future<void> setMeta(String key, String value) => _db.insert('meta', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> deleteMeta(String key) =>
      _db.delete('meta', where: 'key = ?', whereArgs: [key]);

  // ----- sessions -----

  /// All sessions, newest first, fully assembled with their logs and sets.
  Future<List<WorkoutSession>> loadSessions() async {
    final sessionRows = await _db.query('sessions', orderBy: 'date DESC');
    if (sessionRows.isEmpty) return [];

    final logRows = await _db.query('exercise_logs', orderBy: 'position ASC');
    final setRows = await _db.query('set_logs', orderBy: 'position ASC');

    final setsByLog = <int, List<SetLog>>{};
    for (final row in setRows) {
      (setsByLog[row['exercise_log_id'] as int] ??= []).add(
        SetLog(
          weightKg: (row['weight_kg'] as num).toDouble(),
          reps: row['reps'] as int,
        ),
      );
    }

    final logsBySession = <int, List<ExerciseLog>>{};
    for (final row in logRows) {
      (logsBySession[row['session_id'] as int] ??= []).add(
        ExerciseLog(
          exerciseId: row['exercise_id'] as String,
          sets: setsByLog[row['id'] as int] ?? const [],
        ),
      );
    }

    return [
      for (final row in sessionRows)
        WorkoutSession(
          date: DateTime.parse(row['date'] as String),
          dayKey: row['day_key'] as String,
          logs: logsBySession[row['id'] as int] ?? const [],
        ),
    ];
  }

  Future<void> insertSession(WorkoutSession session) =>
      _db.transaction((txn) => _insertSession(txn, session));

  static Future<void> _insertSession(
    DatabaseExecutor txn,
    WorkoutSession session,
  ) async {
    final sessionId = await txn.insert('sessions', {
      'date': session.date.toIso8601String(),
      'day_key': session.dayKey,
    });
    for (var i = 0; i < session.logs.length; i++) {
      final log = session.logs[i];
      final logId = await txn.insert('exercise_logs', {
        'session_id': sessionId,
        'exercise_id': log.exerciseId,
        'position': i,
      });
      for (var j = 0; j < log.sets.length; j++) {
        await txn.insert('set_logs', {
          'exercise_log_id': logId,
          'weight_kg': log.sets[j].weightKg,
          'reps': log.sets[j].reps,
          'position': j,
        });
      }
    }
  }

  /// Replaces the entire session history (used by backup restore).
  Future<void> replaceAllSessions(List<WorkoutSession> sessions) =>
      _db.transaction((txn) async {
        await txn.delete('sessions');
        for (final session in sessions) {
          await _insertSession(txn, session);
        }
      });

  Future<void> close() => _db.close();
}
