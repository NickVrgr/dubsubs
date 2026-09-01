import 'translation_service.dart';
import 'translation_service_web.dart'
    if (dart.library.io) 'translation_service_mlkit.dart';

/// Builds the right [TranslationService] for the running platform: on-device
/// ML Kit for Android/iOS, or the browser's built-in Translator API on web —
/// see translation_service.dart for why callers never need to know which.
TranslationService buildTranslationService() => createTranslationService();
