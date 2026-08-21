import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_settings.dart';
import '../models/subtitle_document.dart';

/// Offline persistence for the imported subtitle library and app settings.
///
/// Uses plain Hive boxes (Map values) rather than generated TypeAdapters —
/// keeps the project free of a build_runner step, and works identically on
/// Android/iOS (file-backed) and Web (IndexedDB-backed).
///
/// Expects `Hive.initFlutter()` (or, in tests, `Hive.init(path)`) to have
/// already been called — that bootstrapping is platform-specific and kept
/// out of this class so tests can point Hive at a temp directory instead of
/// going through the `path_provider` platform channel.
class StorageService {
  static const _libraryBoxName = 'library';
  static const _settingsBoxName = 'settings';
  static const _settingsKey = 'settings';

  Box? _libraryBox;
  Box? _settingsBox;

  Future<void> init() async {
    _libraryBox = await Hive.openBox(_libraryBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  List<SubtitleDocument> getLibrary() {
    final box = _libraryBox!;
    return box.values
        .map((e) => SubtitleDocument.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  Future<void> saveDocument(SubtitleDocument doc) {
    return _libraryBox!.put(doc.id, doc.toMap());
  }

  Future<void> deleteDocument(String id) {
    return _libraryBox!.delete(id);
  }

  AppSettings getSettings() {
    final raw = _settingsBox!.get(_settingsKey);
    if (raw == null) return const AppSettings();
    return AppSettings.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  Future<void> saveSettings(AppSettings settings) {
    return _settingsBox!.put(_settingsKey, settings.toMap());
  }
}
