/// A subtitle file the user has imported into their offline library.
///
/// The raw `.srt` text is stored (not the parsed cues) so re-parsing always
/// reflects [SrtParser]'s current behavior and storage stays simple —
/// plain Map values that Hive can persist without generated type adapters.
class SubtitleDocument {
  final String id;
  final String name;
  final DateTime importedAt;
  final String rawSrtText;

  const SubtitleDocument({
    required this.id,
    required this.name,
    required this.importedAt,
    required this.rawSrtText,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'importedAt': importedAt.toIso8601String(),
    'rawSrtText': rawSrtText,
  };

  factory SubtitleDocument.fromMap(Map<dynamic, dynamic> map) {
    return SubtitleDocument(
      id: map['id'] as String,
      name: map['name'] as String,
      importedAt: DateTime.parse(map['importedAt'] as String),
      rawSrtText: map['rawSrtText'] as String,
    );
  }
}
