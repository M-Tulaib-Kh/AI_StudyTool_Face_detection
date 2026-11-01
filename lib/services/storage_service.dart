import 'dart:io';
// ignore: unnecessary_import
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';

enum StorageBucket { avatars, lectureFiles, assignmentFiles, submissions }

extension StorageBucketX on StorageBucket {
  String get name => switch (this) {
        StorageBucket.avatars => 'avatars',
        StorageBucket.lectureFiles => 'lecture-files',
        StorageBucket.assignmentFiles => 'assignment-files',
        StorageBucket.submissions => 'submissions',
      };
  bool get isPublic => this == StorageBucket.avatars;
}

class StorageService {
  static final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));
  static const _uuid = Uuid();

  // ── File size limit: 50MB ────────────────────────────────────
  static const int maxFileSizeBytes = 50 * 1024 * 1024;

  static Future<Uint8List> _readBytes(PlatformFile file) async {
    if (file.bytes != null) return file.bytes!;
    if (file.path != null) return File(file.path!).readAsBytes();
    throw Exception('Cannot read file: no bytes or path available.');
  }

  static void _validateFile(PlatformFile file) {
    final size = file.size;
    if (size > maxFileSizeBytes) {
      throw Exception(
          'File too large. Maximum size is ${maxFileSizeBytes ~/ 1024 ~/ 1024}MB.');
    }
    final ext = (file.extension ?? '').toLowerCase();
    const allowedExtensions = [
      'pdf',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'zip',
      'jpg',
      'jpeg',
      'png',
      'webp',
      'mp4'
    ];
    if (ext.isNotEmpty && !allowedExtensions.contains(ext)) {
      throw Exception('File type .$ext is not allowed.');
    }
  }

  /// Pick document file
  static Future<PlatformFile?> pickFile({
    List<String> extensions = const ['pdf', 'doc', 'docx'],
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      allowMultiple: false,
      withData: kIsWeb,
      withReadStream: false,
    );
    return result?.files.firstOrNull;
  }

  /// Pick image file
  static Future<PlatformFile?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );
    return result?.files.firstOrNull;
  }

  /// Upload file with validation and progress
  static Future<({String fileUrl, String storagePath})> uploadFile({
    required PlatformFile file,
    required StorageBucket bucket,
    required String userId,
    void Function(double)? onProgress,
  }) async {
    _validateFile(file);

    final ext = (file.extension ?? 'pdf').toLowerCase();
    final path = '$userId/${_uuid.v4()}.$ext';
    final bytes = await _readBytes(file);

    await SupabaseConfig.storage.from(bucket.name).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _mime(ext), upsert: false),
          retryAttempts: 3,
        );

    onProgress?.call(1.0);

    final url = bucket.isPublic
        ? SupabaseConfig.storage.from(bucket.name).getPublicUrl(path)
        : await SupabaseConfig.storage
            .from(bucket.name)
            .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year

    return (fileUrl: url, storagePath: path);
  }

  /// Get a fresh signed URL for private files
  static Future<String> getSignedUrl(
    StorageBucket bucket,
    String storagePath, {
    int expiresInSeconds = 3600,
  }) async {
    if (bucket.isPublic) {
      return SupabaseConfig.storage.from(bucket.name).getPublicUrl(storagePath);
    }
    return SupabaseConfig.storage
        .from(bucket.name)
        .createSignedUrl(storagePath, expiresInSeconds);
  }

  /// Download with Dio progress tracking
  static Future<String> downloadFile({
    required String url,
    required String fileName,
    void Function(double)? onProgress,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
          'Download not supported on web — use url_launcher instead.');
    }
    final dir = await getApplicationDocumentsDirectory();
    final savePath = '${dir.path}/$fileName';
    await _dio.download(
      url,
      savePath,
      options: Options(receiveTimeout: const Duration(minutes: 5)),
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress?.call(received / total);
      },
    );
    return savePath;
  }

  /// Delete file from storage
  static Future<void> deleteFile(StorageBucket bucket, String storagePath) =>
      SupabaseConfig.storage.from(bucket.name).remove([storagePath]);

  static String _mime(String ext) => switch (ext) {
        'pdf' => 'application/pdf',
        'doc' => 'application/msword',
        'docx' =>
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'ppt' => 'application/vnd.ms-powerpoint',
        'pptx' =>
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'zip' => 'application/zip',
        'mp4' => 'video/mp4',
        _ => 'application/octet-stream',
      };
}
