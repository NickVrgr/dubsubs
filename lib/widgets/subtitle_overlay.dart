import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// Renders the current subtitle line, styled per [AppSettings].
class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({super.key, required this.text, required this.settings});

  final String? text;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    // This widget fills the space between the header and transport controls
    // (see PlayerScreen's Column), so top/bottom just biases within that
    // free area rather than pinning to the screen edge.
    final alignment = settings.position == SubtitlePosition.top
        ? Alignment.topCenter
        : Alignment.bottomCenter;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: (text == null || text!.isEmpty)
            ? const SizedBox.shrink()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: settings.backgroundOpacity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    text!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: settings.fontColor,
                      fontSize: settings.fontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
