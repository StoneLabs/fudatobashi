import 'package:flutter/foundation.dart';

/// How much of a group of cards (an island, a 友札 set) is in the deck,
/// counting only the cards the player knows.
enum Coverage { none, some, all }

/// Free practice's deck while it is being set up: a set of card ids drawn
/// from the cards the player knows. Islands and 友札 sets are views onto it
/// that toggle their cards in bulk, and the card picker edits it one card at
/// a time, so every picker always agrees with the others.
class DeckSelection extends ChangeNotifier {
  /// Starts from [picked] (a stored custom deck), or every known card when
  /// null. Cards the player no longer knows are dropped.
  DeckSelection({required Set<int> known, Iterable<int>? picked})
      : known = Set.unmodifiable(known),
        _selected = picked == null ? {...known} : {...picked}.intersection(known);

  /// The cards that may be picked.
  final Set<int> known;
  final Set<int> _selected;

  Set<int> get selected => Set.unmodifiable(_selected);
  int get count => _selected.length;

  /// Every known card: free practice's default deck.
  bool get isDefault => _selected.length == known.length;

  /// The deck to store: null when it is the default (so it keeps following
  /// the known cards as more are learned), else the picked cards, sorted.
  List<int>? get customIds => isDefault ? null : (_selected.toList()..sort());

  bool contains(int id) => _selected.contains(id);

  /// The known cards among [group].
  Iterable<int> knownOf(Iterable<int> group) => group.where(known.contains);

  Coverage coverageOf(Iterable<int> group) {
    final ids = knownOf(group).toList();
    final n = ids.where(_selected.contains).length;
    if (n == 0) return Coverage.none;
    return n == ids.length ? Coverage.all : Coverage.some;
  }

  /// Adds or removes one known card.
  void toggleCard(int id) {
    if (!known.contains(id)) return;
    if (!_selected.remove(id)) _selected.add(id);
    notifyListeners();
  }

  /// A fully selected group empties; otherwise all of its known cards join.
  void toggleGroup(Iterable<int> group) {
    final ids = knownOf(group).toList();
    if (ids.isEmpty) return;
    if (coverageOf(ids) == Coverage.all) {
      _selected.removeAll(ids);
    } else {
      _selected.addAll(ids);
    }
    notifyListeners();
  }

  void selectAll() {
    _selected.addAll(known);
    notifyListeners();
  }

  void clear() {
    _selected.clear();
    notifyListeners();
  }
}
