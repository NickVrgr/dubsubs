import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subtitle_document.dart';
import '../services/library_controller.dart';
import '../services/srt_parser.dart';
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

    String content;
    try {
      content = utf8.decode(bytes);
    } catch (_) {
      content = latin1.decode(bytes);
    }

    final name = file.name.replaceAll(RegExp(r'\.srt$', caseSensitive: false), '');

    try {
      final doc = await library.importSrt(name: name, rawSrtText: content);
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(document: doc)));
      }
    } on SrtParseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Not a valid .srt file: ${e.message}')));
      }
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

  @override
  Widget build(BuildContext context) {
    final docs = context.watch<LibraryController>().documents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DubSubs'),
        actions: [
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
                  'No subtitles yet.\nImport an .srt file to get started.',
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(context, doc),
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
