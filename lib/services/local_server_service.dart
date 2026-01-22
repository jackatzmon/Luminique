import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../models/photo.dart';
import 'moderation_service.dart';

/// Local Server Service
///
/// Provides local network functionality for offline mode:
/// - Receives photo uploads over local Wi-Fi
/// - Stores photos locally
/// - Syncs to cloud when internet is available
///
/// Note: This service is primarily for the DJ's machine running the slideshow.
/// In Flutter Web, some features are limited.
class LocalServerService {
  HttpServer? _server;
  final List<LocalPhoto> _localPhotos = [];
  final StreamController<LocalPhoto> _photoStreamController =
      StreamController<LocalPhoto>.broadcast();

  final ModerationService _moderationService = ModerationService();

  bool _isRunning = false;
  String? _serverAddress;
  int _serverPort = 8080;

  // Getters
  bool get isRunning => _isRunning;
  String? get serverAddress => _serverAddress;
  int get serverPort => _serverPort;
  List<LocalPhoto> get localPhotos => List.unmodifiable(_localPhotos);
  Stream<LocalPhoto> get photoStream => _photoStreamController.stream;

  /// Start the local server
  Future<bool> startServer({int port = 8080}) async {
    if (_isRunning) return true;

    try {
      _serverPort = port;

      // Get local IP address
      _serverAddress = await _getLocalIpAddress();

      if (_serverAddress == null) {
        return false;
      }

      // Start HTTP server
      _server = await HttpServer.bind(
        InternetAddress.anyIPv4,
        _serverPort,
      );

      _isRunning = true;

      // Listen for requests
      _server!.listen(_handleRequest);

      return true;
    } catch (e) {
      _isRunning = false;
      return false;
    }
  }

