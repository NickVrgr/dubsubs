import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subtitle_document.dart';
import '../services/library_controller.dart';
import '../services/srt_import.dart';
import '../services/translation_service.dart';
import 'opensubtitles_search_screen.dart';
import 'player_screen.dart';
import 'settings_screen.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  Future<void> _import(BuildContext context) async {
    final library = context.read<LibraryController>();
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['srt'],
    );
    if (file == null) return;

    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not read the selected file.')));
      }
      return;
    }

    final result = await importSrtBytes(library: library, fileName: file.name, bytes: bytes);
    if (!context.mounted) return;
    if (result.document != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(document: result.document!)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.errorMessage!)));
    }
  }

  Future<void> _confirmDelete(BuildContext context, SubtitleDocument doc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove subtitle?'),
        content: Text('"${doc.name}" will be removed from your offline library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<LibraryController>().delete(doc.id);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _translate(BuildContext context, SubtitleDocument doc) async {
    try {
      await context.read<LibraryController>().translateDocument(doc.id);
    } on TranslationUnavailableException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Widget _translationBadge(BuildContext context, SubtitleDocument doc) {
    switch (doc.translationStatus) {
      case TranslationStatus.pending:
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      case TranslationStatus.done:
        return Tooltip(
          message: 'Translated to ${doc.translatedLanguage} — ready offline',
          child: const Icon(Icons.offline_pin, color: Colors.green),
        );
      case TranslationStatus.failed:
        return IconButton(
          icon: const Icon(Icons.cloud_off, color: Colors.orange),
          tooltip: 'Translation failed — tap to retry',
          onPressed: () => _translate(context, doc),
        );
      case TranslationStatus.none:
        return IconButton(
          icon: const Icon(Icons.translate),
          tooltip: 'Translate for offline reading',
          onPressed: () => _translate(context, doc),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final docs = context.watch<LibraryController>().documents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DubSubs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore),
            tooltip: 'Search OpenSubtitles',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OpenSubtitlesSearchScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () =>
                Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: docs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No subtitles yet.\nImport an .srt file, or search OpenSubtitles online.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final doc = docs[i];
                return ListTile(
                  leading: const Icon(Icons.subtitles),
                  title: Text(doc.name),
                  subtitle: Text('Imported ${_formatDate(doc.importedAt)}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _translationBadge(context, doc),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, doc),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlayerScreen(document: doc)),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _import(context),
        icon: const Icon(Icons.add),
        label: const Text('Import .srt'),
      ),
    );
  }
}
