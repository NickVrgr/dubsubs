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
    required this.onScanStart,
    required this.onScanEnd,
    required this.onSeek,
    required this.onToggleMic,
    required this.isLandscape,
    required this.onToggleRotation,
  });

  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final bool micListening;
  final VoidCallback onPlayPause;
  final void Function(Duration delta) onJump;
  final void Function(bool forward) onScanStart;
  final VoidCallback onScanEnd;
  final void Function(Duration target) onSeek;
  final VoidCallback onToggleMic;
  final bool isLandscape;
  final VoidCallback onToggleRotation;

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
              _HoldSeekButton(
                forward: false,
                onTap: () => onJump(const Duration(seconds: -1)),
                onHoldStart: () => onScanStart(false),
                onHoldEnd: onScanEnd,
              ),
              IconButton(
                iconSize: 40,
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                  color: Colors.white,
                ),
                onPressed: onPlayPause,
              ),
              _HoldSeekButton(
                forward: true,
                onTap: () => onJump(const Duration(seconds: 1)),
                onHoldStart: () => onScanStart(true),
                onHoldEnd: onScanEnd,
              ),
              const SizedBox(width: 4),
              _compactIcon(
                micListening ? Icons.mic : Icons.mic_none,
                micListening ? 'Sync assist on' : 'Sync assist off',
                onToggleMic,
                color: micListening ? Colors.redAccent : Colors.white,
              ),
              _compactIcon(
                isLandscape ? Icons.screen_lock_rotation : Icons.screen_rotation,
                isLandscape ? 'Switch to portrait' : 'Rotate screen',
                onToggleRotation,
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

/// Rewind/fast-forward button: a tap jumps 1s, holding scans through the
/// timeline at increasing speed until released. Labelled "1s" so the tap
/// behaviour is visible without a tooltip — on touch screens a tooltip
/// would only appear on long-press, which is taken by scanning.
class _HoldSeekButton extends StatelessWidget {
  const _HoldSeekButton({
    required this.forward,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  final bool forward;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  @override
  Widget build(BuildContext context) {
    final label = forward
        ? 'Forward 1s (hold to fast-forward)'
        : 'Back 1s (hold to rewind)';
    return Tooltip(
      message: label,
      // Hover-only (desktop/web): long-press is reserved for scanning.
      triggerMode: TooltipTriggerMode.manual,
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkResponse(
          radius: 20,
          onTap: onTap,
          child: GestureDetector(
            onLongPressStart: (_) => onHoldStart(),
            onLongPressEnd: (_) => onHoldEnd(),
            onLongPressCancel: onHoldEnd,
            child: SizedBox(
              width: 40,
              height: 40,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    forward ? Icons.fast_forward : Icons.fast_rewind,
                    color: Colors.white,
                    size: 22,
                  ),
                  const Text(
                    '1s',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
