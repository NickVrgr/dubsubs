import 'package:flutter/material.dart';

/// Play/pause, seek, jump-by-offset, tap-to-sync and mic-assist controls
/// shown over the subtitle display.
class TransportControls extends StatelessWidget {
  const TransportControls({
    super.key,
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.micListening,
    required this.onPlayPause,
    required this.onJump,
    required this.onSeek,
    required this.onOpenSyncPicker,
    required this.onToggleMic,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool micListening;
  final VoidCallback onPlayPause;
  final void Function(Duration delta) onJump;
  final void Function(Duration target) onSeek;
  final VoidCallback onOpenSyncPicker;
  final VoidCallback onToggleMic;

  String _fmt(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final hasDuration = duration > Duration.zero;
    final maxMs = hasDuration ? duration.inMilliseconds.toDouble() : 1.0;
    final posMs = position.inMilliseconds
        .clamp(0, hasDuration ? duration.inMilliseconds : 0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(_fmt(position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Slider(
                  value: posMs.clamp(0, maxMs),
                  max: maxMs,
                  onChanged: hasDuration
                      ? (v) => onSeek(Duration(milliseconds: v.round()))
                      : null,
                ),
              ),
              Text(_fmt(duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10, color: Colors.white),
                tooltip: 'Back 10s',
                onPressed: () => onJump(const Duration(seconds: -10)),
              ),
              IconButton(
                icon: const Icon(Icons.replay_5, color: Colors.white),
                tooltip: 'Back 5s',
                onPressed: () => onJump(const Duration(seconds: -5)),
              ),
              IconButton(
                iconSize: 52,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: onPlayPause,
              ),
              IconButton(
                icon: const Icon(Icons.forward_5, color: Colors.white),
                tooltip: 'Forward 5s',
                onPressed: () => onJump(const Duration(seconds: 5)),
              ),
              IconButton(
                icon: const Icon(Icons.forward_10, color: Colors.white),
                tooltip: 'Forward 10s',
                onPressed: () => onJump(const Duration(seconds: 10)),
              ),
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              TextButton.icon(
                onPressed: onOpenSyncPicker,
                icon: const Icon(Icons.subtitles, color: Colors.white),
                label: const Text('Tap line to sync', style: TextStyle(color: Colors.white)),
              ),
              TextButton.icon(
                onPressed: onToggleMic,
                icon: Icon(
                  micListening ? Icons.mic : Icons.mic_none,
                  color: micListening ? Colors.redAccent : Colors.white,
                ),
                label: Text(
                  micListening ? 'Sync assist on' : 'Sync assist off',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
