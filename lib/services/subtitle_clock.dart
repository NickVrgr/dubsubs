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

  /// Scan (hold-to-fast-forward/rewind) state. While scanning, the ticker
  /// advances [_position] itself at [scanSpeed]× real time, and
  /// [_resumeAfterScan] remembers whether to keep playing on release.
  DateTime? _scanStart;
  DateTime? _lastScanTick;
  bool _scanForward = true;
  bool _resumeAfterScan = false;

  /// How long each scan speed step lasts before doubling.
  static const scanStepDuration = Duration(seconds: 1);
  static const scanSpeeds = [2, 4, 8, 16];

  List<SubtitleCue> get cues => _cues;

  /// Whether the timeline is (or, mid-scan, will resume) playing.
  bool get isPlaying => isScanning ? _resumeAfterScan : _anchorWallTime != null;

  bool get isScanning => _scanStart != null;
  bool get isScanningForward => _scanForward;

  /// Current scan multiplier (2×, 4×, 8×, 16×), ramping up the longer the
  /// scan is held; null when not scanning.
  int? get scanSpeed {
    if (_scanStart == null) return null;
    final held = DateTime.now().difference(_scanStart!);
    final step = held.inMilliseconds ~/ scanStepDuration.inMilliseconds;
    return scanSpeeds[step.clamp(0, scanSpeeds.length - 1)];
  }
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
    _scanStart = null;
    _lastScanTick = null;
    notifyListeners();
  }

  void play() {
    if (isPlaying || _cues.isEmpty) return;
    if (isScanning) {
      _resumeAfterScan = true;
      notifyListeners();
      return;
    }
    _anchorWallTime = DateTime.now();
    _startTicker();
    notifyListeners();
  }

  void pause() {
    if (!isPlaying) return;
    if (isScanning) {
      _resumeAfterScan = false;
      notifyListeners();
      return;
    }
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
    if (_anchorWallTime != null) _anchorWallTime = DateTime.now();
    notifyListeners();
  }

  /// Starts running the timeline at a multiple of real time (forward or
  /// backward), ramping up through [scanSpeeds] for as long as the scan is
  /// held — lines still appear in order, just briefly, so the user can
  /// watch them fly past and let go at the one being spoken.
  void startScan({required bool forward}) {
    if (_cues.isEmpty) return;
    if (isScanning) stopScan();
    _resumeAfterScan = _anchorWallTime != null;
    _position = position;
    _anchorWallTime = null;
    _scanForward = forward;
    final now = DateTime.now();
    _scanStart = now;
    _lastScanTick = now;
    _ticker?.cancel();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _advanceScan(),
    );
    notifyListeners();
  }

  /// Ends a scan and returns to normal speed, resuming playback if it was
  /// playing (or play was pressed) during the scan.
  void stopScan() {
    if (!isScanning) return;
    _advanceScan(notify: false);
    _stopTicker();
    _scanStart = null;
    _lastScanTick = null;
    if (_resumeAfterScan) {
      _anchorWallTime = DateTime.now();
      _startTicker();
    }
    notifyListeners();
  }

  void _advanceScan({bool notify = true}) {
    final now = DateTime.now();
    final elapsed = now.difference(_lastScanTick!);
    _lastScanTick = now;
    final delta = elapsed * scanSpeed! * (_scanForward ? 1 : -1);
    var next = _position + delta;
    if (next.isNegative) next = Duration.zero;
    if (next > duration) next = duration;
    _position = next;
    if (notify) notifyListeners();
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
