import 'package:flutter/widgets.dart';

import '../../config/design.dart';

enum MangaTransition {
  /// A page turns in from the right (screens reached from a screen).
  page,

  /// The page zooms up into place (runs and other full-screen moments).
  zoom,
}

/// A full-screen route with the app's transitions.
class MangaRoute<T> extends PageRoute<T> {
  MangaRoute({required this.builder, this.transition = MangaTransition.page, super.settings});

  final WidgetBuilder builder;
  final MangaTransition transition;

  @override
  Duration get transitionDuration => Motion.route;

  @override
  Duration get reverseTransitionDuration => Motion.routeReverse;

  @override
  bool get opaque => true;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final t = CurvedAnimation(parent: animation, curve: Motion.routeCurve, reverseCurve: Motion.routeCurve.flipped);
    final out = CurvedAnimation(parent: secondaryAnimation, curve: Motion.routeCurve);
    final entering = switch (transition) {
      MangaTransition.page => SlideTransition(
          position: Tween(begin: const Offset(Motion.routeSlide, 0), end: Offset.zero).animate(t),
          child: FadeTransition(opacity: t, child: child),
        ),
      MangaTransition.zoom => ScaleTransition(
          scale: Tween(begin: Motion.routeZoom, end: 1.0).animate(t),
          child: FadeTransition(opacity: t, child: child),
        ),
    };
    return SlideTransition(
      position: Tween(begin: Offset.zero, end: const Offset(-Motion.routeSlide / 2, 0)).animate(out),
      child: entering,
    );
  }
}

/// Slides a sheet up from the bottom over the screen, dimmed by
/// [barrierColor]; a tap on the dim ([barrierLabel] to screen readers)
/// closes it.
Future<T?> showMangaSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  required Color barrierColor,
  required String barrierLabel,
}) =>
    showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: barrierLabel,
      barrierColor: barrierColor,
      transitionDuration: Motion.sheet,
      pageBuilder: (context, _, _) => builder(context),
      transitionBuilder: (context, animation, _, child) => SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: animation, curve: Motion.routeCurve)),
        child: child,
      ),
    );
