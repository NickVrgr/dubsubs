// Params below are named for callers (getCues/getPosition/onNudge) but
// backed by private fields, so `this.` initializing formals — which would
// force the external name to match the private field name — can't be used.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:record/record.dart';

import '../models/subtitle_cue.dart';

/// Best-effort drift assist based on voice-activity detection (VAD).
///
/// This does **not** do speech recognition or audio fingerprinting — it
/// can't, since the phone mic hears the room's spoken (dubbed) audio while
/// the subtitles are a different language and there's no reference track to
/// match against. All it does is notice "someone started talking around
/// now" (a silence→speech transition) and, if that moment lines up closely
/// with a subtitle cue that's about to start, nudge the timeline so they
/// align. Manual tap-to-sync ([SubtitleClock.syncLineNow]) stays the
/// reliable primary sync method; this only tightens drift between taps.
///
/// Raw audio is never written to disk or sent anywhere — only its
/// amplitude (loudness) is inspected, in memory, in real time.
class MicSyncService extends ChangeNotifier {
  MicSyncService({
    required List<SubtitleCue> Function() getCues,
    required Duration Function() getPosition,
    required void Function(Duration appliedDelta) onNudge,
  }) : _getCues = getCues,
       _getPosition = getPosition,
       _onNudge = onNudge;

  final List<SubtitleCue> Function() _getCues;
  final Duration Function() _getPosition;
  final void Function(Duration appliedDelta) _onNudge;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _ampSub;
  StreamSubscription<List<int>>? _streamSub;

  bool _listening = false;
  bool get isListening => _listening;

  String? _lastError;
  String? get lastError => _lastError;

  bool _isSpeaking = false;

  // Hysteresis thresholds in dBFS, tuned for typical cinema ambient volume.
  static const double _speechThresholdDb = -30;
  static const double _silenceThresholdDb = -38;

  // How close a detected speech onset must be to an upcoming cue's start
  // to count as "this is that line", and how often we're willing to nudge.
  static const _toleranceWindow = Duration(milliseconds: 2500);
  static const _minNudgeMagnitude = Duration(milliseconds: 150);
  static const _minNudgeInterval = Duration(seconds: 4);
  DateTime? _lastNudgeAt;

  Future<bool> start() async {
    if (_listening) return true;
    _lastError = null;

    if (!kIsWeb) {
      final status = await ph.Permission.microphone.status;
      if (status.isPermanentlyDenied) {
        _lastError =
            'Microphone permission was denied. Enable it in system settings to use sync assist.';
        notifyListeners();
        return false;
      }
    }

    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _lastError = 'Microphone permission denied.';
        notifyListeners();
        return false;
      }

      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          numChannels: 1,
          sampleRate: 16000,
        ),
      );
      // Audio bytes themselves are discarded — only amplitude is used.
      _streamSub = stream.listen((_) {});

      _ampSub = _recorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen(_onAmplitude);

      _isSpeaking = false;
      _lastNudgeAt = null;
      _listening = true;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = 'Could not access microphone: $e';
      _listening = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    if (!_listening) return;
    await _ampSub?.cancel();
    await _streamSub?.cancel();
    _ampSub = null;
    _streamSub = null;
    try {
      await _recorder.stop();
    } catch (_) {
      // Already stopped or never fully started — safe to ignore.
    }
    _listening = false;
    notifyListeners();
  }

  void _onAmplitude(Amplitude amp) {
    final db = amp.current;
    if (!_isSpeaking && db > _speechThresholdDb) {
      _isSpeaking = true;
      _maybeNudge();
    } else if (_isSpeaking && db < _silenceThresholdDb) {
      _isSpeaking = false;
    }
  }

  void _maybeNudge() {
    final now = DateTime.now();
    if (_lastNudgeAt != null && now.difference(_lastNudgeAt!) < _minNudgeInterval) {
      return;
    }

    final position = _getPosition();
    SubtitleCue? nearest;
    Duration? nearestDelta;

    for (final cue in _getCues()) {
      final delta = cue.start - position;
      if (delta > _toleranceWindow) break; // cues are sorted by start
      if (delta.abs() <= _toleranceWindow) {
        if (nearestDelta == null || delta.abs() < nearestDelta.abs()) {
          nearest = cue;
          nearestDelta = delta;
        }
      }
    }

    if (nearest != null &&
        nearestDelta != null &&
        nearestDelta.abs() >= _minNudgeMagnitude) {
      _onNudge(nearestDelta);
      _lastNudgeAt = now;
    }
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _streamSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }
}
