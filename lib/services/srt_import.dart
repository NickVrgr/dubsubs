import 'dart:convert';
import 'dart:typed_data';

import '../models/subtitle_document.dart';
import 'library_controller.dart';
import 'srt_parser.dart';

/// Result of [importSrtBytes]: either the imported [document], or an
/// [errorMessage] describing why the bytes weren't a valid .srt file.
class SrtImportResult {
  const SrtImportResult.success(this.document) : errorMessage = null;
  const SrtImportResult.failure(this.errorMessage) : document = null;

  final SubtitleDocument? document;
  final String? errorMessage;
}

/// Decodes raw subtitle file [bytes] (trying UTF-8, then falling back to
/// Latin-1) and imports them into [library] under a name derived from
/// [fileName].
Future<SrtImportResult> importSrtBytes({
  required LibraryController library,
  required String fileName,
  required Uint8List bytes,
}) async {
  String content;
  try {
    content = utf8.decode(bytes);
  } catch (_) {
    content = latin1.decode(bytes);
  }

  final name = fileName.replaceAll(RegExp(r'\.srt$', caseSensitive: false), '');

  try {
    final doc = await library.importSrt(name: name, rawSrtText: content);
    return SrtImportResult.success(doc);
  } on SrtParseException catch (e) {
    return SrtImportResult.failure('Not a valid .srt file: ${e.message}');
  }
}
