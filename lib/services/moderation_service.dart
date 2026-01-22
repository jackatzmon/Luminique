import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../models/photo.dart';

/// Content Moderation Service
///
/// Supports two modes:
/// 1. Cloud Mode: Uses Google Cloud Vision API SafeSearch
/// 2. Local Mode: Uses on-device heuristics and hash-based checking
///
/// The service automatically falls back to local mode when offline.
class ModerationService {
  static const String _visionApiEndpoint =
      'https://vision.googleapis.com/v1/images:annotate';

  // TODO: Replace with your actual API key or use environment variables
  String? _apiKey;

  // Thresholds for content filtering
  static const double _safeThreshold = 0.3;
  static const double _rejectThreshold = 0.7;

  // Known bad image hashes (for local mode)
  final Set<String> _blockedHashes = {};

  // Local moderation settings
  bool _useLocalFallback = true;

  void configure({
    String? apiKey,
    bool useLocalFallback = true,
  }) {
    _apiKey = apiKey;
    _useLocalFallback = useLocalFallback;
  }

  /// Moderate an image using the best available method
  Future<ModerationResult> moderateImage(Uint8List imageBytes) async {
    // Try cloud moderation first if API key is available
    if (_apiKey != null && _apiKey!.isNotEmpty) {
      try {
        return await _moderateWithVisionAPI(imageBytes);
      } catch (e) {
        // Fall back to local if cloud fails
        if (_useLocalFallback) {
          return await _moderateLocally(imageBytes);
        }
        rethrow;
      }
    }

    // Use local moderation if no API key
    if (_useLocalFallback) {
      return await _moderateLocally(imageBytes);
    }

    // Auto-approve if no moderation available
    return ModerationResult(
      isSafe: true,
      source: ModerationSource.localAI,
      checkedAt: DateTime.now(),
    );
  }

