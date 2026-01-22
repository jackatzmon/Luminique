import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/event.dart';

/// Event Service
///
/// Handles all event-related operations:
/// - Create, read, update, delete events
/// - Manage event settings
/// - Generate QR codes and share links
class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('events');

  /// Create a new event
  Future<Event> createEvent({
    required String name,
    required String ownerId,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    EventSettings? settings,
    EventBranding? branding,
    NetworkSettings? networkSettings,
  }) async {
    final eventId = _uuid.v4().substring(0, 8); // Shorter ID for easier sharing
    final now = DateTime.now();

    final event = Event(
      id: eventId,
      name: name,
      description: description,
      ownerId: ownerId,
      status: EventStatus.draft,
      createdAt: now,
      startTime: startTime,
      endTime: endTime,
      settings: settings ?? EventSettings(),
      branding: branding ?? EventBranding(),
      networkSettings: networkSettings ?? NetworkSettings(),
      stats: EventStats(),
    );

    await _eventsCollection.doc(eventId).set(event.toFirestore());

    return event;
  }

  /// Get event by ID
  Future<Event?> getEvent(String eventId) async {
    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  /// Get event stream for real-time updates
  Stream<Event?> getEventStream(String eventId) {
    return _eventsCollection.doc(eventId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Event.fromFirestore(doc);
    });
  }

  /// Get all events for a user
  Stream<List<Event>> getUserEventsStream(String userId) {
    return _eventsCollection
        .where('ownerId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList());
  }

  /// Get active events for a user
  Future<List<Event>> getActiveEvents(String userId) async {
    final snapshot = await _eventsCollection
        .where('ownerId', isEqualTo: userId)
        .where('status', isEqualTo: EventStatus.active.name)
        .get();

    return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
  }

  /// Update event
  Future<void> updateEvent(Event event) async {
    await _eventsCollection.doc(event.id).update(event.toFirestore());
  }

  /// Update event status
  Future<void> updateEventStatus(String eventId, EventStatus status) async {
    await _eventsCollection.doc(eventId).update({
      'status': status.name,
    });
  }

  /// Start event (set to active)
  Future<void> startEvent(String eventId) async {
    await _eventsCollection.doc(eventId).update({
      'status': EventStatus.active.name,
      'startTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Pause event
  Future<void> pauseEvent(String eventId) async {
    await updateEventStatus(eventId, EventStatus.paused);
  }

  /// End event
  Future<void> endEvent(String eventId) async {
    await _eventsCollection.doc(eventId).update({
      'status': EventStatus.ended.name,
      'endTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Update event settings
  Future<void> updateEventSettings(
    String eventId,
    EventSettings settings,
  ) async {
    await _eventsCollection.doc(eventId).update({
      'settings': settings.toMap(),
    });
  }

  /// Update event branding
  Future<void> updateEventBranding(
    String eventId,
    EventBranding branding,
  ) async {
    await _eventsCollection.doc(eventId).update({
      'branding': branding.toMap(),
    });
  }

  /// Update network settings
  Future<void> updateNetworkSettings(
    String eventId,
    NetworkSettings networkSettings,
  ) async {
    await _eventsCollection.doc(eventId).update({
      'networkSettings': networkSettings.toMap(),
    });
  }

  /// Toggle uploads
  Future<void> toggleUploads(String eventId, bool enabled) async {
    await _eventsCollection.doc(eventId).update({
      'settings.uploadsEnabled': enabled,
    });
  }

  /// Toggle voting
  Future<void> toggleVoting(String eventId, bool enabled) async {
    await _eventsCollection.doc(eventId).update({
      'settings.votingEnabled': enabled,
    });
  }

  /// Toggle captions
  Future<void> toggleCaptions(String eventId, bool enabled) async {
    await _eventsCollection.doc(eventId).update({
      'settings.captionsEnabled': enabled,
    });
  }

  /// Set slideshow interval
  Future<void> setSlideshowInterval(String eventId, int seconds) async {
    await _eventsCollection.doc(eventId).update({
      'settings.slideshowIntervalSeconds': seconds,
    });
  }

  /// Block a device
  Future<void> blockDevice(String eventId, String deviceId) async {
    await _eventsCollection.doc(eventId).update({
      'settings.blockedDeviceIds': FieldValue.arrayUnion([deviceId]),
    });
  }

  /// Unblock a device
  Future<void> unblockDevice(String eventId, String deviceId) async {
    await _eventsCollection.doc(eventId).update({
      'settings.blockedDeviceIds': FieldValue.arrayRemove([deviceId]),
    });
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    // TODO: Also delete associated photos from storage
    await _eventsCollection.doc(eventId).delete();
  }

  /// Check if event exists and is active
  Future<bool> isEventActive(String eventId) async {
    final event = await getEvent(eventId);
    return event?.isActive ?? false;
  }

  /// Check if device is blocked
  Future<bool> isDeviceBlocked(String eventId, String deviceId) async {
    final event = await getEvent(eventId);
    if (event == null) return true;
    return event.settings.blockedDeviceIds.contains(deviceId);
  }

  /// Get event upload URL
  String getUploadUrl(String eventId, String baseUrl) {
    return '$baseUrl/e/$eventId';
  }

  /// Get event slideshow URL
  String getSlideshowUrl(String eventId, String baseUrl) {
    return '$baseUrl/slideshow?event=$eventId';
  }

  /// Increment unique device count
  Future<void> incrementUniqueDevices(String eventId) async {
    await _eventsCollection.doc(eventId).update({
      'stats.uniqueDevices': FieldValue.increment(1),
    });
  }

  /// Get event statistics
  Future<EventStats?> getEventStats(String eventId) async {
    final event = await getEvent(eventId);
    return event?.stats;
  }
}
