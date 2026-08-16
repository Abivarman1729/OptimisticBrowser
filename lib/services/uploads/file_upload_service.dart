import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class UploadRequest {
  const UploadRequest({
    required this.accept,
    required this.multiple,
    this.capture,
  });

  final List<String> accept;
  final bool multiple;
  final String? capture;
}

class UploadResult {
  const UploadResult({
    required this.files,
    this.cancelled = false,
  });

  final List<File> files;
  final bool cancelled;
}

class FileUploadService {
  const FileUploadService();

  static const MethodChannel _channel =
      MethodChannel('optimistic_browser/file_upload');

  Future<UploadResult> pick(UploadRequest request) async {
    final raw = await _channel.invokeMethod<List<dynamic>>('pickFiles', {
      'accept': request.accept,
      'multiple': request.multiple,
      'capture': request.capture,
    });

    if (raw == null || raw.isEmpty) {
      return const UploadResult(files: <File>[], cancelled: true);
    }

    final files = raw
        .whereType<String>()
        .where((path) => path.isNotEmpty)
        .map(File.new)
        .where((file) => file.existsSync())
        .toList(growable: false);

    return UploadResult(files: files, cancelled: files.isEmpty);
  }

  bool accepts(String fileName, List<String> mimeTypes) {
    if (mimeTypes.isEmpty || mimeTypes.contains('*/*')) return true;
    final extension = fileName.toLowerCase().split('.').last;
    final image = {'png', 'jpg', 'jpeg', 'gif', 'webp'};
    final text = {'txt', 'csv', 'json', 'xml'};
    for (final mime in mimeTypes) {
      if (mime == 'image/*' && image.contains(extension)) return true;
      if (mime == 'text/*' && text.contains(extension)) return true;
      if (mime.endsWith('/$extension')) return true;
    }
    return false;
  }
}