  /// Moderate using Google Cloud Vision API SafeSearch
  Future<ModerationResult> _moderateWithVisionAPI(Uint8List imageBytes) async {
    final base64Image = base64Encode(imageBytes);

    final requestBody = {
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'SAFE_SEARCH_DETECTION'}
          ],
        }
      ]
    };

    final response = await http.post(
      Uri.parse('$_visionApiEndpoint?key=$_apiKey'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode != 200) {
      throw Exception('Vision API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final safeSearch = data['responses']?[0]?['safeSearchAnnotation'];

    if (safeSearch == null) {
      throw Exception('No SafeSearch results returned');
    }

    // Parse likelihood scores
    final adultScore = _likelihoodToScore(safeSearch['adult']);
    final violenceScore = _likelihoodToScore(safeSearch['violence']);
    final racyScore = _likelihoodToScore(safeSearch['racy']);
    final spoofScore = _likelihoodToScore(safeSearch['spoof']);
    final medicalScore = _likelihoodToScore(safeSearch['medical']);

    // Determine if safe
    final isSafe = adultScore < _rejectThreshold &&
        violenceScore < _rejectThreshold &&
        racyScore < _rejectThreshold;

    String? rejectionReason;
    if (!isSafe) {
      if (adultScore >= _rejectThreshold) {
        rejectionReason = 'Adult content detected';
      } else if (violenceScore >= _rejectThreshold) {
        rejectionReason = 'Violent content detected';
      } else if (racyScore >= _rejectThreshold) {
        rejectionReason = 'Inappropriate content detected';
      }
    }

    return ModerationResult(
      isSafe: isSafe,
      source: ModerationSource.googleVision,
      adultScore: adultScore,
      violenceScore: violenceScore,
      racyScore: racyScore,
      spoofScore: spoofScore,
      medicalScore: medicalScore,
      rejectionReason: rejectionReason,
      checkedAt: DateTime.now(),
    );
  }

  /// Convert Vision API likelihood string to numeric score
  double _likelihoodToScore(String? likelihood) {
    switch (likelihood) {
      case 'VERY_UNLIKELY':
        return 0.0;
      case 'UNLIKELY':
        return 0.2;
      case 'POSSIBLE':
        return 0.5;
      case 'LIKELY':
        return 0.75;
      case 'VERY_LIKELY':
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Local content moderation (for offline mode)
  ///
  /// This uses multiple heuristics:
  /// 1. Hash-based blocking (known bad images)
  /// 2. Image statistics analysis
  /// 3. Color distribution analysis
  Future<ModerationResult> _moderateLocally(Uint8List imageBytes) async {
    // Check against blocked hashes
    final hash = _computeImageHash(imageBytes);
    if (_blockedHashes.contains(hash)) {
      return ModerationResult(
        isSafe: false,
        source: ModerationSource.localAI,
        rejectionReason: 'Image blocked by hash',
        checkedAt: DateTime.now(),
      );
    }

    // Analyze image characteristics
    final analysis = await _analyzeImageLocally(imageBytes);

    // Use heuristics to estimate safety scores
    final estimatedAdultScore = analysis['skinToneRatio'] ?? 0.0;
    final estimatedViolenceScore = analysis['redRatio'] ?? 0.0;

    // Be more permissive in local mode since it's less accurate
    final isSafe = estimatedAdultScore < 0.6 && estimatedViolenceScore < 0.5;

    String? rejectionReason;
    if (!isSafe) {
      rejectionReason = 'Flagged by local content filter';
    }

    return ModerationResult(
      isSafe: isSafe,
      source: ModerationSource.localAI,
      adultScore: estimatedAdultScore,
      violenceScore: estimatedViolenceScore,
      rejectionReason: rejectionReason,
      checkedAt: DateTime.now(),
    );
  }

  /// Compute a simple hash of the image for comparison
  String _computeImageHash(Uint8List bytes) {
    // Simple hash based on image size and sample bytes
    int hash = bytes.length;
    for (int i = 0; i < bytes.length; i += (bytes.length ~/ 100).clamp(1, 1000)) {
      hash = (hash * 31 + bytes[i]) & 0x7FFFFFFF;
    }
    return hash.toRadixString(16);
  }

  /// Analyze image locally for content hints
  Future<Map<String, double>> _analyzeImageLocally(Uint8List bytes) async {
    // This is a simplified analysis that looks at color distribution
    // In a real implementation, you might use a local ML model

    final Map<String, double> results = {};

    try {
      // Sample pixels to estimate skin tone and red content
      // This is a very basic heuristic
      int skinTonePixels = 0;
      int redPixels = 0;
      int totalSamples = 0;

      // Sample every Nth byte (assuming RGBA format)
      for (int i = 0; i < bytes.length - 4; i += 400) {
        final r = bytes[i];
        final g = bytes[i + 1];
        final b = bytes[i + 2];

        totalSamples++;

        // Simple skin tone detection heuristic
        if (_isSkinTone(r, g, b)) {
          skinTonePixels++;
        }

        // High red content detection
        if (r > 150 && r > g * 1.5 && r > b * 1.5) {
          redPixels++;
        }
      }

      if (totalSamples > 0) {
        results['skinToneRatio'] = skinTonePixels / totalSamples;
        results['redRatio'] = redPixels / totalSamples;
      }
    } catch (e) {
      // If analysis fails, return neutral scores
      results['skinToneRatio'] = 0.0;
      results['redRatio'] = 0.0;
    }

    return results;
  }

  /// Simple skin tone detection heuristic
  bool _isSkinTone(int r, int g, int b) {
    // Based on common skin tone RGB ranges
    // This is a simplified version - production would use better models
    if (r < 95 || g < 40 || b < 20) return false;
    if (r > 250 && g > 250 && b > 250) return false; // White
    if (r < 50 && g < 50 && b < 50) return false; // Black

    final max = [r, g, b].reduce((a, b) => a > b ? a : b);
    final min = [r, g, b].reduce((a, b) => a < b ? a : b);

    // Skin tones typically have R > G > B
    if (!(r > g && g > b)) return false;

    // Check if color difference is within skin tone range
    if ((max - min) > 15 && (r - g) > 15) {
      return true;
    }

    return false;
  }

  /// Add a hash to the blocked list
  void addBlockedHash(String hash) {
    _blockedHashes.add(hash);
  }

  /// Remove a hash from the blocked list
  void removeBlockedHash(String hash) {
    _blockedHashes.remove(hash);
  }

  /// Check if Vision API is configured
  bool get isCloudModerationAvailable => _apiKey != null && _apiKey!.isNotEmpty;

  /// Get current moderation mode
  String get currentMode {
    if (isCloudModerationAvailable) {
      return 'Cloud (Google Vision)';
    } else if (_useLocalFallback) {
      return 'Local (On-device)';
    } else {
      return 'Disabled';
    }
  }
}
