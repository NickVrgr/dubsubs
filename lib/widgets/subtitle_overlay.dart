import 'package:flutter/material.dart';

import '../models/app_settings.dart';

/// Renders the current subtitle line, styled per [AppSettings].
class SubtitleOverlay extends StatelessWidget {
  const SubtitleOverlay({super.key, required this.text, required this.settings});

  final String? text;
  final AppSettings settings;

  @override
  Widget build(BuildContext context) {
    final alignment = settings.position == SubtitlePosition.top
        ? Alignment.topCenter
        : Alignment.bottomCenter;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: settings.position == SubtitlePosition.top ? 48 : 96,
        ),
        child: (text == null || text!.isEmpty)
            ? const SizedBox.shrink()
            : Container(
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
    );
  }
}
