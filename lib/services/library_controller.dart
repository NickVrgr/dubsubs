import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/subtitle_document.dart';
import 'srt_parser.dart';
import 'storage_service.dart';

/// Manages the offline library of imported subtitle files.
class LibraryController extends ChangeNotifier {
  LibraryController(this._storage) {
    _documents = _storage.getLibrary();
  }

  final StorageService _storage;
  late List<SubtitleDocument> _documents;

  List<SubtitleDocument> get documents => _documents;

  /// Validates and stores a new subtitle file. Throws [SrtParseException]
  /// if [rawSrtText] isn't a readable .srt file — nothing is persisted in
  /// that case.
  Future<SubtitleDocument> importSrt({
    required String name,
    required String rawSrtText,
  }) async {
    SrtParser.parse(rawSrtText); // validates; throws on bad input

    final doc = SubtitleDocument(
      id: const Uuid().v4(),
      name: name,
      importedAt: DateTime.now(),
      rawSrtText: rawSrtText,
    );
    await _storage.saveDocument(doc);
    _documents = _storage.getLibrary();
    notifyListeners();
    return doc;
  }

  Future<void> delete(String id) async {
    await _storage.deleteDocument(id);
    _documents = _storage.getLibrary();
    notifyListeners();
  }
}
