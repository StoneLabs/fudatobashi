import 'dart:convert';

import '../domain/card_mask.dart';
import '../domain/play_session.dart';
import 'play_config.dart';

/// A run under way, saved after every change so that a run the app never
/// got to record (it was closed or killed mid-run) is recorded on the next
/// start with the swipes it had (see `Progress.journalRun`). The exam also
/// keeps Tobi's time.
class RunJournal {
  const RunJournal({required this.run, required this.config, required this.startedAt, this.tobi, this.tobiLine});

  final PlaySession run;
  final PlayConfig config;
  final DateTime startedAt;
  final Duration? tobi;
  final List<Duration>? tobiLine;

  /// When it last changed: its latest swipe, or its start.
  DateTime get lastAt => run.swipes.isEmpty ? startedAt : run.swipes.map((a) => a.at).reduce((a, b) => a.isAfter(b) ? a : b);

  String encode() => jsonEncode({
        'config': config.toJson(),
        'startedAt': startedAt.toIso8601String(),
        'cards': [for (final c in run.cards) _card(c)],
        'attempts': [for (final a in run.attempts) _attempt(a)],
        'undone': [for (final a in run.undone) _attempt(a)],
        'elapsedUs': run.elapsed.inMicroseconds,
        'tobiMs': tobi?.inMilliseconds,
        'tobiLine': tobiLine?.map((t) => t.inMilliseconds).toList(),
      });

  static RunJournal decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    List<Attempt> attempts(String key) => [for (final a in j[key] as List) _attemptOf(a as Map<String, dynamic>)];
    return RunJournal(
      run: PlaySession.restored(
        [for (final c in j['cards'] as List) _cardOf(c as Map<String, dynamic>)],
        attempts: attempts('attempts'),
        undone: attempts('undone'),
        elapsed: Duration(microseconds: j['elapsedUs'] as int),
      ),
      config: PlayConfig.fromJson(j['config'] as Map<String, dynamic>),
      startedAt: DateTime.parse(j['startedAt'] as String),
      tobi: switch (j['tobiMs']) { final int ms => Duration(milliseconds: ms), _ => null },
      tobiLine: (j['tobiLine'] as List?)?.map((ms) => Duration(milliseconds: ms as int)).toList(),
    );
  }

  static Map<String, Object?> _card(CardRef c) => {
        'id': c.poemId,
        'inv': c.inverted,
        if (!c.mask.isNone) 'mask': {'hidden': c.mask.hidden.toList(), 'style': c.mask.style.name, 'seed': c.mask.seed},
      };

  static CardRef _cardOf(Map<String, dynamic> j) {
    final mask = j['mask'] as Map<String, dynamic>?;
    return CardRef(
      j['id'] as int,
      inverted: j['inv'] as bool,
      mask: mask == null
          ? CardMask.none
          : CardMask(
              hidden: (mask['hidden'] as List).cast<int>().toSet(),
              style: MaskStyle.values.byName(mask['style'] as String),
              seed: mask['seed'] as int,
            ),
    );
  }

  static Map<String, Object?> _attempt(Attempt a) => {
        'index': a.index,
        'card': _card(a.card),
        'responseUs': a.responseUs,
        'revealAtUs': a.revealAtUs,
        'commitUs': a.commitUs,
        'outcome': a.outcome.name,
        'at': a.at.toIso8601String(),
        'deckSize': a.deckSize,
        'wrong': a.wrong,
        'tainted': a.tainted,
      };

  static Attempt _attemptOf(Map<String, dynamic> j) => Attempt(
        index: j['index'] as int,
        card: _cardOf(j['card'] as Map<String, dynamic>),
        responseUs: j['responseUs'] as int,
        revealAtUs: j['revealAtUs'] as int?,
        commitUs: j['commitUs'] as int?,
        outcome: Outcome.values.byName(j['outcome'] as String),
        at: DateTime.parse(j['at'] as String),
        deckSize: j['deckSize'] as int,
        tainted: j['tainted'] as bool,
      )..wrong = j['wrong'] as bool;
}
