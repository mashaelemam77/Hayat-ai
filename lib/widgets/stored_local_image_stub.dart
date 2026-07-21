import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../services/api_service.dart';

Widget buildStoredLocalImage(
  String path,
  Widget Function(String path) missingBuilder,
) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return missingBuilder(path);

  final lower = trimmed.toLowerCase();

  if (lower.startsWith('data:image')) {
    final bytes = _bytesFromDataImage(trimmed);
    if (bytes == null || bytes.isEmpty) return missingBuilder(path);

    return Image.memory(
      bytes,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => missingBuilder(path),
    );
  }

  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return Image.network(
      trimmed,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => missingBuilder(path),
    );
  }

  if (_isOnlyImageFileName(trimmed)) {
    return _NetworkImageCandidates(
      fileName: trimmed,
      missingBuilder: missingBuilder,
    );
  }

  return missingBuilder(path);
}

bool _isOnlyImageFileName(String value) {
  final lower = value.toLowerCase();
  final hasImageExtension = lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp');
  final hasNoPath = !value.contains('/') && !value.contains('\\');
  return hasImageExtension && hasNoPath;
}

Uint8List? _bytesFromDataImage(String value) {
  final commaIndex = value.indexOf(',');
  if (commaIndex == -1 || commaIndex + 1 >= value.length) return null;

  final base64Part = value.substring(commaIndex + 1).trim();
  if (base64Part.isEmpty) return null;

  try {
    return base64Decode(base64Part);
  } catch (_) {
    return null;
  }
}

class _NetworkImageCandidates extends StatefulWidget {
  const _NetworkImageCandidates({
    required this.fileName,
    required this.missingBuilder,
  });

  final String fileName;
  final Widget Function(String path) missingBuilder;

  @override
  State<_NetworkImageCandidates> createState() => _NetworkImageCandidatesState();
}

class _NetworkImageCandidatesState extends State<_NetworkImageCandidates> {
  int _index = 0;

  List<String> get _urls {
    final encoded = Uri.encodeComponent(widget.fileName);
    final urls = <String>[];
    final supabaseUrl = ApiService.supabaseUrl.trim();

    if (supabaseUrl.isNotEmpty) {
      final base = supabaseUrl.endsWith('/')
          ? supabaseUrl.substring(0, supabaseUrl.length - 1)
          : supabaseUrl;
      final buckets = [
        'uploads',
        'reports',
        'report-images',
        'report_images',
        'images',
        'attachments',
        'files',
        'public',
      ];

      for (final bucket in buckets) {
        urls.add('$base/storage/v1/object/public/$bucket/$encoded');
        urls.add('$base/storage/v1/object/public/$bucket/uploads/$encoded');
        urls.add('$base/storage/v1/object/public/$bucket/reports/$encoded');
        urls.add('$base/storage/v1/object/public/$bucket/images/$encoded');
      }
    }

    urls.addAll([
      'http://127.0.0.1:8000/uploads/$encoded',
      'http://localhost:8000/uploads/$encoded',
      'http://127.0.0.1:5000/uploads/$encoded',
      'http://localhost:5000/uploads/$encoded',
      'http://127.0.0.1:8080/uploads/$encoded',
      'http://localhost:8080/uploads/$encoded',
    ]);

    return urls;
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;

    if (_index >= urls.length) {
      return widget.missingBuilder(widget.fileName);
    }

    final url = urls[_index];

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _index++);
        });
        return widget.missingBuilder(widget.fileName);
      },
    );
  }
}
