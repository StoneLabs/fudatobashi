import '../state/backups.dart';
import 'history_strings.dart';
import 'strings.dart';

/// Strings of backup and restore (Settings › Data) and the recovery screen.
extension DataStrings on S {
  String get backUpData => t('backUpData');
  String get backUpDataNote => t('backUpDataNote');
  String get backupSaved => t('backupSaved');
  String get backupSaveFailed => t('backupSaveFailed');
  String get restoreBackup => t('restoreBackup');
  String get restoreBackupNote => t('restoreBackupNote');
  String get restoreChooseFile => t('restoreChooseFile');
  String get restoreChooseFileNote => t('restoreChooseFileNote');
  String get restoreCopies => t('restoreCopies');
  String restoreCopiesNote(int kept) => f('restoreCopiesNote', [kept]);
  String get restoreDone => t('restoreDone');
  String get restoreProblemTitle => t('restoreProblemTitle');
  String get restoreOpenFailed => t('restoreOpenFailed');
  String get restoreWarningTitle => t('restoreWarningTitle');
  String get restoreWarningBody => t('restoreWarningBody');
  String restoreWarningHold(int seconds) => f('restoreWarningHold', [seconds]);

  String restoreProblem(BackupProblem problem) => switch (problem) {
        BackupProblem.notBackup => t('restoreNotBackup'),
        BackupProblem.damaged => t('restoreDamaged'),
        BackupProblem.tooNew => t('restoreTooNew'),
      };

  /// A copy in the backups folder: when and why it was made.
  String copyDate(BackupCopy copy) => sessionDate(copy.at);
  String copyKind(CopyKind kind) => switch (kind) {
        CopyKind.update => t('copyKindUpdate'),
        CopyKind.restore => t('copyKindRestore'),
        CopyKind.setAside => t('copyKindSetAside'),
      };

  String get recoveryTitle => t('recoveryTitle');
  String get recoveryBody => t('recoveryBody');
  String get recoverySave => t('recoverySave');
  String get recoverySaveNote => t('recoverySaveNote');
  String get recoveryRestoreNote => t('recoveryRestoreNote');
  String get startFresh => t('startFresh');
  String get startFreshNote => t('startFreshNote');
  String get startFreshWarningTitle => t('startFreshWarningTitle');
  String get startFreshWarningBody => t('startFreshWarningBody');
  String startFreshWarningHold(int seconds) => f('startFreshWarningHold', [seconds]);
  String get errorDetails => t('errorDetails');
  String get copyText => t('copyText');
  String get copiedText => t('copiedText');
}
