import 'poem.dart';

enum FudaSetKind { all, initial, confusable, shimoStart, kimarijiLength }

/// A selectable group of cards (the original app's 表示する札を限定する options,
/// plus a few new ones).
class FudaSet {
  const FudaSet({
    required this.id,
    required this.label,
    required this.kind,
    required this.poemIds,
  });

  final String id;
  final String label;
  final FudaSetKind kind;
  final List<int> poemIds;

  /// Label with the card count, like the original: "むすめふさほせ(7首)".
  String get labelWithCount => '$label(${poemIds.length}首)';
}

/// Initial-kana groups of the kimariji, in the classic learning order
/// (一枚札 → 二枚札 → … → 十六枚札).
const initialGroups = [
  'むすめふさほせ',
  'うつしもゆ',
  'いちひき',
  'はやよか',
  'み',
  'た',
  'こ',
  'お',
  'わ',
  'な',
  'あ',
];

/// 間違えやすい札: cards whose torifuda start the same way. Labels follow the
/// original app; members are given by kimariji.
const confusableSets = <(String, List<String>)>[
  ('あらざ/おぐ', ['あらざ', 'おぐ']),
  ('あきの/きみ・は', ['あきの', 'きみがためは']),
  ('なにわえ/わび', ['なにわえ', 'わび']),
  ('やえ/わがそ', ['やえ', 'わがそ']),
  ('つき/はなの', ['つき', 'はなの']),
  ('ながか/みち', ['ながか', 'みち']),
  ('なにし/わた・や', ['なにし', 'わたのはらや']),
  ('きり/はるす', ['きり', 'はるす']),
  ('あし/きみ・お/やまが', ['あし', 'きみがためお', 'やまが']),
  ('うら/こころに/つく', ['うら', 'こころに', 'つく']),
  ('なつ/め/わた・こ', ['なつ', 'め', 'わたのはらこ']),
  ('あけ/もも', ['あけ', 'もも']),
  ('あさじ/よの・は', ['あさじ', 'よのなかは']),
  ('いに/わすれ', ['いに', 'わすれ']),
  ('さ/みかの', ['さ', 'みかの']),
  ('もろ/ひとは', ['もろ', 'ひとは']),
  ('ちぎりお/なにわが', ['ちぎりお', 'なにわが']),
  ('たち/たれ', ['たち', 'たれ']),
  ('ひとも/わがい', ['ひとも', 'わがい']),
];

class FudaSets {
  FudaSets(Poems p) : all = _build(p) {
    _byId = {for (final s in all) s.id: s};
  }

  final List<FudaSet> all;
  late final Map<String, FudaSet> _byId;

  FudaSet operator [](String id) => _byId[id]!;

  Iterable<FudaSet> ofKind(FudaSetKind k) => all.where((s) => s.kind == k);

  /// Union of the cards in the given sets, sorted by id.
  List<int> union(Iterable<String> ids) =>
      ({for (final id in ids) ...?_byId[id]?.poemIds}.toList()..sort());

  /// For each card, the other cards that share one of its confusable sets.
  List<int> tomofuda(int poemId) => {
        for (final s in ofKind(FudaSetKind.confusable))
          if (s.poemIds.contains(poemId)) ...s.poemIds,
      }.where((id) => id != poemId).toList();

  static List<FudaSet> _build(Poems p) {
    List<int> ids(bool Function(Poem) f) => [for (final x in p.all) if (f(x)) x.id];
    return [
      FudaSet(id: 'all', label: '100首', kind: FudaSetKind.all, poemIds: ids((_) => true)),
      for (final g in initialGroups)
        FudaSet(
          id: 'initial:$g',
          label: g,
          kind: FudaSetKind.initial,
          poemIds: ids((x) => g.contains(x.kimariji[0])),
        ),
      for (final (label, members) in confusableSets)
        FudaSet(
          id: 'confusable:$label',
          label: label,
          kind: FudaSetKind.confusable,
          poemIds: [for (final k in members) p.byKimariji(k).id]..sort(),
        ),
      FudaSet(
        id: 'shimo:ひと',
        label: '下句がひとで始まる句',
        kind: FudaSetKind.shimoStart,
        poemIds: ids((x) => x.torifuda.startsWith('ひと')),
      ),
      FudaSet(
        id: 'shimo:わか',
        label: '下句がわかで始まる句',
        kind: FudaSetKind.shimoStart,
        poemIds: ids((x) => x.torifuda.startsWith('わか')),
      ),
      for (var n = 1; n <= 6; n++)
        FudaSet(
          id: 'len:$n',
          label: '$n字決まり',
          kind: FudaSetKind.kimarijiLength,
          poemIds: ids((x) => x.kimariji.length == n),
        ),
    ];
  }
}

late final FudaSets fudaSets;
