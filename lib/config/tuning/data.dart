part of '../config.dart';

/// The data file on disk (`DataStore`): its backups, the copies the app
/// makes of it on its own, and how long opening it may take at start.
abstract final class DataFileTuning {
  /// The database is `<name>.sqlite` in the app's documents folder.
  static const String databaseName = 'fudatobashi';
  static const String extension = '.sqlite';

  /// A backup's default file name is this, then `yyMMdd-HHmm` local time.
  static const String exportPrefix = 'fudatobashi_backup_';

  /// The app-private folder (in the app support folder) that holds the
  /// automatic copies and the files set aside.
  static const String backupsFolder = 'backups';

  /// Automatic copies (before an update, before a restore) kept; older ones
  /// are deleted. Files set aside after a failed start are never deleted.
  static const int keptCopies = 5;

  /// Opening and upgrading the data at start; longer counts as a failure.
  static const Duration openTimeout = Duration(seconds: 45);

  /// Letting go of data that failed to open; the file is moved on after it.
  static const Duration closeTimeout = Duration(seconds: 5);

  /// Developer mode's "Fail the next start" leaves this file in the app
  /// support folder; the next start removes it and fails on purpose.
  static const String failNextStartFile = 'fail_next_start';
}

/// The local crash log (`CrashLog`): uncaught errors, newest last. It never
/// leaves the device.
abstract final class CrashLogTuning {
  static const String fileName = 'crash_log.txt';

  /// The log is cut from the front to stay under this many characters.
  static const int maxChars = 64 * 1024;

  /// Lines of each error's stack trace kept.
  static const int stackLines = 30;
}
