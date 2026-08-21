import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/subtitle_cue.dart';

/// Drives subtitle playback against a wall-clock timer that the user
/// controls — there is no video file underneath, the movie is playing on a
/// separate screen (cinema/TV), so this is effectively a synced
/// teleprompter: play/pause, jump by a fixed offset, seek, or snap to a
/// specific line.
class SubtitleClock extends ChangeNotifier {
  List<SubtitleCue> _cues = const [];
  Duration _position = Duration.zero;
  DateTime? _anchorWallTime;
  Timer? _ticker;

  List<SubtitleCue> get cues => _cues;
  bool get isPlaying => _anchorWallTime != null;
  Duration get duration =>
      _cues.isEmpty ? Duration.zero : _cues.last.end;

  /// Current subtitle-timeline position, computed live while playing.
  Duration get position {
    if (_anchorWallTime == null) return _position;
    return _position + DateTime.now().difference(_anchorWallTime!);
  }

  SubtitleCue? get currentCue => _findCueAt(position);

  void loadCues(List<SubtitleCue> cues) {
    _stopTicker();
    _cues = List.of(cues)..sort((a, b) => a.start.compareTo(b.start));
    _position = Duration.zero;
    _anchorWallTime = null;
    notifyListeners();
  }

  void play() {
    if (isPlaying || _cues.isEmpty) return;
    _anchorWallTime = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!isPlaying) return;
    _position = position;
    _anchorWallTime = null;
    _stopTicker();
    notifyListeners();
  }

  void togglePlayPause() => isPlaying ? pause() : play();

  /// Jumps to an absolute point on the subtitle timeline (used by the
  /// scrubber and "tap to sync" line picker). Clamped to zero.
  void seekTo(Duration target) {
    final clamped = target.isNegative ? Duration.zero : target;
    _position = clamped;
    if (isPlaying) _anchorWallTime = DateTime.now();
    notifyListeners();
  }

  /// Relative seek — powers the -10s/-2s/+2s/+10s buttons and mic-assisted
  /// drift nudges alike.
  void jumpBy(Duration delta) => seekTo(position + delta);

  /// Aligns [cue]'s start time with "now" on the timeline — the manual,
  /// reliable sync method: tap a line right as it's spoken on screen.
  void syncLineNow(SubtitleCue cue) => seekTo(cue.start);

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => notifyListeners(),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  SubtitleCue? _findCueAt(Duration t) {
    if (_cues.isEmpty) return null;
    var low = 0;
    var high = _cues.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final cue = _cues[mid];
      if (t < cue.start) {
        high = mid - 1;
      } else if (t >= cue.end) {
        low = mid + 1;
      } else {
        return cue;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }
}