  /// Stop the local server
  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
    _isRunning = false;
  }

  /// Handle incoming HTTP requests
  Future<void> _handleRequest(HttpRequest request) async {
    // Add CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    // Handle preflight
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      switch (request.uri.path) {
        case '/upload':
          await _handleUpload(request);
          break;
        case '/photos':
          await _handleGetPhotos(request);
          break;
        case '/status':
          await _handleStatus(request);
          break;
        default:
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('Not found');
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.write('Server error: $e');
    }

    await request.response.close();
  }

  /// Handle photo upload
  Future<void> _handleUpload(HttpRequest request) async {
    if (request.method != 'POST') {
      request.response.statusCode = HttpStatus.methodNotAllowed;
      return;
    }

    try {
      // Read request body
      final bytes = await _collectBytes(request);

      // Parse multipart form data (simplified)
      final contentType = request.headers.contentType;
      if (contentType?.mimeType == 'multipart/form-data') {
        final boundary = contentType?.parameters['boundary'];
        if (boundary != null) {
          final photo = await _parseMultipartUpload(bytes, boundary);
          if (photo != null) {
            _localPhotos.add(photo);
            _photoStreamController.add(photo);

            request.response.statusCode = HttpStatus.ok;
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({
              'success': true,
              'photoId': photo.id,
              'status': photo.status.name,
            }));
            return;
          }
        }
      }

      // Direct image upload
      final photo = await _processUploadedImage(bytes);
      _localPhotos.add(photo);
      _photoStreamController.add(photo);

      request.response.statusCode = HttpStatus.ok;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'success': true,
        'photoId': photo.id,
        'status': photo.status.name,
      }));
    } catch (e) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Upload failed: $e');
    }
  }

  /// Handle get photos request
  Future<void> _handleGetPhotos(HttpRequest request) async {
    final approvedPhotos = _localPhotos
        .where((p) => p.status == PhotoStatus.approved)
        .map((p) => p.toJson())
        .toList();

    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(approvedPhotos));
  }

  /// Handle status request
  Future<void> _handleStatus(HttpRequest request) async {
    request.response.statusCode = HttpStatus.ok;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'status': 'online',
      'totalPhotos': _localPhotos.length,
      'approvedPhotos': _localPhotos.where((p) => p.status == PhotoStatus.approved).length,
      'pendingPhotos': _localPhotos.where((p) => p.status == PhotoStatus.pending).length,
    }));
  }

  /// Collect bytes from request
  Future<Uint8List> _collectBytes(HttpRequest request) async {
    final completer = Completer<Uint8List>();
    final chunks = <List<int>>[];

    request.listen(
      (chunk) => chunks.add(chunk),
      onDone: () {
        final bytes = chunks.fold<List<int>>(
          [],
          (previous, element) => [...previous, ...element],
        );
        completer.complete(Uint8List.fromList(bytes));
      },
      onError: completer.completeError,
    );

    return completer.future;
  }

  /// Parse multipart form upload
  Future<LocalPhoto?> _parseMultipartUpload(
    Uint8List bytes,
    String boundary,
  ) async {
    // Simplified multipart parsing
    // In production, use a proper multipart parser

    final boundaryBytes = utf8.encode('--$boundary');
    final content = String.fromCharCodes(bytes);

    // Find image data section
    final imageStart = content.indexOf('\r\n\r\n');
    if (imageStart == -1) return null;

    final imageEnd = content.lastIndexOf('--$boundary');
    if (imageEnd == -1) return null;

    // Extract image bytes (simplified)
    final imageData = bytes.sublist(imageStart + 4, imageEnd - 2);

    return await _processUploadedImage(imageData);
  }

  /// Process uploaded image with moderation
  Future<LocalPhoto> _processUploadedImage(Uint8List imageBytes) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();

    // Run local moderation
    final moderationResult = await _moderationService.moderateImage(imageBytes);

    PhotoStatus status;
    if (moderationResult.isSafe) {
      status = PhotoStatus.approved;
    } else if (moderationResult.needsManualReview) {
      status = PhotoStatus.flagged;
    } else {
      status = PhotoStatus.rejected;
    }

    return LocalPhoto(
      id: id,
      imageBytes: imageBytes,
      status: status,
      moderationResult: moderationResult,
      uploadedAt: DateTime.now(),
    );
  }

  /// Get local IP address
  Future<String?> _getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );

      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          // Skip loopback
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get approved photos for slideshow
  List<LocalPhoto> getApprovedPhotos() {
    return _localPhotos
        .where((p) => p.status == PhotoStatus.approved)
        .toList();
  }

  /// Approve a photo manually
  void approvePhoto(String photoId) {
    final index = _localPhotos.indexWhere((p) => p.id == photoId);
    if (index != -1) {
      _localPhotos[index] = _localPhotos[index].copyWith(
        status: PhotoStatus.approved,
      );
    }
  }

  /// Reject a photo manually
  void rejectPhoto(String photoId) {
    final index = _localPhotos.indexWhere((p) => p.id == photoId);
    if (index != -1) {
      _localPhotos[index] = _localPhotos[index].copyWith(
        status: PhotoStatus.rejected,
      );
    }
  }

  /// Clear all local photos
  void clearPhotos() {
    _localPhotos.clear();
  }

  /// Get server URL for guests
  String? getServerUrl() {
    if (!_isRunning || _serverAddress == null) return null;
    return 'http://$_serverAddress:$_serverPort';
  }

  /// Dispose resources
  void dispose() {
    _photoStreamController.close();
    stopServer();
  }
}

/// Local photo model for offline storage
class LocalPhoto {
  final String id;
  final Uint8List imageBytes;
  final PhotoStatus status;
  final ModerationResult? moderationResult;
  final DateTime uploadedAt;
  final String? caption;
  final String? deviceId;

  LocalPhoto({
    required this.id,
    required this.imageBytes,
    required this.status,
    this.moderationResult,
    required this.uploadedAt,
    this.caption,
    this.deviceId,
  });

  LocalPhoto copyWith({
    String? id,
    Uint8List? imageBytes,
    PhotoStatus? status,
    ModerationResult? moderationResult,
    DateTime? uploadedAt,
    String? caption,
    String? deviceId,
  }) {
    return LocalPhoto(
      id: id ?? this.id,
      imageBytes: imageBytes ?? this.imageBytes,
      status: status ?? this.status,
      moderationResult: moderationResult ?? this.moderationResult,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      caption: caption ?? this.caption,
      deviceId: deviceId ?? this.deviceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status.name,
      'uploadedAt': uploadedAt.toIso8601String(),
      'caption': caption,
      // Note: imageBytes converted to base64 for JSON transport
      'imageData': base64Encode(imageBytes),
    };
  }

  /// Create data URL for displaying image
  String get dataUrl {
    final base64 = base64Encode(imageBytes);
    return 'data:image/jpeg;base64,$base64';
  }
}
