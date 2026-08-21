import 'package:flutter_test/flutter_test.dart';
import 'package:dubsubs/models/subtitle_cue.dart';
import 'package:dubsubs/services/subtitle_clock.dart';

List<SubtitleCue> _sampleCues() => [
  const SubtitleCue(index: 1, start: Duration(seconds: 1), end: Duration(seconds: 2), text: 'One'),
  const SubtitleCue(index: 2, start: Duration(seconds: 5), end: Duration(seconds: 8), text: 'Two'),
];

void main() {
  test('starts paused at zero with no active cue', () {
    final clock = SubtitleClock()..loadCues(_sampleCues());
    expect(clock.isPlaying, isFalse);
    expect(clock.position, Duration.zero);
    expect(clock.currentCue, isNull);
    clock.dispose();
  });

  test('seekTo moves the position and selects the right cue, including gaps', () {
    final clock = SubtitleClock()..loadCues(_sampleCues());

    clock.seekTo(const Duration(seconds: 1));
    expect(clock.currentCue?.text, 'One');

    clock.seekTo(const Duration(seconds: 3)); // gap between cues
    expect(clock.currentCue, isNull);

    clock.seekTo(const Duration(seconds: 6));
    expect(clock.currentCue?.text, 'Two');

    clock.dispose();
  });

  test('seekTo clamps negative targets to zero', () {
    final clock = SubtitleClock()..loadCues(_sampleCues());
    clock.seekTo(const Duration(seconds: -5));
    expect(clock.position, Duration.zero);
    clock.dispose();
  });

  test('jumpBy applies a relative offset', () {
    final clock = SubtitleClock()..loadCues(_sampleCues());
    clock.seekTo(const Duration(seconds: 5));
    clock.jumpBy(const Duration(seconds: -2));
    expect(clock.position, const Duration(seconds: 3));
    clock.dispose();
  });

  test('syncLineNow snaps the timeline to a cue\'s start', () {
    final clock = SubtitleClock()..loadCues(_sampleCues());
    clock.syncLineNow(_sampleCues()[1]);
    expect(clock.position, const Duration(seconds: 5));
    clock.dispose();
  });

  test('play advances position with wall-clock time; pause freezes it', () async {
    final clock = SubtitleClock()..loadCues(_sampleCues());
    clock.play();
    expect(clock.isPlaying, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 150));
    clock.pause();

    expect(clock.isPlaying, isFalse);
    expect(clock.position, greaterThan(const Duration(milliseconds: 50)));
    expect(clock.position, lessThan(const Duration(seconds: 2)));

    final frozen = clock.position;
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(clock.position, frozen); // unchanged while paused

    clock.dispose();
  });

  test('togglePlayPause flips play state', () {
    final clock = SubtitleClock()..loadCues(_sampleCues());
    expect(clock.isPlaying, isFalse);
    clock.togglePlayPause();
    expect(clock.isPlaying, isTrue);
    clock.togglePlayPause();
    expect(clock.isPlaying, isFalse);
    clock.dispose();
  });
}
