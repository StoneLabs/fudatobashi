import '../db/database.dart';

/// The saved data's tables or columns differ from what the code expects.
/// [differences] has one line per difference.
class DbShapeMismatch implements Exception {
  const DbShapeMismatch(this.differences);

  final List<String> differences;

  @override
  String toString() => 'The saved data has the wrong structure:\n${differences.join('\n')}';
}

/// Checks on every start that the database has the tables and column names
/// the code expects. It only reads: it never repairs or migrates, so a
/// mismatch is reported instead of letting saves fail later.
abstract final class DbShape {
  /// Throws [DbShapeMismatch] when a table or column is missing or extra.
  static Future<void> check(AppDatabase db) async {
    final differences = <String>[];
    for (final table in db.allTables) {
      final name = table.actualTableName;
      final rows = await db.customSelect('PRAGMA table_info("$name")').get();
      if (rows.isEmpty) {
        differences.add('$name: missing table');
        continue;
      }
      final actual = {for (final r in rows) r.read<String>('name')};
      final expected = {for (final c in table.$columns) c.name};
      for (final c in expected.difference(actual)) {
        differences.add('$name: missing column $c');
      }
      for (final c in actual.difference(expected)) {
        differences.add('$name: extra column $c');
      }
    }
    if (differences.isNotEmpty) throw DbShapeMismatch(differences);
  }
}
