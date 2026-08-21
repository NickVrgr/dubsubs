import 'package:flutter/foundation.dart';

import '../models/app_settings.dart';
import 'storage_service.dart';

/// Manages the globally persisted subtitle display preferences.
class SettingsController extends ChangeNotifier {
  SettingsController(this._storage) : settings = _storage.getSettings();

  final StorageService _storage;
  AppSettings settings;

  Future<void> update(AppSettings Function(AppSettings current) updater) async {
    settings = updater(settings);
    notifyListeners();
    await _storage.saveSettings(settings);
  }
}
