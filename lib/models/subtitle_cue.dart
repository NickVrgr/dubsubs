/// A single timed subtitle line parsed from an .srt file.
class SubtitleCue {
  final int index;
  final Duration start;
  final Duration end;
  final String text;

  const SubtitleCue({
    required this.index,
    required this.start,
    required this.end,
    required this.text,
  });

  SubtitleCue copyWith({
    int? index,
    Duration? start,
    Duration? end,
    String? text,
  }) {
    return SubtitleCue(
      index: index ?? this.index,
      start: start ?? this.start,
      end: end ?? this.end,
      text: text ?? this.text,
    );
  }
}
