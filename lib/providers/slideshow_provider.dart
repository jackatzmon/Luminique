import 'dart:async';
import 'package:flutter/material.dart';

import '../models/photo.dart';
import '../services/photo_service.dart';

/// Slideshow Provider
///
/// Manages slideshow state:
/// - Photo queue
/// - Current photo index
/// - Auto-advance timer
/// - Transition effects
class SlideshowProvider extends ChangeNotifier {
  final PhotoService photoService;

  SlideshowProvider({required this.photoService});

  // Photos
  List<Photo> _photos = [];
  List<Photo> get photos => _photos;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  Photo? get currentPhoto =>
      _photos.isNotEmpty && _currentIndex < _photos.length
          ? _photos[_currentIndex]
          : null;

  // Slideshow state
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // Timer
  Timer? _autoAdvanceTimer;
  int _intervalSeconds = 5;
  int get intervalSeconds => _intervalSeconds;

  // Event subscription
  StreamSubscription<List<Photo>>? _photoSubscription;
  String? _currentEventId;

  /// Start listening to photos for an event
  void startListening(String eventId) {
    _currentEventId = eventId;

    // Cancel existing subscription
    _photoSubscription?.cancel();

    // Listen to approved photos stream
    _photoSubscription = photoService
        .getApprovedPhotosStream(eventId)
        .listen(_onPhotosUpdated);
  }

  /// Stop listening to photos
  void stopListening() {
    _photoSubscription?.cancel();
    _photoSubscription = null;
    _currentEventId = null;
  }

  /// Handle photo updates from stream
  void _onPhotosUpdated(List<Photo> newPhotos) {
    final hadPhotos = _photos.isNotEmpty;
    _photos = newPhotos;

    // If we just got our first photos, reset index
    if (!hadPhotos && _photos.isNotEmpty) {
      _currentIndex = 0;
    }

    // Make sure current index is valid
    if (_currentIndex >= _photos.length && _photos.isNotEmpty) {
      _currentIndex = _photos.length - 1;
    }

    notifyListeners();
  }

  /// Set photos directly (for local mode)
  void setPhotos(List<Photo> photos) {
    _photos = photos;
    if (_currentIndex >= _photos.length && _photos.isNotEmpty) {
      _currentIndex = _photos.length - 1;
    }
    notifyListeners();
  }

  /// Add a photo to the queue
  void addPhoto(Photo photo) {
    _photos.insert(0, photo); // Add to beginning (newest first)
    notifyListeners();
  }

  /// Go to next photo
  void nextPhoto() {
    if (_photos.isEmpty) return;

    _currentIndex = (_currentIndex + 1) % _photos.length;
    notifyListeners();
  }

  /// Go to previous photo
  void previousPhoto() {
    if (_photos.isEmpty) return;

    _currentIndex = (_currentIndex - 1 + _photos.length) % _photos.length;
    notifyListeners();
  }

  /// Go to specific photo
  void goToPhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  /// Start auto-advance
  void play() {
    if (_isPlaying) return;

    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  /// Stop auto-advance
  void pause() {
    _isPlaying = false;
    _stopTimer();
    notifyListeners();
  }

  /// Toggle play/pause
  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Set interval (in seconds)
  void setInterval(int seconds) {
    _intervalSeconds = seconds;

    // Restart timer if playing
    if (_isPlaying) {
      _stopTimer();
      _startTimer();
    }

    notifyListeners();
  }

  /// Start the auto-advance timer
  void _startTimer() {
    _stopTimer();
    _autoAdvanceTimer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) => nextPhoto(),
    );
  }

  /// Stop the auto-advance timer
  void _stopTimer() {
    _autoAdvanceTimer?.cancel();
    _autoAdvanceTimer = null;
  }

  /// Shuffle photos
  void shuffle() {
    _photos.shuffle();
    _currentIndex = 0;
    notifyListeners();
  }

  /// Sort by newest first
  void sortByNewest() {
    _photos.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    _currentIndex = 0;
    notifyListeners();
  }

  /// Sort by most votes
  void sortByVotes() {
    _photos.sort((a, b) => b.votes.compareTo(a.votes));
    _currentIndex = 0;
    notifyListeners();
  }

  /// Get photo count
  int get photoCount => _photos.length;

  /// Check if there are photos
  bool get hasPhotos => _photos.isNotEmpty;

  /// Get progress (0.0 to 1.0)
  double get progress =>
      _photos.isEmpty ? 0.0 : (_currentIndex + 1) / _photos.length;

  /// Reset slideshow
  void reset() {
    _stopTimer();
    _isPlaying = false;
    _currentIndex = 0;
    _photos = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    _photoSubscription?.cancel();
    super.dispose();
  }
}
