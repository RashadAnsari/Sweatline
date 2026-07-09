import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sweatline/database.dart';
import 'package:sweatline/store.dart';

/// Points sqflite at the FFI implementation so tests run in the Dart VM
/// without a device. Call once from `setUpAll`.
///
/// Uses the no-isolate factory: the default [databaseFactoryFfi] runs SQLite
/// on a background isolate, which never gets pumped inside `testWidgets`'
/// fake-async zone, so the store's async DB writes would hang forever.
void initTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
}

/// A fresh, isolated in-memory database. Reuse the returned instance across
/// multiple [AppStore.open] calls to test persistence within one test.
/// `singleInstance: false` guarantees each call is its own database, so
/// state does not leak between tests.
Future<AppDatabase> openTestDatabase() =>
    AppDatabase.open(path: inMemoryDatabasePath, singleInstance: false);

/// A store over its own fresh in-memory database.
Future<AppStore> openTestStore() async =>
    AppStore.open(await openTestDatabase());
