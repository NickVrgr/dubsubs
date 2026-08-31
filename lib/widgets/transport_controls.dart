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
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            ),
            child: Row(
              children: [
                Text(_fmt(position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Expanded(
                  child: Slider(
                    value: posMs.clamp(0, maxMs),
                    max: maxMs,
                    onChanged: hasDuration
                        ? (v) => onSeek(Duration(milliseconds: v.round()))
                        : null,
                  ),
                ),
                Text(_fmt(duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _compactIcon(Icons.replay_10, 'Back 10s', () => onJump(const Duration(seconds: -10))),
              _compactIcon(Icons.replay_5, 'Back 5s', () => onJump(const Duration(seconds: -5))),
              IconButton(
                iconSize: 40,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: onPlayPause,
              ),
              _compactIcon(Icons.forward_5, 'Forward 5s', () => onJump(const Duration(seconds: 5))),
              _compactIcon(Icons.forward_10, 'Forward 10s', () => onJump(const Duration(seconds: 10))),
              const SizedBox(width: 4),
              _compactIcon(Icons.subtitles, 'Tap line to sync', onOpenSyncPicker),
              _compactIcon(
                micListening ? Icons.mic : Icons.mic_none,
                micListening ? 'Sync assist on' : 'Sync assist off',
                onToggleMic,
                color: micListening ? Colors.redAccent : Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactIcon(
    IconData icon,
    String tooltip,
    VoidCallback onPressed, {
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      onPressed: onPressed,
    );
  }
}
