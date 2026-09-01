/// How far along [SubtitleDocument.translatedLines] is for the document's
/// [SubtitleDocument.translatedLanguage].
enum TranslationStatus {
  /// No translation has been requested yet.
  none,

  /// A translation is currently running.
  pending,

  /// [SubtitleDocument.translatedLines] holds a complete, usable translation.
  done,

  /// The last attempt failed (e.g. no network for the cloud fallback, or the
  /// on-device model couldn't be downloaded). Playback falls back to
  /// [SubtitleDocument.rawSrtText] either way — this only affects whether the
  /// library screen offers a retry.
  failed;

  String get _name => switch (this) {
    TranslationStatus.none => 'none',
    TranslationStatus.pending => 'pending',
    TranslationStatus.done => 'done',
    TranslationStatus.failed => 'failed',
  };

  static TranslationStatus _fromName(String? name) {
    return TranslationStatus.values.firstWhere(
      (s) => s._name == name,
      orElse: () => TranslationStatus.none,
    );
  }
}

/// A subtitle file the user has imported into their offline library.
///
/// The raw `.srt` text is stored (not the parsed cues) so re-parsing always
/// reflects [SrtParser]'s current behavior and storage stays simple —
/// plain Map values that Hive can persist without generated type adapters.
///
/// [translatedLines], when present, holds one translated line per cue in
/// [SrtParser.parse(rawSrtText)]'s output order — a positional match, not a
/// second .srt file — so it can never drift out of alignment with the
/// original cues the way two independently-sourced subtitle files could.
class SubtitleDocument {
  final String id;
  final String name;
  final DateTime importedAt;
  final String rawSrtText;
  final List<String>? translatedLines;
  final String? translatedLanguage;
  final TranslationStatus translationStatus;
  final DateTime? translatedAt;

  const SubtitleDocument({
    required this.id,
    required this.name,
    required this.importedAt,
    required this.rawSrtText,
    this.translatedLines,
    this.translatedLanguage,
    this.translationStatus = TranslationStatus.none,
    this.translatedAt,
  });

  SubtitleDocument copyWith({
    List<String>? translatedLines,
    String? translatedLanguage,
    TranslationStatus? translationStatus,
    DateTime? translatedAt,
  }) {
    return SubtitleDocument(
      id: id,
      name: name,
      importedAt: importedAt,
      rawSrtText: rawSrtText,
      translatedLines: translatedLines ?? this.translatedLines,
      translatedLanguage: translatedLanguage ?? this.translatedLanguage,
      translationStatus: translationStatus ?? this.translationStatus,
      translatedAt: translatedAt ?? this.translatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'importedAt': importedAt.toIso8601String(),
    'rawSrtText': rawSrtText,
    'translatedLines': translatedLines,
    'translatedLanguage': translatedLanguage,
    'translationStatus': translationStatus._name,
    'translatedAt': translatedAt?.toIso8601String(),
  };

  factory SubtitleDocument.fromMap(Map<dynamic, dynamic> map) {
    return SubtitleDocument(
      id: map['id'] as String,
      name: map['name'] as String,
      importedAt: DateTime.parse(map['importedAt'] as String),
      rawSrtText: map['rawSrtText'] as String,
      translatedLines: (map['translatedLines'] as List?)?.cast<String>(),
      translatedLanguage: map['translatedLanguage'] as String?,
      translationStatus: TranslationStatus._fromName(map['translationStatus'] as String?),
      translatedAt: map['translatedAt'] != null
          ? DateTime.parse(map['translatedAt'] as String)
          : null,
    );
  }
}
