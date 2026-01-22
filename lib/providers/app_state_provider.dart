import 'package:flutter/material.dart';

import '../models/event.dart';
import '../models/user.dart';
import '../services/network_service.dart';

/// App State Provider
///
/// Manages global application state:
/// - Theme mode
/// - Current event
/// - Network mode
/// - User session
class AppStateProvider extends ChangeNotifier {
  final NetworkService networkService;

  AppStateProvider({required this.networkService});

  // Theme
  ThemeMode _themeMode = ThemeMode.dark; // Dark mode by default for DJ use
  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  // Current Event
  Event? _currentEvent;
  Event? get currentEvent => _currentEvent;

  void setCurrentEvent(Event? event) {
    _currentEvent = event;
    notifyListeners();
  }

  // Current User
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  void setCurrentUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  // Network Mode
  NetworkMode get networkMode => networkService.currentMode;
  bool get isOnline => networkService.isOnline;

  void setNetworkMode(NetworkMode mode) {
    networkService.setMode(mode);
    notifyListeners();
  }

  // Slideshow state
  bool _slideshowRunning = false;
  bool get slideshowRunning => _slideshowRunning;

  void setSlideshowRunning(bool running) {
    _slideshowRunning = running;
    notifyListeners();
  }

  // Full screen mode
  bool _isFullScreen = false;
  bool get isFullScreen => _isFullScreen;

  void setFullScreen(bool fullScreen) {
    _isFullScreen = fullScreen;
    notifyListeners();
  }

  void toggleFullScreen() {
    _isFullScreen = !_isFullScreen;
    notifyListeners();
  }

  // Loading states
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Error handling
  String? _error;
  String? get error => _error;

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Success message
  String? _successMessage;
  String? get successMessage => _successMessage;

  void setSuccessMessage(String? message) {
    _successMessage = message;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _successMessage = null;
    notifyListeners();
  }

  // Reset state
  void reset() {
    _currentEvent = null;
    _currentUser = null;
    _slideshowRunning = false;
    _isFullScreen = false;
    _isLoading = false;
    _error = null;
    _successMessage = null;
    notifyListeners();
  }
}
