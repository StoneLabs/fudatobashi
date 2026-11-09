import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fudatobashi/db/database.dart';
import 'package:fudatobashi/state/db_shape.dart';
import 'package:sqlite3/sqlite3.dart' show OpenMode, sqlite3;

void main() {
  Future<List<String>> differences(AppDatabase db) async {
    try {
      await DbShape.check(db);
    } on DbShapeMismatch catch (e) {
      return e.differences;
    }
    return [];
  }

  test('a fresh database has the expected structure', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await differences(db), isEmpty);
    await db.close();
  });

  test('a dropped column is reported as missing', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('ALTER TABLE ikkiuchi_matches DROP COLUMN xp');
    expect(await differences(db), ['ikkiuchi_matches: missing column xp']);
    await db.close();
  });

  test('an extra column and a dropped table are reported', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('ALTER TABLE key_values ADD COLUMN stray TEXT');
    await db.customStatement('DROP TABLE teiichi_placings');
    expect(await differences(db), ['key_values: extra column stray', 'teiichi_placings: missing table']);
    expect(const DbShapeMismatch(['a: missing table']).toString(), contains('a: missing table'));
    await db.close();
  });

  test('a v2.3.0 install upgraded by the migrations has the expected structure', () async {
    final release = sqlite3.open('test/past_db/v2.3.0_fresh.sqlite', mode: OpenMode.readOnly);
    final sql = [
      for (final row in release.select("SELECT sql FROM sqlite_master WHERE sql IS NOT NULL AND name NOT LIKE 'sqlite_%' "
          'ORDER BY rowid'))
        row['sql'] as String,
    ];
    final version = release.userVersion;
    release.close();
    final db = AppDatabase(NativeDatabase.memory(setup: (raw) {
      for (final s in sql) {
        raw.execute(s);
      }
      raw.userVersion = version;
    }));
    expect(await differences(db), isEmpty);
    await db.close();
  });
}
