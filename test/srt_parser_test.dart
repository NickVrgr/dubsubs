import 'package:flutter_test/flutter_test.dart';
import 'package:dubsubs/services/srt_parser.dart';

void main() {
  test('parses a well-formed multi-cue file', () {
    const srt = '''
1
00:00:01,000 --> 00:00:04,500
Hello there.

2
00:00:05,200 --> 00:00:07,000
General Kenobi.
''';

    final cues = SrtParser.parse(srt);

    expect(cues, hasLength(2));
    expect(cues[0].text, 'Hello there.');
    expect(cues[0].start, const Duration(seconds: 1));
    expect(cues[0].end, const Duration(seconds: 4, milliseconds: 500));
    expect(cues[1].text, 'General Kenobi.');
    expect(cues[1].start, const Duration(seconds: 5, milliseconds: 200));
  });

  test('preserves multi-line cue text', () {
    const srt = '''
1
00:00:00,000 --> 00:00:02,000
Line one
Line two
''';

    final cues = SrtParser.parse(srt);
    expect(cues.single.text, 'Line one\nLine two');
  });

  test('handles CRLF line endings, BOM, and a "." millisecond separator', () {
    const srt =
        '﻿1\r\n00:00:00.000 --> 00:00:01.000\r\nHi\r\n\r\n2\r\n00:00:02,000 --> 00:00:03,000\r\nBye\r\n';

    final cues = SrtParser.parse(srt);
    expect(cues, hasLength(2));
    expect(cues[0].text, 'Hi');
    expect(cues[1].text, 'Bye');
  });

  test('tolerates extra blank lines between blocks', () {
    const srt = '''
1
00:00:00,000 --> 00:00:01,000
First



2
00:00:02,000 --> 00:00:03,000
Second
''';

    final cues = SrtParser.parse(srt);
    expect(cues, hasLength(2));
  });

  test('sorts cues by start time regardless of input order', () {
    const srt = '''
2
00:00:10,000 --> 00:00:11,000
Second

1
00:00:01,000 --> 00:00:02,000
First
''';

    final cues = SrtParser.parse(srt);
    expect(cues.first.text, 'First');
    expect(cues.last.text, 'Second');
  });

  test('throws SrtParseException when there are no valid cues', () {
    expect(() => SrtParser.parse('not a subtitle file'), throwsA(isA<SrtParseException>()));
  });

  test('strips HTML-style styling tags', () {
    const srt = '''
1
00:00:00,000 --> 00:00:01,000
<i>Hello there.</i>

2
00:00:02,000 --> 00:00:03,000
<b>Bold</b> and <font color="#ff0000">red</font> text.
''';

    final cues = SrtParser.parse(srt);
    expect(cues[0].text, 'Hello there.');
    expect(cues[1].text, 'Bold and red text.');
  });

  test('strips ASS-style override codes', () {
    const srt = '''
1
00:00:00,000 --> 00:00:01,000
{\\an8}{\\i1}Top of screen.
''';

    final cues = SrtParser.parse(srt);
    expect(cues.single.text, 'Top of screen.');
  });

  test('strips tags spanning a multi-line cue without merging the lines', () {
    const srt = '''
1
00:00:00,000 --> 00:00:02,000
<i>Line one</i>
<i>Line two</i>
''';

    final cues = SrtParser.parse(srt);
    expect(cues.single.text, 'Line one\nLine two');
  });
}
