/// Build-time configuration read via `--dart-define` (or
/// `--dart-define-from-file=env.json`) so secrets never live in source
/// control. See README.md for how to supply `OPENSUBTITLES_API_KEY`.
class Config {
  static const openSubtitlesApiKey = String.fromEnvironment('OPENSUBTITLES_API_KEY');

  static bool get hasOpenSubtitlesApiKey => openSubtitlesApiKey.isNotEmpty;
}
