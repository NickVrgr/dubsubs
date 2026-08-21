import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../services/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _colorOptions = <Color>[
    Colors.white,
    Colors.yellow,
    Colors.cyanAccent,
    Colors.greenAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
  ];

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<SettingsController>();
    final settings = controller.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Subtitle appearance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Font size: ${settings.fontSize.round()}'),
          Slider(
            value: settings.fontSize,
            min: 16,
            max: 64,
            divisions: 24,
            label: settings.fontSize.round().toString(),
            onChanged: (v) => controller.update((s) => s.copyWith(fontSize: v)),
          ),
          const SizedBox(height: 16),
          const Text('Font color'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            children: _colorOptions.map((c) {
              final selected = c.toARGB32() == settings.fontColor.toARGB32();
              return GestureDetector(
                onTap: () => controller.update((s) => s.copyWith(fontColor: c)),
                child: CircleAvatar(
                  backgroundColor: c,
                  radius: 18,
                  child: selected ? const Icon(Icons.check, color: Colors.black) : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text('Background darkness: ${(settings.backgroundOpacity * 100).round()}%'),
          Slider(
            value: settings.backgroundOpacity,
            onChanged: (v) => controller.update((s) => s.copyWith(backgroundOpacity: v)),
          ),
          const SizedBox(height: 24),
          const Text('Position on screen'),
          const SizedBox(height: 8),
          SegmentedButton<SubtitlePosition>(
            segments: const [
              ButtonSegment(
                value: SubtitlePosition.bottom,
                label: Text('Bottom'),
                icon: Icon(Icons.vertical_align_bottom),
              ),
              ButtonSegment(
                value: SubtitlePosition.top,
                label: Text('Top'),
                icon: Icon(Icons.vertical_align_top),
              ),
            ],
            selected: {settings.position},
            onSelectionChanged: (s) =>
                controller.update((old) => old.copyWith(position: s.first)),
          ),
          const SizedBox(height: 24),
          const Text('Preview'),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            alignment: Alignment.center,
            child: Text(
              'Preview subtitle',
              style: TextStyle(color: settings.fontColor, fontSize: settings.fontSize),
            ),
          ),
        ],
      ),
    );
  }
}
