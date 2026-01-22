import 'dart:typed_data';
import 'package:flutter/material.dart';

import '../models/photo.dart';
import '../services/photo_service.dart';
import '../services/moderation_service.dart';

/// Upload state for individual files
class UploadItem {
  final String id;
  final String fileName;
  final Uint8List bytes;
  UploadStatus status;
  double progress;
  String? error;
  Photo? uploadedPhoto;

  UploadItem({
    required this.id,
    required this.fileName,
    required this.bytes,
    this.status = UploadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.uploadedPhoto,
  });

  UploadItem copyWith({
    String? id,
    String? fileName,
    Uint8List? bytes,
    UploadStatus? status,
    double? progress,
    String? error,
    Photo? uploadedPhoto,
  }) {
    return UploadItem(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      bytes: bytes ?? this.bytes,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
      uploadedPhoto: uploadedPhoto ?? this.uploadedPhoto,
    );
  }
}

enum UploadStatus {
  pending,
  moderating,
  uploading,
  completed,
  rejected,
  failed,
}

/// Upload Provider
///
/// Manages photo upload state:
/// - Queue of files to upload
/// - Upload progress
/// - Moderation status
class UploadProvider extends ChangeNotifier {
  final PhotoService photoService;
  final ModerationService moderationService;

  UploadProvider({
    required this.photoService,
    required this.moderationService,
  });

  // Upload queue
  final List<UploadItem> _uploadQueue = [];
  List<UploadItem> get uploadQueue => List.unmodifiable(_uploadQueue);

  // Current event
  String? _eventId;
  String? _deviceId;
  String? _caption;

  // Upload state
  bool _isUploading = false;
  bool get isUploading => _isUploading;

  int get pendingCount =>
      _uploadQueue.where((item) => item.status == UploadStatus.pending).length;

  int get completedCount =>
      _uploadQueue.where((item) => item.status == UploadStatus.completed).length;

  int get rejectedCount =>
      _uploadQueue.where((item) => item.status == UploadStatus.rejected).length;

  int get failedCount =>
      _uploadQueue.where((item) => item.status == UploadStatus.failed).length;

  double get overallProgress {
    if (_uploadQueue.isEmpty) return 0.0;
    final total = _uploadQueue.fold<double>(
      0.0,
      (sum, item) => sum + item.progress,
    );
    return total / _uploadQueue.length;
  }

  /// Configure upload settings
  void configure({
    required String eventId,
    required String deviceId,
    String? caption,
  }) {
    _eventId = eventId;
    _deviceId = deviceId;
    _caption = caption;
  }

  /// Set caption for uploads
  void setCaption(String? caption) {
    _caption = caption;
  }

  /// Add files to upload queue
  void addFiles(List<MapEntry<String, Uint8List>> files) {
    for (final file in files) {
      final item = UploadItem(
        id: DateTime.now().millisecondsSinceEpoch.toString() + file.key,
        fileName: file.key,
        bytes: file.value,
      );
      _uploadQueue.add(item);
    }
    notifyListeners();
  }

  /// Add a single file to upload queue
  void addFile(String fileName, Uint8List bytes) {
    final item = UploadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString() + fileName,
      fileName: fileName,
      bytes: bytes,
    );
    _uploadQueue.add(item);
    notifyListeners();
  }

  /// Remove item from queue
  void removeItem(String id) {
    _uploadQueue.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Clear the queue
  void clearQueue() {
    _uploadQueue.clear();
    notifyListeners();
  }

  /// Clear completed items
  void clearCompleted() {
    _uploadQueue.removeWhere(
      (item) =>
          item.status == UploadStatus.completed ||
          item.status == UploadStatus.rejected,
    );
    notifyListeners();
  }

  /// Start uploading all pending items
  Future<void> startUpload() async {
    if (_isUploading || _eventId == null) return;

    _isUploading = true;
    notifyListeners();

    for (var i = 0; i < _uploadQueue.length; i++) {
      final item = _uploadQueue[i];
      if (item.status != UploadStatus.pending) continue;

      await _uploadItem(i);
    }

    _isUploading = false;
    notifyListeners();
  }

  /// Upload a single item
  Future<void> _uploadItem(int index) async {
    if (index < 0 || index >= _uploadQueue.length) return;

    final item = _uploadQueue[index];

    try {
      // Step 1: Moderation
      _updateItem(index, status: UploadStatus.moderating, progress: 0.1);

      final moderationResult = await moderationService.moderateImage(item.bytes);

      // Check if rejected by moderation
      if (!moderationResult.isSafe && !moderationResult.needsManualReview) {
        _updateItem(
          index,
          status: UploadStatus.rejected,
          progress: 1.0,
          error: moderationResult.rejectionReason ?? 'Content not allowed',
        );
        return;
      }

      // Step 2: Upload
      _updateItem(index, status: UploadStatus.uploading, progress: 0.3);

      final photo = await photoService.uploadPhoto(
        eventId: _eventId!,
        imageBytes: item.bytes,
        fileName: item.fileName,
        caption: _caption,
        deviceId: _deviceId,
        moderationResult: moderationResult,
      );

      // Step 3: Complete
      _updateItem(
        index,
        status: moderationResult.isSafe
            ? UploadStatus.completed
            : UploadStatus.rejected,
        progress: 1.0,
        uploadedPhoto: photo,
      );
    } catch (e) {
      _updateItem(
        index,
        status: UploadStatus.failed,
        error: e.toString(),
      );
    }
  }

  /// Update item state
  void _updateItem(
    int index, {
    UploadStatus? status,
    double? progress,
    String? error,
    Photo? uploadedPhoto,
  }) {
    if (index < 0 || index >= _uploadQueue.length) return;

    _uploadQueue[index] = _uploadQueue[index].copyWith(
      status: status,
      progress: progress,
      error: error,
      uploadedPhoto: uploadedPhoto,
    );
    notifyListeners();
  }

  /// Retry failed upload
  Future<void> retryItem(String id) async {
    final index = _uploadQueue.indexWhere((item) => item.id == id);
    if (index == -1) return;

    _uploadQueue[index] = _uploadQueue[index].copyWith(
      status: UploadStatus.pending,
      progress: 0.0,
      error: null,
    );
    notifyListeners();

    _isUploading = true;
    notifyListeners();

    await _uploadItem(index);

    _isUploading = false;
    notifyListeners();
  }

  /// Get status message
  String get statusMessage {
    if (_isUploading) {
      return 'Uploading ${completedCount + 1} of ${_uploadQueue.length}...';
    }
    if (completedCount == _uploadQueue.length && _uploadQueue.isNotEmpty) {
      return 'All photos uploaded!';
    }
    if (failedCount > 0) {
      return '$failedCount upload(s) failed';
    }
    if (rejectedCount > 0) {
      return '$rejectedCount photo(s) rejected by moderation';
    }
    return '';
  }

  /// Check if all uploads are complete
  bool get allComplete =>
      _uploadQueue.isNotEmpty &&
      _uploadQueue.every(
        (item) =>
            item.status == UploadStatus.completed ||
            item.status == UploadStatus.rejected ||
            item.status == UploadStatus.failed,
      );

  /// Check if any uploads were successful
  bool get hasSuccessfulUploads => completedCount > 0;

  /// Reset provider
  void reset() {
    _uploadQueue.clear();
    _isUploading = false;
    _eventId = null;
    _deviceId = null;
    _caption = null;
    notifyListeners();
  }
}
