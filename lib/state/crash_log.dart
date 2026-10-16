import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/config.dart';

/// Uncaught errors, appended to a small file on the device (newest last,
/// cut from the front past [CrashLogTuning.maxChars]). Developer mode shows
/// it; nothing ever sends it anywhere.
class CrashLog {
  CrashLog(this.file);

  final File file;

  /// The app's log, once [install] has run.
  static CrashLog? instance;

  Future<void> _writing = Future.value();

  /// Logs Flutter's and the platform's uncaught errors from now on.
  void install() {
    instance = this;
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      record(details.exception, details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('$error\n$stack');
      record(error, stack);
      return true;
    };
  }

  /// Appends [error] with the top of its [stack].
  Future<void> record(Object error, StackTrace? stack) => _writing = _writing.then((_) async {
        final lines = '${stack ?? ''}'.trimRight().split('\n').take(CrashLogTuning.stackLines).join('\n');
        final entry = '[${DateTime.now().toIso8601String()}] $error\n$lines\n\n';
        try {
          var text = (await file.exists() ? await file.readAsString() : '') + entry;
          if (text.length > CrashLogTuning.maxChars) text = text.substring(text.length - CrashLogTuning.maxChars);
          await file.parent.create(recursive: true);
          await file.writeAsString(text, flush: true);
        } catch (_) {}
      });

  Future<String> read() async {
    await _writing;
    return await file.exists() ? file.readAsString() : '';
  }

  Future<void> clear() => _writing = _writing.then((_) async {
        if (await file.exists()) await file.delete();
      });
}
