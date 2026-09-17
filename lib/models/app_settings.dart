import 'package:flutter/material.dart';

/// User-adjustable subtitle display preferences, persisted globally.
class AppSettings {
  final double fontSize;
  final Color fontColor;
  final double backgroundOpacity;
  final bool micSyncEnabled;

  const AppSettings({
    this.fontSize = 32,
    this.fontColor = Colors.white,
    this.backgroundOpacity = 0.6,
    this.micSyncEnabled = false,
  });

  AppSettings copyWith({
    double? fontSize,
    Color? fontColor,
    double? backgroundOpacity,
    bool? micSyncEnabled,
  }) {
    return AppSettings(
      fontSize: fontSize ?? this.fontSize,
      fontColor: fontColor ?? this.fontColor,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
      micSyncEnabled: micSyncEnabled ?? this.micSyncEnabled,
    );
  }

  Map<String, dynamic> toMap() => {
    'fontSize': fontSize,
    'fontColor': fontColor.toARGB32(),
    'backgroundOpacity': backgroundOpacity,
    'micSyncEnabled': micSyncEnabled,
  };

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 32,
      fontColor: Color(map['fontColor'] as int? ?? Colors.white.toARGB32()),
      backgroundOpacity: (map['backgroundOpacity'] as num?)?.toDouble() ?? 0.6,
      micSyncEnabled: map['micSyncEnabled'] as bool? ?? false,
    );
  }
}
