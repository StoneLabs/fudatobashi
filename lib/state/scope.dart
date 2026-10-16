import 'package:flutter/widgets.dart';

import 'progress.dart';

/// Makes [Progress] available to the widget tree and rebuilds dependants when
/// it changes.
class ProgressScope extends InheritedNotifier<Progress> {
  const ProgressScope({super.key, required Progress progress, required super.child}) : super(notifier: progress);

  static Progress of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProgressScope>()!.notifier!;

  /// Reads without subscribing to changes.
  static Progress read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ProgressScope>()!.notifier!;
}
