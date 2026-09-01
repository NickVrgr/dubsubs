import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'translation_service.dart';

/// Picked up via the conditional import in translation_service_provider.dart
/// on web (the only platform without dart:io) — never referenced directly
/// from shared code, since importing dart:js_interop would break the
/// Android/iOS build.
TranslationService createTranslationService() => _WebTranslationService();

/// Binding for the browser's built-in `Translator` API (Chrome/Edge 138+),
/// which runs entirely on-device — no server, no API key, no per-character
/// cost. See https://developer.mozilla.org/docs/Web/API/Translator
///
/// Not yet available in every browser, so callers must be ready for
/// [TranslationUnavailableException] on anything else (Firefox, Safari,
/// older Chrome) — same as the model-download failure mobile already has to
/// handle.
@JS('Translator')
extension type _TranslatorClass._(JSObject _) implements JSObject {
  external static JSPromise<JSString> availability(JSObject options);
  external static JSPromise<_Translator> create(JSObject options);
}

extension type _Translator._(JSObject _) implements JSObject {
  external JSPromise<JSString> translate(JSString input);
  external void destroy();
}

JSObject _languagePairOptions(String sourceLanguage, String targetLanguage) {
  final options = JSObject();
  options['sourceLanguage'] = sourceLanguage.toJS;
  options['targetLanguage'] = targetLanguage.toJS;
  return options;
}

class _WebTranslationService implements TranslationService {
  @override
  Future<List<String>> translate(
    List<String> lines, {
    required String sourceLanguage,
    required String targetLanguage,
  }) async {
    if (!globalContext.has('Translator')) {
      throw TranslationUnavailableException(
        "This browser doesn't support on-device translation yet — try a recent "
        'Chrome or Edge, or use the Android/iOS app.',
      );
    }

    final availability = (await _TranslatorClass.availability(
      _languagePairOptions(sourceLanguage, targetLanguage),
    ).toDart).toDart;
    if (availability == 'unavailable') {
      throw TranslationUnavailableException(
        "This browser can't translate $sourceLanguage -> $targetLanguage on-device.",
      );
    }

    final _Translator translator;
    try {
      // create() downloads the language model on first use (same tradeoff as
      // the mobile ML Kit path) and resolves once it's ready to translate.
      translator = await _TranslatorClass.create(
        _languagePairOptions(sourceLanguage, targetLanguage),
      ).toDart;
    } catch (e) {
      throw TranslationUnavailableException(
        'Could not start the on-device translator — connect to Wi-Fi and retry. ($e)',
      );
    }

    try {
      final results = <String>[];
      for (final line in lines) {
        if (line.isEmpty) {
          results.add('');
          continue;
        }
        final translated = await translator.translate(line.toJS).toDart;
        results.add(translated.toDart);
      }
      return results;
    } catch (e) {
      throw TranslationUnavailableException('Translation failed: $e');
    } finally {
      translator.destroy();
    }
  }
}
