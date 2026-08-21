/// One subtitle file found via the OpenSubtitles.com search API.
class OpenSubtitlesResult {
  final int fileId;
  final String language;
  final String releaseName;
  final String? movieTitle;
  final int? year;
  final String uploaderName;
  final int downloadCount;
  final bool hearingImpaired;

  const OpenSubtitlesResult({
    required this.fileId,
    required this.language,
    required this.releaseName,
    required this.movieTitle,
    required this.year,
    required this.uploaderName,
    required this.downloadCount,
    required this.hearingImpaired,
  });

  String get displayTitle {
    final t = movieTitle;
    if (t == null || t.isEmpty) return releaseName;
    return year != null ? '$t ($year)' : t;
  }

  /// Parses one `data[]` entry from the OpenSubtitles `/subtitles` search
  /// response. Returns null for entries with no attached file (shouldn't
  /// normally happen, but the API doesn't guarantee it).
  static OpenSubtitlesResult? fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>?;
    if (attributes == null) return null;

    final files = attributes['files'] as List<dynamic>?;
    if (files == null || files.isEmpty) return null;
    final firstFile = files.first as Map<String, dynamic>;
    final fileId = firstFile['file_id'] as int?;
    if (fileId == null) return null;

    final featureDetails = attributes['feature_details'] as Map<String, dynamic>?;
    final uploader = attributes['uploader'] as Map<String, dynamic>?;

    return OpenSubtitlesResult(
      fileId: fileId,
      language: attributes['language'] as String? ?? '?',
      releaseName: (attributes['release'] as String?)?.trim().isNotEmpty == true
          ? attributes['release'] as String
          : (firstFile['file_name'] as String? ?? 'Untitled'),
      movieTitle: featureDetails?['title'] as String?,
      year: featureDetails?['year'] as int?,
      uploaderName: uploader?['name'] as String? ?? 'Anonymous',
      downloadCount: attributes['download_count'] as int? ?? 0,
      hearingImpaired: attributes['hearing_impaired'] as bool? ?? false,
    );
  }
}
