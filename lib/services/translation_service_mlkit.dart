import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import 'translation_service.dart';

/// Picked up via the conditional import in translation_service_provider.dart
/// on Android/iOS (dart.library.io) — never referenced directly from shared
/// code, since importing google_mlkit_translation would drag a dart:io
/// import into the web build and break compilation there.
TranslationService createTranslationService() => _MlKitTranslationService();

/// On-device translation via Google ML Kit — Android and iOS only.
///
/// The per-language model (roughly 30MB) is downloaded once and cached by
/// the OS; every translation after that runs fully on-device with no
/// network call at all. That's what makes this safe to rely on inside a
/// cinema with no signal: as long as the model was fetched at some point
/// earlier (e.g. at home on Wi-Fi when the subtitle was translated), it
/// never needs the network again, no matter how many times you replay it.
class _MlKitTranslationService implements TranslationService {
  @override
  Future<List<String>> translate(
    List<String> lines, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    final source = BCP47Code.fromRawValue(sourceLanguage);
    final target = BCP47Code.fromRawValue(targetLanguage);
    if (source == null || target == null) {
      throw TranslationUnavailableException(
        'Unsupported language code ($sourceLanguage -> $targetLanguage).',
      );
    }

    final modelManager = OnDeviceTranslatorModelManager();
    try {
      final modelReady = await modelManager.isModelDownloaded(target.bcpCode);
      if (!modelReady) {
        await modelManager.downloadModel(target.bcpCode);
      }
    } catch (e) {
      throw TranslationUnavailableException(
        'Could not download the $targetLanguage translation model — connect to Wi-Fi and retry. ($e)',
      );
    }

    final translator = OnDeviceTranslator(sourceLanguage: source, targetLanguage: target);
    try {
      final results = <String>[];
      for (final line in lines) {
        results.add(line.isEmpty ? '' : await translator.translateText(line));
      }
      return results;
    } catch (e) {
      throw TranslationUnavailableException('Translation failed: $e');
    } finally {
      await translator.close();
    }
  }
}
