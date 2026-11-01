import 'package:drift/drift.dart';

/// Schema 5 → 6: a 定位置 game with a time limit can end with cards still in
/// the stack, and keeps them too. Every card stored so far was placed.
Future<void> v5ToV6(Migrator m) => m.database.customStatement(
    'ALTER TABLE "teiichi_placings" ADD COLUMN "placed" INTEGER NOT NULL DEFAULT 1 CHECK ("placed" IN (0, 1))');
