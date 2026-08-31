import 'package:flutter/material.dart';

import '../models/subtitle_cue.dart';
import '../services/subtitle_clock.dart';

/// Bottom sheet listing every subtitle line so the user can tap the one
/// being spoken right now to snap the timeline to it — the reliable manual
/// sync method. The line matching the clock's live position is highlighted
/// and kept roughly centered as playback advances.
class SyncLineList extends StatefulWidget {
  const SyncLineList({super.key, required this.clock, required this.onPick});

  final SubtitleClock clock;
  final void Function(SubtitleCue cue) onPick;

  @override
  State<SyncLineList> createState() => _SyncLineListState();
}

class _SyncLineListState extends State<SyncLineList> {
  static const _rowExtent = 68.0;

  ScrollController? _scrollController;
  int? _highlightedIndex;

  @override
  void initState() {
    super.initState();
    _highlightedIndex = _indexOf(widget.clock.currentCue);
    widget.clock.addListener(_onClockTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerCurrent(animate: false));
  }

  @override
  void dispose() {
    widget.clock.removeListener(_onClockTick);
    super.dispose();
  }

  int? _indexOf(SubtitleCue? cue) {
    if (cue == null) return null;
    final i = widget.clock.cues.indexOf(cue);
    return i < 0 ? null : i;
  }

  void _onClockTick() {
    final index = _indexOf(widget.clock.currentCue);
    if (index == _highlightedIndex) return;
    setState(() => _highlightedIndex = index);
    _centerCurrent();
  }

  void _centerCurrent({bool animate = true}) {
    final controller = _scrollController;
    final index = _highlightedIndex;
    if (controller == null || index == null || !controller.hasClients) return;
    final viewport = controller.position.viewportDimension;
    final target = (index * _rowExtent) - (viewport / 2) + (_rowExtent / 2);
    final clamped = target.clamp(0.0, controller.position.maxScrollExtent);
    if (animate) {
      controller.animateTo(clamped, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      controller.jumpTo(clamped);
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final cues = widget.clock.cues;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
        _scrollController = controller;
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                "Tap the line as it's spoken",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemExtent: _rowExtent,
                itemCount: cues.length,
                itemBuilder: (context, i) {
                  final cue = cues[i];
                  final isCurrent = i == _highlightedIndex;
                  return Material(
                    color: isCurrent
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    child: ListTile(
                      dense: true,
                      selected: isCurrent,
                      title: Text(
                        cue.text,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: isCurrent ? const TextStyle(fontWeight: FontWeight.bold) : null,
                      ),
                      subtitle: Text(_fmt(cue.start)),
                      onTap: () => widget.onPick(cue),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
