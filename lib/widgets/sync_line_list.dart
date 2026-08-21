import 'package:flutter/material.dart';

import '../models/subtitle_cue.dart';

/// Bottom sheet listing every subtitle line so the user can tap the one
/// being spoken right now to snap the timeline to it — the reliable manual
/// sync method.
class SyncLineList extends StatelessWidget {
  const SyncLineList({super.key, required this.cues, required this.onPick});

  final List<SubtitleCue> cues;
  final void Function(SubtitleCue cue) onPick;

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, controller) {
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
                itemCount: cues.length,
                itemBuilder: (context, i) {
                  final cue = cues[i];
                  return ListTile(
                    dense: true,
                    title: Text(cue.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: Text(_fmt(cue.start)),
                    onTap: () => onPick(cue),
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
