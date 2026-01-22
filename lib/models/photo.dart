import 'package:cloud_firestore/cloud_firestore.dart';

enum PhotoStatus {
  pending,    // Just uploaded, awaiting moderation
  approved,   // Passed moderation, visible in slideshow
  rejected,   // Failed moderation
  flagged,    // Needs manual review
  archived,   // Hidden from slideshow but kept
}

enum ModerationSource {
  googleVision,  // Cloud Vision API
  localAI,       // On-device moderation
  manual,        // DJ manually reviewed
}

class Photo {
  final String id;
  final String eventId;
  final String imageUrl;
  final String thumbnailUrl;
  final String? localPath;       // For offline mode
  final PhotoStatus status;
  final String? caption;
  final int votes;
  final DateTime uploadedAt;
  final DateTime? approvedAt;
  final String? uploaderDeviceId;  // Anonymous device identifier
  final ModerationResult? moderationResult;
  final Map<String, dynamic>? metadata;

  Photo({
    required this.id,
    required this.eventId,
    required this.imageUrl,
    this.thumbnailUrl = '',
    this.localPath,
    this.status = PhotoStatus.pending,
    this.caption,
    this.votes = 0,
    required this.uploadedAt,
    this.approvedAt,
    this.uploaderDeviceId,
    this.moderationResult,
    this.metadata,
  });

  factory Photo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Photo(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      localPath: data['localPath'],
      status: PhotoStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => PhotoStatus.pending,
      ),
      caption: data['caption'],
      votes: data['votes'] ?? 0,
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedAt: (data['approvedAt'] as Timestamp?)?.toDate(),
      uploaderDeviceId: data['uploaderDeviceId'],
      moderationResult: data['moderationResult'] != null
          ? ModerationResult.fromMap(data['moderationResult'])
          : null,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'imageUrl': imageUrl,
      'thumbnailUrl': thumbnailUrl,
      'localPath': localPath,
      'status': status.name,
      'caption': caption,
      'votes': votes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'uploaderDeviceId': uploaderDeviceId,
      'moderationResult': moderationResult?.toMap(),
      'metadata': metadata,
    };
  }

  Photo copyWith({
    String? id,
    String? eventId,
    String? imageUrl,
    String? thumbnailUrl,
    String? localPath,
    PhotoStatus? status,
    String? caption,
    int? votes,
    DateTime? uploadedAt,
    DateTime? approvedAt,
    String? uploaderDeviceId,
    ModerationResult? moderationResult,
    Map<String, dynamic>? metadata,
  }) {
    return Photo(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      imageUrl: imageUrl ?? this.imageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      localPath: localPath ?? this.localPath,
      status: status ?? this.status,
      caption: caption ?? this.caption,
      votes: votes ?? this.votes,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      uploaderDeviceId: uploaderDeviceId ?? this.uploaderDeviceId,
      moderationResult: moderationResult ?? this.moderationResult,
      metadata: metadata ?? this.metadata,
    );
  }
}

class ModerationResult {
  final bool isSafe;
  final ModerationSource source;
  final double? adultScore;
  final double? violenceScore;
  final double? racyScore;
  final double? spoofScore;
  final double? medicalScore;
  final String? rejectionReason;
  final DateTime checkedAt;

  ModerationResult({
    required this.isSafe,
    required this.source,
    this.adultScore,
    this.violenceScore,
    this.racyScore,
    this.spoofScore,
    this.medicalScore,
    this.rejectionReason,
    required this.checkedAt,
  });

  factory ModerationResult.fromMap(Map<String, dynamic> map) {
    return ModerationResult(
      isSafe: map['isSafe'] ?? false,
      source: ModerationSource.values.firstWhere(
        (e) => e.name == map['source'],
        orElse: () => ModerationSource.localAI,
      ),
      adultScore: map['adultScore']?.toDouble(),
      violenceScore: map['violenceScore']?.toDouble(),
      racyScore: map['racyScore']?.toDouble(),
      spoofScore: map['spoofScore']?.toDouble(),
      medicalScore: map['medicalScore']?.toDouble(),
      rejectionReason: map['rejectionReason'],
      checkedAt: (map['checkedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isSafe': isSafe,
      'source': source.name,
      'adultScore': adultScore,
      'violenceScore': violenceScore,
      'racyScore': racyScore,
      'spoofScore': spoofScore,
      'medicalScore': medicalScore,
      'rejectionReason': rejectionReason,
      'checkedAt': Timestamp.fromDate(checkedAt),
    };
  }

  /// Check if the image should be flagged for manual review
  bool get needsManualReview {
    // Flag images that are borderline (scores between 0.3 and 0.7)
    const threshold = 0.3;
    const upperThreshold = 0.7;

    if (adultScore != null && adultScore! > threshold && adultScore! < upperThreshold) {
      return true;
    }
    if (violenceScore != null && violenceScore! > threshold && violenceScore! < upperThreshold) {
      return true;
    }
    if (racyScore != null && racyScore! > threshold && racyScore! < upperThreshold) {
      return true;
    }
    return false;
  }
}
