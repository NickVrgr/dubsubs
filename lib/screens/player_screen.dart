import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
    super.dispose();
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
        SnackBar(content: Text(_micSync.lastError ?? 'Could not start sync assist.')),
      );
    }
    setState(() {});
  }

  void _openSyncPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SyncLineList(
        cues: _clock.cues,
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _controlsVisible = !_controlsVisible),
        child: Stack(
          children: [
            Positioned.fill(
              child: ListenableBuilder(
                listenable: _clock,
                builder: (context, _) => SubtitleOverlay(
                  text: _clock.currentCue?.text,
                  settings: settings,
                ),
              ),
            ),
            SafeArea(
              child: AnimatedOpacity(
                opacity: _controlsVisible ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_controlsVisible,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                widget.document.name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings, color: Colors.white),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      ListenableBuilder(
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
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
