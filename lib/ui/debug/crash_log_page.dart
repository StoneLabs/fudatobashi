import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../state/crash_log.dart';
import '../manga/manga.dart';
import 'debug_common.dart';

/// The local crash log (`CrashLog`), newest last, to copy into a bug report
/// or clear.
class CrashLogPage extends StatefulWidget {
  const CrashLogPage({super.key, required this.log});

  final CrashLog log;

  @override
  State<CrashLogPage> createState() => _CrashLogPageState();
}

class _CrashLogPageState extends State<CrashLogPage> {
  String? _text;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final text = await widget.log.read();
    if (mounted) setState(() => _text = text);
  }

  @override
  Widget build(BuildContext context) {
    final text = _text;
    return DebugScaffold(
      title: 'Crash log',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            TextButton(
              onPressed: text == null || text.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) MangaToast.show(context, 'Copied');
                    },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: text == null || text.isEmpty
                  ? null
                  : () async {
                      await widget.log.clear();
                      await _load();
                    },
              child: const Text('Clear'),
            ),
          ]),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SelectableText(text == null ? '…' : (text.isEmpty ? 'No errors logged.' : text), style: debugMono),
            ),
          ),
        ],
      ),
    );
  }
}
