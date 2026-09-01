import '../models/subtitle_cue.dart';

class SrtParseException implements Exception {
  final String message;
  SrtParseException(this.message);

  @override
  String toString() => 'SrtParseException: $message';
}

/// Parses SubRip (.srt) subtitle text into timed [SubtitleCue]s.
///
/// Tolerant of BOM, CRLF/LF line endings, extra blank lines between blocks,
/// and both `,` and `.` as the millisecond separator (some tools export
/// `00:00:01.000` instead of the strict `00:00:01,000`).
class SrtParser {
  static final RegExp _timecodeLine = RegExp(
    r'^\s*(\d{1,2}):(\d{2}):(\d{2})[.,](\d{1,3})\s*-->\s*'
    r'(\d{1,2}):(\d{2}):(\d{2})[.,](\d{1,3})',
  );

  // <i>, <b>, <u>, <font color="...">, etc. — the small set of HTML-style
  // tags .srt supports for styling. The player has no rich-text renderer for
  // these yet, and sending them to a translation engine garbles the tag
  // placement, so cue text is always plain — strip rather than display them.
  static final RegExp _htmlTag = RegExp(r'<[^>]*>');

  // ASS/SSA override codes (e.g. {\an8}, {\i1}) that sometimes leak into
  // .srt files converted from other subtitle formats.
  static final RegExp _assOverride = RegExp(r'\{\\[^}]*\}');

  static String _stripFormatting(String text) {
    return text
        .replaceAll(_htmlTag, '')
        .replaceAll(_assOverride, '')
        .split('\n')
        .map((line) => line.replaceAll(RegExp(r'[ \t]+'), ' ').trim())
        .join('\n');
  }

  static List<SubtitleCue> parse(String source) {
    final text = source.startsWith('﻿') ? source.substring(1) : source;
    final normalized = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final blocks = normalized.split(RegExp(r'\n\s*\n'));

    final cues = <SubtitleCue>[];
    var fallbackIndex = 0;

    for (final rawBlock in blocks) {
      final block = rawBlock.trim();
      if (block.isEmpty) continue;

      final lines = block.split('\n');
      var lineOffset = 0;

      // Optional numeric index line.
      int? index;
      if (lineOffset < lines.length &&
          RegExp(r'^\s*\d+\s*$').hasMatch(lines[lineOffset])) {
        index = int.parse(lines[lineOffset].trim());
        lineOffset++;
      }

      if (lineOffset >= lines.length) continue;
      final match = _timecodeLine.firstMatch(lines[lineOffset]);
      if (match == null) {
        // Not a valid cue block (e.g. trailing metadata) — skip it rather
        // than failing the whole file.
        continue;
      }
      lineOffset++;

      final start = _durationFromMatch(match, 1);
      final end = _durationFromMatch(match, 5);

      final textLines = lines.sublist(lineOffset).map((l) => l.trimRight());
      final cueText = _stripFormatting(textLines.join('\n').trim());

      fallbackIndex++;
      cues.add(
        SubtitleCue(
          index: index ?? fallbackIndex,
          start: start,
          end: end,
          text: cueText,
        ),
      );
    }

    if (cues.isEmpty) {
      throw SrtParseException('No valid subtitle cues found.');
    }

    cues.sort((a, b) => a.start.compareTo(b.start));
    return cues;
  }

  static Duration _durationFromMatch(RegExpMatch match, int groupStart) {
    final hours = int.parse(match.group(groupStart)!);
    final minutes = int.parse(match.group(groupStart + 1)!);
    final seconds = int.parse(match.group(groupStart + 2)!);
    final millisRaw = match.group(groupStart + 3)!;
    // Pad to 3 digits so ".5" (rare, non-standard) is treated as 500ms.
    final millis = int.parse(millisRaw.padRight(3, '0'));
    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      milliseconds: millis,
    );
  }
}
