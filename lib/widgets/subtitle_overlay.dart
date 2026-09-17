import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// Renders the current subtitle line together with the line before and
/// after it — a small teleprompter crawl (previous line dimmed above,
/// current line bold and larger in the middle, next line dimmed below) so
/// the reader always has visual context for where they are, styled per
/// [AppSettings]. Always centered vertically, in both portrait and
/// landscape.
///
/// [sequence] identifies which cue is "current" (or, in a gap, which cue is
/// upcoming) as a monotonically-increasing index into the cue list. When it
/// changes, the whole block animates in as a scroll rather than a hard cut —
/// upward when [sequence] increases (normal playback / swiping forward),
/// downward when it decreases (swiping back / a backward sync nudge).
class SubtitleOverlay extends StatefulWidget {
  const SubtitleOverlay({
    super.key,
    required this.previousText,
    required this.currentText,
    required this.nextText,
    required this.settings,
    required this.sequence,
  });

  final String? previousText;
  final String? currentText;
  final String? nextText;
  final AppSettings settings;
  final int sequence;

  @override
  State<SubtitleOverlay> createState() => _SubtitleOverlayState();
}

class _SubtitleOverlayState extends State<SubtitleOverlay> {
  bool _scrollForward = true;

  @override
  void didUpdateWidget(covariant SubtitleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sequence != oldWidget.sequence) {
      _scrollForward = widget.sequence >= oldWidget.sequence;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;

    // Only lines that actually have text get a row — e.g. while paused in
    // the gap between two cues there's no current line, and reserving a
    // full-height blank slot for it looked like a broken/invisible line.
    final lines = <Widget>[];
    void addLine(String? text, {required bool current}) {
      if (text == null || text.isEmpty) return;
      if (lines.isNotEmpty) lines.add(const SizedBox(height: 6));
      lines.add(_line(text, current: current));
    }

    addLine(widget.previousText, current: false);
    addLine(widget.currentText, current: true);
    addLine(widget.nextText, current: false);

    final hasAnyLine = lines.isNotEmpty;

    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: !hasAnyLine
            ? const SizedBox.shrink()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: settings.backgroundOpacity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: _buildTransition,
                      child: Column(
                        key: ValueKey(widget.sequence),
                        mainAxisSize: MainAxisSize.min,
                        children: lines,
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// A shared slide+fade tween applied to both the outgoing and incoming
  /// children so the whole block appears to scroll past rather than swap —
  /// distinguishing the two by [animation]'s status (forward/completed for
  /// the entering child, reverse for the one leaving).
  Widget _buildTransition(Widget child, Animation<double> animation) {
    final entering = animation.status != AnimationStatus.reverse;
    final direction = _scrollForward ? 1.0 : -1.0;
    final beginOffset = entering
        ? Offset(0, 0.35 * direction)
        : Offset(0, -0.35 * direction);
    return SlideTransition(
      position: Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

  Widget _line(String? text, {required bool current}) {
    return Text(
      text ?? '',
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: current ? widget.settings.fontColor : widget.settings.fontColor.withValues(alpha: 0.5),
        fontSize: current ? widget.settings.fontSize : widget.settings.fontSize * 0.7,
        fontWeight: current ? FontWeight.w700 : FontWeight.w400,
        height: 1.25,
      ),
    );
  }
}
