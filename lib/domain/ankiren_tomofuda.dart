import '../config/config.dart';
import '../data/poem.dart';

/// 暗記練's 友札: the cards of one kimariji family, whose kimariji begin with the
/// same sounds and split only at the deciding one (あさぼらけう / あさぼらけあ,
/// なにし / なにわが / なにわえ). Two cards are 友札 when their kimariji share
/// at least [AnkirenTuning.tomofudaMinShared] sounds, and all but the last
/// of the shorter one.
class AnkirenTomofuda {
  AnkirenTomofuda(Poems poems)
    : _friends = {
        for (final p in poems.all)
          p.id: [
            for (final q in poems.all)
              if (q.id != p.id && areFriends(p.kimariji, q.kimariji)) q.id,
          ],
      };

  final Map<int, List<int>> _friends;

  /// A card's 友札.
  List<int> of(int poemId) => _friends[poemId]!;

  static bool areFriends(String a, String b) {
    var shared = 0;
    while (shared < a.length && shared < b.length && a[shared] == b[shared]) {
      shared++;
    }
    final shorter = a.length < b.length ? a.length : b.length;
    return shared >= AnkirenTuning.tomofudaMinShared && shared >= shorter - 1;
  }

  /// The families: cards linked by 友札, directly or not, each by id and the
  /// families by their first card.
  List<List<int>> get families {
    final seen = <int>{};
    final result = <List<int>>[];
    for (final id in _friends.keys) {
      if (_friends[id]!.isEmpty || !seen.add(id)) continue;
      final family = [id];
      for (var i = 0; i < family.length; i++) {
        for (final t in _friends[family[i]]!) {
          if (seen.add(t)) family.add(t);
        }
      }
      result.add(family..sort());
    }
    return result;
  }
}
