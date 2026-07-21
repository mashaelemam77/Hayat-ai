import 'package:url_launcher/url_launcher.dart';

Future<bool> openStoredAudio(String value) async {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return false;

  final uri = Uri.tryParse(trimmed);
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
