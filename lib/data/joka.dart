import 'poem.dart';

/// The 序歌 (joka): the poem a reader recites before the first card of a
/// match, so the players can settle in. It is not one of the hundred poems;
/// the start card carries it. One phrase per column, first to last.
const jokaPhrases = ['難波津に', '咲くやこの花', '冬ごもり', '今を春べと', '咲くやこの花'];

/// The start card's title.
const jokaTitle = '序歌';

/// [jokaTitle] as read.
const jokaTitleKana = 'じょか';

/// What players say with a bow before a match begins.
const jokaGreeting = 'よろしくお願いします';

/// The 序歌 in full, as tool/build_poems.dart writes it next to the poems.
const jokaAsset = 'assets/data/joka.json';

/// Loaded once at startup in `main`.
late final Waka joka;
