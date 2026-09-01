/// Thrown when a [TranslationService] can't produce a translation right now
/// (no network, no on-device model yet, unsupported platform, etc).
///
/// Callers should treat this as "keep showing the original text", not a hard
/// failure — see [SubtitleDocument.translationStatus] and how the player
/// falls back to [SubtitleDocument.rawSrtText] whenever a translation isn't
/// available.
class TranslationUnavailableException implements Exception {
  TranslationUnavailableException(this.message);

  final String message;

  @override
  String toString() => 'TranslationUnavailableException: $message';
}

/// Translates a batch of subtitle lines from one language to another.
///
/// Implementations are swappable per platform — see
/// `translation_service_mlkit.dart` for the on-device Android/iOS engine.
/// Nothing outside this interface should know which engine is behind it.
abstract class TranslationService {
  /// Translates [lines] from [sourceLanguage] to [targetLanguage] (BCP-47
  /// codes, e.g. `'es'` / `'en'`), in order.
  ///
  /// The result is always the same length as [lines], positionally matched,
  /// so callers can zip it straight back onto the original cues — never a
  /// partial or misaligned result. Throws [TranslationUnavailableException]
  /// if translation can't be done right now.
  Future<List<String>> translate(
    List<String> lines, {
    required String sourceLanguage,
    required String targetLanguage,
  });
}
