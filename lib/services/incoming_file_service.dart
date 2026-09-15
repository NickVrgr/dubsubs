import 'package:flutter/services.dart';

/// A file handed to the app by the OS (e.g. tapping an .srt file in a file
/// manager or email client) via the native "open with DubSubs" integration.
class IncomingFile {
  const IncomingFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

/// Bridges to the native `open_file` MethodChannel (see MainActivity.kt and
/// OpenFilePlugin.swift) that delivers .srt files opened from outside the
/// app.
class IncomingFileService {
  IncomingFileService._();

  static const _channel = MethodChannel('com.vargar.dubsubs/open_file');

  /// The file the app was launched with, if it was cold-started by opening
  /// an .srt file. Returns null otherwise, and only ever returns a given
  /// file once.
  static Future<IncomingFile?> takeInitialFile() async {
    final result = await _channel.invokeMethod<Map<Object?, Object?>>('getInitialFile');
    return _toIncomingFile(result);
  }

  /// Calls [onFile] whenever an .srt file is opened while the app is already
  /// running.
  static void listen(void Function(IncomingFile file) onFile) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onFileOpened') return;
      final file = _toIncomingFile(call.arguments as Map<Object?, Object?>?);
      if (file != null) onFile(file);
    });
  }

  static IncomingFile? _toIncomingFile(Map<Object?, Object?>? raw) {
    if (raw == null) return null;
    final name = raw['name'] as String?;
    final bytes = raw['bytes'] as Uint8List?;
    if (name == null || bytes == null) return null;
    return IncomingFile(name: name, bytes: bytes);
  }
}
