import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/subtitle_document.dart';
import 'srt_parser.dart';
import 'storage_service.dart';
import 'translation_service.dart';
import 'translation_service_provider.dart';

/// Manages the offline library of imported subtitle files.
class LibraryController extends ChangeNotifier {
  LibraryController(this._storage, {TranslationService? translationService})
    : _translation = translationService ?? buildTranslationService() {
    _documents = _storage.getLibrary();
  }

  final StorageService _storage;
  final TranslationService _translation;
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

  /// Translates [id]'s subtitle lines from [sourceLanguage] to
  /// [targetLanguage] (BCP-47 codes, e.g. `'es'`/`'en'`) and caches the
  /// result — see [TranslationService]. Meant to be run ahead of time, while
  /// there's still a connection (for the model download on first use, or the
  /// web fallback); playback itself never calls this and always falls back
  /// to the original text if no cached translation exists.
  ///
  /// Safe to call repeatedly — a fresh call re-translates and overwrites the
  /// cache, so a previous [TranslationStatus.failed] can just be retried.
  ///
  /// Throws [TranslationUnavailableException] on failure (after recording
  /// [TranslationStatus.failed]) so callers can show the specific reason —
  /// e.g. "this browser doesn't support it" is not the same problem as "no
  /// network", and only one of those is worth retrying.
  Future<void> translateDocument(
    String id, {
    String sourceLanguage = 'es',
    String targetLanguage = 'en',
  }) async {
    final doc = _documents.firstWhere((d) => d.id == id);
    await _updateDocument(doc.copyWith(translationStatus: TranslationStatus.pending));

    try {
      final cues = SrtParser.parse(doc.rawSrtText);
      final translated = await _translation.translate(
        cues.map((c) => c.text).toList(),
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      await _updateDocument(
        doc.copyWith(
          translatedLines: translated,
          translatedLanguage: targetLanguage,
          translationStatus: TranslationStatus.done,
          translatedAt: DateTime.now(),
        ),
      );
    } on TranslationUnavailableException {
      await _updateDocument(doc.copyWith(translationStatus: TranslationStatus.failed));
      rethrow;
    } catch (e) {
      await _updateDocument(doc.copyWith(translationStatus: TranslationStatus.failed));
      throw TranslationUnavailableException('Translation failed: $e');
    }
  }

  Future<void> _updateDocument(SubtitleDocument doc) async {
    await _storage.saveDocument(doc);
    _documents = _storage.getLibrary();
    notifyListeners();
  }
}
