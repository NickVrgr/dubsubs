import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subtitle_cue.dart';
import '../models/subtitle_document.dart';
import '../services/mic_sync_service.dart';
import '../services/settings_controller.dart';
import '../services/srt_parser.dart';
import '../services/subtitle_clock.dart';
import '../widgets/subtitle_overlay.dart';
import '../widgets/sync_line_list.dart';
import '../widgets/transport_controls.dart';
import 'settings_screen.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key, required this.document});

  final SubtitleDocument document;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final SubtitleClock _clock;
  late final MicSyncService _micSync;
  bool _controlsVisible = true;
  String? _parseError;

  bool _showSeekFeedback = false;
  bool _seekFeedbackForward = true;
  Timer? _seekFeedbackTimer;

  @override
  void initState() {
    super.initState();
    _clock = SubtitleClock();
    _micSync = MicSyncService(
      getCues: () => _clock.cues,
      getPosition: () => _clock.position,
      onNudge: _handleNudge,
    );

    try {
      _clock.loadCues(SrtParser.parse(widget.document.rawSrtText));
    } on SrtParseException catch (e) {
      _parseError = e.message;
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    _micSync.dispose();
    _seekFeedbackTimer?.cancel();
    super.dispose();
  }

  /// Double-tapping the left/right half of the screen jumps back/forward by
  /// one second, same as the transport buttons — Prime-Video-style seeking.
  void _handleDoubleTapSeek(TapDownDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final forward = details.localPosition.dx > width / 2;
    _clock.jumpBy(Duration(seconds: forward ? 1 : -1));

    _seekFeedbackTimer?.cancel();
    setState(() {
      _seekFeedbackForward = forward;
      _showSeekFeedback = true;
    });
    _seekFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _showSeekFeedback = false);
    });
  }

  void _handleNudge(Duration delta) {
    _clock.jumpBy(delta);
    if (!mounted) return;
    final ms = delta.inMilliseconds;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sync assist: ${ms >= 0 ? '+' : ''}${ms}ms'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _toggleMicSync() async {
    if (_micSync.isListening) {
      await _micSync.stop();
      setState(() {});
      return;
    }
    final ok = await _micSync.start();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_micSync.lastError ?? 'Could not start sync assist.'),
        ),
      );
    }
    setState(() {});
  }

  /// Prefers the cached translation for the current cue; falls back to the
  /// original-language line whenever no translation is cached (or it
  /// couldn't be produced) so the teleprompter never blanks out — see
  /// SubtitleDocument.translationStatus.
  String? _displayTextFor(SubtitleCue? cue) {
    if (cue == null) return null;
    final translated = widget.document.translatedLines;
    if (widget.document.translationStatus == TranslationStatus.done &&
        translated != null) {
      final index = _clock.cues.indexOf(cue);
      if (index >= 0 && index < translated.length) return translated[index];
    }
    return cue.text;
  }

  void _openSyncPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SyncLineList(
        clock: _clock,
        onPick: (cue) {
          _clock.syncLineNow(cue);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_parseError != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.document.name)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Could not read this subtitle file:\n$_parseError'),
          ),
        ),
      );
    }

    final settings = context.watch<SettingsController>().settings;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: !_controlsVisible
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              widget.document.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.settings,
                              color: Colors.white,
                            ),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    setState(() => _controlsVisible = !_controlsVisible),
                onDoubleTapDown: _handleDoubleTapSeek,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ListenableBuilder(
                        listenable: _clock,
                        builder: (context, _) => SubtitleOverlay(
                          text: _displayTextFor(_clock.currentCue),
                          settings: settings,
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: _SeekFeedback(
                        forward: _seekFeedbackForward,
                        visible: _showSeekFeedback,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: !_controlsVisible
                  ? const SizedBox(width: double.infinity)
                  : ListenableBuilder(
                      listenable: Listenable.merge([_clock, _micSync]),
                      builder: (context, _) => TransportControls(
                        isPlaying: _clock.isPlaying,
                        position: _clock.position,
                        duration: _clock.duration,
                        micListening: _micSync.isListening,
                        onPlayPause: _clock.togglePlayPause,
                        onJump: _clock.jumpBy,
                        onSeek: _clock.seekTo,
                        onOpenSyncPicker: _openSyncPicker,
                        onToggleMic: _toggleMicSync,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Brief icon that flashes on the left/right half of the screen to
/// acknowledge a double-tap seek, similar to Prime Video's seek animation.
class _SeekFeedback extends StatelessWidget {
  const _SeekFeedback({required this.forward, required this.visible});

  final bool forward;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return IgnorePointer(
      child: Align(
        alignment: forward ? Alignment.centerRight : Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: 0.5,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 150),
              builder: (context, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.black45,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      forward ? Icons.fast_forward : Icons.fast_rewind,
                      color: Colors.white,
                      size: 28,
                    ),
                    const Text(
                      '1s',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
