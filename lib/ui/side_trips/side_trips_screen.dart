import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../config/design.dart';
import '../../domain/side_trips.dart';
import '../../state/progress.dart';
import '../../state/scope.dart';
import '../run/run_launcher.dart';
import 'ankiren_free_sheet.dart';
import 'ankiren_rules_sheet.dart';
import 'dojo_scene.dart';
import 'side_trip_entry.dart';

/// The Side Trips tab (寄り道): the dojo scene ([DojoScene]) over 暗記練's
/// entry, its lettering ([SideTripHead]) breaking out over its panel and
/// button pair ([SideTripBody]). Everything it shows comes from the hub
/// ([SideTripsHub]).
///
/// The first time the tab shows 暗記練 open after showing it locked, its
/// torii opens with a snap; once, like the tab chains.
class SideTripsScreen extends StatefulWidget {
  const SideTripsScreen({super.key});

  @override
  State<SideTripsScreen> createState() => _SideTripsScreenState();
}

class _SideTripsScreenState extends State<SideTripsScreen> {
  /// Trips whose opening is being shown.
  final Set<SideTrip> _opening = {};
  bool _syncScheduled = false;

  /// While the tab is on screen: remembers the trips it shows locked, and
  /// starts showing the opening of any seen locked that have opened since.
  void _syncLatch(Progress progress, SideTripsHub hub) {
    if (!TickerMode.valuesOf(context).enabled) return;
    final seen = progress.sideTripsSeenLocked;
    final locked = [
      for (final e in hub.entries)
        if (!e.open) e.trip,
    ];
    final opened = [
      for (final t in seen)
        if (hub[t].open) t,
    ];
    if (_syncScheduled || (seen.containsAll(locked) && opened.isEmpty)) return;
    _syncScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      progress.noteSideTripsSeenLocked(locked);
      if (opened.isEmpty) return;
      progress.noteSideTripsOpened(opened);
      setState(() => _opening.addAll(opened));
    });
  }

  /// [entry]'s torii: padlocked until its opening has been shown.
  GateState _gate(Progress progress, SideTripEntry entry) {
    if (!entry.open || progress.sideTripsSeenLocked.contains(entry.trip)) return GateState.locked;
    return _opening.contains(entry.trip) ? GateState.opening : GateState.open;
  }

  @override
  Widget build(BuildContext context) {
    final progress = ProgressScope.of(context);
    final hub = progress.sideTripsHub();
    _syncLatch(progress, hub);
    final entry = hub[SideTrip.ankiren];
    // The scene ends on an ink edge, over the tab bar's floor.
    return ClipRect(
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.ink, width: Strokes.panel))),
        child: LayoutBuilder(builder: (context, box) {
          final side = math.max(Gaps.gutter, (box.maxWidth - SideTripsLayout.maxWidth) / 2);
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: _HubFrame(
                minScene: DojoSceneLayout.minHeight * box.maxWidth / DojoSceneLayout.width,
                padding: EdgeInsets.fromLTRB(side, 0, side, SideTripsLayout.bottomGap),
                overlap: SideTripsLayout.overlap,
                scene: DojoScene(
                  gate: _gate(progress, entry),
                  day: DateTime.now().day,
                  onOpened: () => setState(() => _opening.remove(entry.trip)),
                ),
                body: SideTripBody(
                  entry,
                  onRanked: () => startAnkirenRanked(context),
                  onFree: () => openAnkirenFree(context),
                  onRules: () => openAnkirenRules(context),
                ),
                head: SideTripHead(entry),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// The hub's layout: the entry ([head] hanging [overlap] over the top of
/// [body]) at the bottom inside [padding], and [scene] filling everything
/// above it, at least [minScene] tall. When the two need more height than
/// the hub is given, it grows (and the tab scrolls).
class _HubFrame extends MultiChildRenderObjectWidget {
  _HubFrame({
    required this.minScene,
    required this.padding,
    required this.overlap,
    required Widget scene,
    required Widget body,
    required Widget head,
  }) : super(children: [scene, body, head]);

  final double minScene;
  final EdgeInsets padding;
  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHubFrame(minScene: minScene, padding: padding, overlap: overlap);

  @override
  void updateRenderObject(BuildContext context, _RenderHubFrame renderObject) => renderObject
    ..minScene = minScene
    ..padding = padding
    ..overlap = overlap;
}

class _HubFrameParentData extends ContainerBoxParentData<RenderBox> {}

/// Paints the scene, then the body, then the head over both; hit tests the
/// other way round.
class _RenderHubFrame extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _HubFrameParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _HubFrameParentData> {
  _RenderHubFrame({required this._minScene, required this._padding, required this._overlap});

  double _minScene;
  set minScene(double v) {
    if (v == _minScene) return;
    _minScene = v;
    markNeedsLayout();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets v) {
    if (v == _padding) return;
    _padding = v;
    markNeedsLayout();
  }

  double _overlap;
  set overlap(double v) {
    if (v == _overlap) return;
    _overlap = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _HubFrameParentData) child.parentData = _HubFrameParentData();
  }

  @override
  void performLayout() {
    final scene = firstChild!;
    final body = childAfter(scene)!;
    final head = childAfter(body)!;
    final width = constraints.maxWidth;
    final entry = BoxConstraints.tightFor(width: math.max(0, width - _padding.horizontal));
    body.layout(entry, parentUsesSize: true);
    head.layout(entry, parentUsesSize: true);
    final entryHeight = head.size.height - _overlap + body.size.height + _padding.bottom;
    final height = math.max(constraints.minHeight, _minScene + entryHeight);
    final top = height - entryHeight;
    scene.layout(BoxConstraints.tight(Size(width, top)));
    (head.parentData! as _HubFrameParentData).offset = Offset(_padding.left, top);
    (body.parentData! as _HubFrameParentData).offset = Offset(_padding.left, top + head.size.height - _overlap);
    size = constraints.constrain(Size(width, height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
