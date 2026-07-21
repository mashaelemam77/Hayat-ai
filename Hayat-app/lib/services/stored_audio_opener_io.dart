import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<bool> openStoredAudio(String value) async {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;

  if (trimmed.startsWith('data:audio/')) {
    final commaIndex = trimmed.indexOf(',');
    if (commaIndex <= 0) return false;

    final header = trimmed.substring(0, commaIndex);
    final base64Data = trimmed.substring(commaIndex + 1);
    final mimeTypeEnd = header.indexOf(';');
    final mimeType = mimeTypeEnd > 5
        ? header.substring(5, mimeTypeEnd)
        : 'audio/mp4';
    final bytes = base64Decode(base64Data);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/hayat_voice_${DateTime.now().millisecondsSinceEpoch}.${_extensionForMime(mimeType)}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
  }

  if (trimmed.startsWith('http://') ||
      trimmed.startsWith('https://') ||
      trimmed.startsWith('blob:')) {
    final uri = Uri.tryParse(trimmed);
    if (uri == null) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  return launchUrl(Uri.file(trimmed), mode: LaunchMode.externalApplication);
}

String _extensionForMime(String mimeType) {
  return switch (mimeType.toLowerCase()) {
    'audio/webm' => 'webm',
    'audio/wav' || 'audio/x-wav' => 'wav',
    'audio/mpeg' || 'audio/mp3' => 'mp3',
    'audio/aac' => 'aac',
    'audio/x-m4a' || 'audio/mp4' => 'm4a',
    _ => 'm4a',
  };
}
