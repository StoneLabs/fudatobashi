import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/article_template.dart';
import '../manga/manga.dart';
import 'debug_common.dart';

final _articlePath = RegExp(r'^assets/l10n/([^/]+)_articles/(.+\.md)$');

/// Every article file the app bundles, found in the asset manifest and
/// grouped by language and folder, to open as raw text.
class RawArticlesPage extends StatefulWidget {
  const RawArticlesPage({super.key, this.bundle});

  final AssetBundle? bundle;

  @override
  State<RawArticlesPage> createState() => _RawArticlesPageState();
}

class _RawArticlesPageState extends State<RawArticlesPage> {
  late final Future<Map<String, List<String>>> _groups = _list();

  Future<Map<String, List<String>>> _list() async {
    final manifest = await AssetManifest.loadFromAssetBundle(widget.bundle ?? rootBundle);
    final paths = manifest.listAssets().where(_articlePath.hasMatch).toList()..sort();
    final groups = <String, List<String>>{};
    for (final path in paths) {
      final m = _articlePath.firstMatch(path)!;
      final parts = m.group(2)!.split('/');
      final folder = parts.length > 1 ? '/${parts.sublist(0, parts.length - 1).join('/')}' : '';
      (groups['${m.group(1)}$folder'] ??= []).add(path);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) => DebugScaffold(
    title: 'Articles (raw)',
    child: FutureBuilder(
      future: _groups,
      builder: (context, snapshot) {
        final groups = snapshot.data;
        if (groups == null) return Center(child: Text(snapshot.hasError ? '${snapshot.error}' : '…'));
        if (groups.isEmpty) return const Center(child: Text('No articles bundled.'));
        return ListView(
          children: [
            for (final MapEntry(:key, :value) in groups.entries)
              ExpansionTile(
                title: Text('$key  (${value.length})', style: debugMono),
                initiallyExpanded: !key.contains('/'),
                children: [
                  for (final path in value)
                    ListTile(
                      dense: true,
                      title: Text(path.substring(path.lastIndexOf('/') + 1), style: debugMono),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => RawArticleViewer(path: path, bundle: widget.bundle)),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    ),
  );
}

enum _View { raw, kana, romaji }

/// One article file as written, in a monospace font; optionally with its
/// template filled in.
class RawArticleViewer extends StatefulWidget {
  const RawArticleViewer({super.key, required this.path, this.bundle});

  final String path;
  final AssetBundle? bundle;

  @override
  State<RawArticleViewer> createState() => _RawArticleViewerState();
}

class _RawArticleViewerState extends State<RawArticleViewer> {
  late final Future<String> _source = _read();
  _View _view = _View.raw;

  Future<String> _read() async {
    try {
      final data = await (widget.bundle ?? rootBundle).load(widget.path);
      return utf8.decode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (e) {
      return 'Could not read ${widget.path}: $e';
    }
  }

  String _shown(String source) {
    if (_view == _View.raw) return source;
    try {
      return ArticleTemplate.fill(source, romaji: _view == _View.romaji);
    } catch (e) {
      return 'Template error: $e';
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder(
    future: _source,
    builder: (context, snapshot) {
      final source = snapshot.data;
      final text = source == null ? '…' : _shown(source);
      return DebugScaffold(
        title: widget.path.substring(widget.path.lastIndexOf('/') + 1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(children: [
                Expanded(
                  child: SegmentedButton<_View>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: _View.raw, label: Text('Raw')),
                      ButtonSegment(value: _View.kana, label: Text('Kana')),
                      ButtonSegment(value: _View.romaji, label: Text('Romaji')),
                    ],
                    selected: {_view},
                    onSelectionChanged: (s) => setState(() => _view = s.first),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy all',
                  icon: const Icon(Icons.copy),
                  onPressed: source == null
                      ? null
                      : () async {
                          await Clipboard.setData(ClipboardData(text: text));
                          if (context.mounted) MangaToast.show(context, 'Copied');
                        },
                ),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(text, style: debugMono),
              ),
            ),
          ],
        ),
      );
    },
  );
}
