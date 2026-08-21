import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/opensubtitles_result.dart';
import '../services/library_controller.dart';
import '../services/opensubtitles_service.dart';
import '../services/srt_parser.dart';
import 'player_screen.dart';

const _languageOptions = <(String code, String label)>[
  ('en', 'English'),
  ('es', 'Spanish'),
  ('ca', 'Catalan'),
  ('fr', 'French'),
  ('de', 'German'),
  ('it', 'Italian'),
  ('pt-PT', 'Portuguese'),
  ('nl', 'Dutch'),
];

class OpenSubtitlesSearchScreen extends StatefulWidget {
  const OpenSubtitlesSearchScreen({super.key});

  @override
  State<OpenSubtitlesSearchScreen> createState() => _OpenSubtitlesSearchScreenState();
}

class _OpenSubtitlesSearchScreenState extends State<OpenSubtitlesSearchScreen> {
  final _service = OpenSubtitlesService();
  final _queryController = TextEditingController();
  String _languageCode = 'en';

  bool _searching = false;
  bool _importing = false;
  String? _error;
  List<OpenSubtitlesResult> _results = const [];
  bool _searchedOnce = false;

  @override
  void dispose() {
    _service.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text;
    if (query.trim().isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
      _searchedOnce = true;
    });

    try {
      final results = await _service.search(query: query, languageCode: _languageCode);
      if (!mounted) return;
      setState(() => _results = results);
    } on OpenSubtitlesException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _download(OpenSubtitlesResult result) async {
    setState(() => _importing = true);
    try {
      final text = await _service.downloadSrtText(result.fileId);
      if (!mounted) return;
      final doc = await context.read<LibraryController>().importSrt(
        name: result.displayTitle,
        rawSrtText: text,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(document: doc)));
    } on OpenSubtitlesException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } on SrtParseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('That file wasn\'t a valid .srt: ${e.message}')));
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(title: const Text('Search OpenSubtitles')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.block, size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  webUnsupportedMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Search OpenSubtitles')),
      body: Column(
        children: [
          if (!_service.hasApiKey)
            Container(
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.all(12),
              child: Text(
                'No OpenSubtitles API key configured for this build. See README.md.',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      labelText: 'Movie or show title',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _languageCode,
                  items: _languageOptions
                      .map((o) => DropdownMenuItem(value: o.$1, child: Text(o.$2)))
                      .toList(),
                  onChanged: (v) => setState(() => _languageCode = v ?? _languageCode),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _searching ? null : _search,
                icon: const Icon(Icons.search),
                label: Text(_searching ? 'Searching...' : 'Search'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _searchedOnce ? 'No subtitles found.' : 'Search for a title to begin.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final r = _results[i];
                          return ListTile(
                            leading: const Icon(Icons.subtitles_outlined),
                            title: Text(r.displayTitle),
                            subtitle: Text(
                              '${r.releaseName}\n${r.language.toUpperCase()} · '
                              '${r.downloadCount} downloads · ${r.uploaderName}'
                              '${r.hearingImpaired ? ' · HI' : ''}',
                            ),
                            isThreeLine: true,
                            trailing: const Icon(Icons.download),
                            onTap: _importing ? null : () => _download(r),
                          );
                        },
                      ),
          ),
          if (_importing) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}
