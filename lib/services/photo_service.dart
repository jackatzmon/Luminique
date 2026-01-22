import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../models/photo.dart';
import '../models/event.dart';

/// Photo Service
///
/// Handles all photo-related operations:
/// - Upload to Firebase Storage
/// - Save metadata to Firestore
/// - Retrieve photos for slideshow
/// - Manage photo status and votes
class PhotoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  // Collection references
  CollectionReference<Map<String, dynamic>> get _photosCollection =>
      _firestore.collection('photos');

  /// Upload a photo to cloud storage
  Future<Photo> uploadPhoto({
    required String eventId,
    required Uint8List imageBytes,
    required String fileName,
    String? caption,
    String? deviceId,
    ModerationResult? moderationResult,
  }) async {
    final photoId = _uuid.v4();
    final timestamp = DateTime.now();

    // Determine storage path
    final storagePath = 'events/$eventId/photos/$photoId/$fileName';

    // Upload to Firebase Storage
    final ref = _storage.ref().child(storagePath);
    final uploadTask = await ref.putData(
      imageBytes,
      SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'eventId': eventId,
          'uploadedAt': timestamp.toIso8601String(),
        },
      ),
    );

    // Get download URL
    final imageUrl = await uploadTask.ref.getDownloadURL();

    // Generate thumbnail (in production, use Cloud Functions)
    final thumbnailUrl = imageUrl; // Placeholder - same as original

    // Determine initial status based on moderation
    PhotoStatus status = PhotoStatus.pending;
    if (moderationResult != null) {
      if (moderationResult.isSafe) {
        status = PhotoStatus.approved;
      } else if (moderationResult.needsManualReview) {
        status = PhotoStatus.flagged;
      } else {
        status = PhotoStatus.rejected;
      }
    }

    // Create photo document
    final photo = Photo(
      id: photoId,
      eventId: eventId,
      imageUrl: imageUrl,
      thumbnailUrl: thumbnailUrl,
      status: status,
      caption: caption,
      votes: 0,
      uploadedAt: timestamp,
      approvedAt: status == PhotoStatus.approved ? timestamp : null,
      uploaderDeviceId: deviceId,
      moderationResult: moderationResult,
    );

    // Save to Firestore
    await _photosCollection.doc(photoId).set(photo.toFirestore());

    // Update event stats
    await _updateEventStats(eventId, status);

    return photo;
  }

  /// Save photo locally (for offline mode)
  Future<Photo> savePhotoLocally({
    required String eventId,
    required String localPath,
    String? caption,
    String? deviceId,
    ModerationResult? moderationResult,
  }) async {
    final photoId = _uuid.v4();
    final timestamp = DateTime.now();

    PhotoStatus status = PhotoStatus.pending;
    if (moderationResult != null) {
      if (moderationResult.isSafe) {
        status = PhotoStatus.approved;
      } else if (moderationResult.needsManualReview) {
        status = PhotoStatus.flagged;
      } else {
        status = PhotoStatus.rejected;
      }
    }

    return Photo(
      id: photoId,
      eventId: eventId,
      imageUrl: '', // Will be set when synced to cloud
      localPath: localPath,
      status: status,
      caption: caption,
      votes: 0,
      uploadedAt: timestamp,
      approvedAt: status == PhotoStatus.approved ? timestamp : null,
      uploaderDeviceId: deviceId,
      moderationResult: moderationResult,
    );
  }

  /// Get approved photos for an event (for slideshow)
  Stream<List<Photo>> getApprovedPhotosStream(String eventId) {
    return _photosCollection
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: PhotoStatus.approved.name)
        .orderBy('approvedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Photo.fromFirestore(doc)).toList());
  }

  /// Get all photos for an event (for admin)
  Stream<List<Photo>> getAllPhotosStream(String eventId) {
    return _photosCollection
        .where('eventId', isEqualTo: eventId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Photo.fromFirestore(doc)).toList());
  }

  /// Get photos pending moderation
  Stream<List<Photo>> getPendingPhotosStream(String eventId) {
    return _photosCollection
        .where('eventId', isEqualTo: eventId)
        .where('status', whereIn: [
          PhotoStatus.pending.name,
          PhotoStatus.flagged.name,
        ])
        .orderBy('uploadedAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Photo.fromFirestore(doc)).toList());
  }

  /// Get top voted photos
  Future<List<Photo>> getTopVotedPhotos(String eventId, {int limit = 10}) async {
    final snapshot = await _photosCollection
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: PhotoStatus.approved.name)
        .orderBy('votes', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => Photo.fromFirestore(doc)).toList();
  }

  /// Update photo status
  Future<void> updatePhotoStatus(String photoId, PhotoStatus newStatus) async {
    final updates = <String, dynamic>{
      'status': newStatus.name,
    };

    if (newStatus == PhotoStatus.approved) {
      updates['approvedAt'] = Timestamp.fromDate(DateTime.now());
    }

    await _photosCollection.doc(photoId).update(updates);

    // Update event stats
    final doc = await _photosCollection.doc(photoId).get();
    if (doc.exists) {
      final photo = Photo.fromFirestore(doc);
      await _updateEventStats(photo.eventId, newStatus);
    }
  }

  /// Approve a photo
  Future<void> approvePhoto(String photoId) async {
    await updatePhotoStatus(photoId, PhotoStatus.approved);
  }

  /// Reject a photo
  Future<void> rejectPhoto(String photoId) async {
    await updatePhotoStatus(photoId, PhotoStatus.rejected);
  }

  /// Vote for a photo
  Future<void> voteForPhoto(String photoId) async {
    await _photosCollection.doc(photoId).update({
      'votes': FieldValue.increment(1),
    });
  }

  /// Update photo caption
  Future<void> updateCaption(String photoId, String caption) async {
    await _photosCollection.doc(photoId).update({
      'caption': caption,
    });
  }

  /// Delete a photo
  Future<void> deletePhoto(String photoId) async {
    final doc = await _photosCollection.doc(photoId).get();
    if (!doc.exists) return;

    final photo = Photo.fromFirestore(doc);

    // Delete from storage
    if (photo.imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(photo.imageUrl).delete();
      } catch (e) {
        // Image may already be deleted
      }
    }

    // Delete from Firestore
    await _photosCollection.doc(photoId).delete();
  }

  /// Get photos count by status
  Future<Map<PhotoStatus, int>> getPhotoCountsByStatus(String eventId) async {
    final counts = <PhotoStatus, int>{};

    for (final status in PhotoStatus.values) {
      final snapshot = await _photosCollection
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: status.name)
          .count()
          .get();

      counts[status] = snapshot.count ?? 0;
    }

    return counts;
  }

  /// Update event statistics
  Future<void> _updateEventStats(String eventId, PhotoStatus status) async {
    final updates = <String, dynamic>{};

    switch (status) {
      case PhotoStatus.pending:
        updates['stats.totalUploads'] = FieldValue.increment(1);
        break;
      case PhotoStatus.approved:
        updates['stats.approvedPhotos'] = FieldValue.increment(1);
        break;
      case PhotoStatus.rejected:
        updates['stats.rejectedPhotos'] = FieldValue.increment(1);
        break;
      case PhotoStatus.flagged:
        updates['stats.flaggedPhotos'] = FieldValue.increment(1);
        break;
      case PhotoStatus.archived:
        break;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('events').doc(eventId).update(updates);
    }
  }

  /// Get all photo URLs for export
  Future<List<String>> getPhotoUrlsForExport(String eventId) async {
    final snapshot = await _photosCollection
        .where('eventId', isEqualTo: eventId)
        .where('status', isEqualTo: PhotoStatus.approved.name)
        .get();

    return snapshot.docs
        .map((doc) => doc.data()['imageUrl'] as String)
        .where((url) => url.isNotEmpty)
        .toList();
  }
}
