import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/event.dart';

/// Network Service
///
/// Manages network connectivity detection and mode switching between:
/// - Internet Mode: Full cloud connectivity
/// - Local Mode: Local Wi-Fi network only
/// - Hybrid Mode: Auto-detect and switch
class NetworkService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  NetworkMode _currentMode = NetworkMode.hybrid;
  bool _isOnline = true;
  bool _isLocalNetworkAvailable = false;
  String? _currentWifiName;
  String? _localServerAddress;

  // Getters
  NetworkMode get currentMode => _currentMode;
  bool get isOnline => _isOnline;
  bool get isLocalNetworkAvailable => _isLocalNetworkAvailable;
  String? get currentWifiName => _currentWifiName;
  String? get localServerAddress => _localServerAddress;

  /// Initialize the network service
  Future<void> initialize() async {
    await _checkConnectivity();
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  /// Dispose of resources
  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectivityStatus(results);
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    _updateConnectivityStatus(results);
  }

  /// Update connectivity status based on results
  void _updateConnectivityStatus(List<ConnectivityResult> results) {
    final wasOnline = _isOnline;

    _isOnline = results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);

    final hasWifi = results.contains(ConnectivityResult.wifi);

    // Update Wi-Fi status
    if (hasWifi) {
      _checkWifiNetwork();
    } else {
      _currentWifiName = null;
      _isLocalNetworkAvailable = false;
    }

    // Notify if status changed
    if (wasOnline != _isOnline) {
      notifyListeners();
    }
  }

  /// Check Wi-Fi network details
  Future<void> _checkWifiNetwork() async {
    // Note: Getting Wi-Fi name requires platform-specific permissions
    // This is a simplified version
    try {
      // In a real implementation, you would use platform channels
      // to get the actual Wi-Fi SSID
      _currentWifiName = 'Connected Wi-Fi';
    } catch (e) {
      _currentWifiName = null;
    }
    notifyListeners();
  }

  /// Set the network mode manually
  void setMode(NetworkMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }

  /// Check if we should use cloud services
  bool get shouldUseCloud {
    switch (_currentMode) {
      case NetworkMode.internet:
        return _isOnline;
      case NetworkMode.local:
        return false;
      case NetworkMode.hybrid:
        return _isOnline;
    }
  }

  /// Check if we should use local server
  bool get shouldUseLocal {
    switch (_currentMode) {
      case NetworkMode.internet:
        return false;
      case NetworkMode.local:
        return true;
      case NetworkMode.hybrid:
        return !_isOnline || _isLocalNetworkAvailable;
    }
  }

  /// Configure local server address
  void setLocalServer(String address, int port) {
    _localServerAddress = 'http://$address:$port';
    _isLocalNetworkAvailable = true;
    notifyListeners();
  }

  /// Clear local server configuration
  void clearLocalServer() {
    _localServerAddress = null;
    _isLocalNetworkAvailable = false;
    notifyListeners();
  }

  /// Get the appropriate upload endpoint
  String getUploadEndpoint(String? cloudEndpoint) {
    if (shouldUseCloud && cloudEndpoint != null) {
      return cloudEndpoint;
    } else if (_localServerAddress != null) {
      return '$_localServerAddress/upload';
    }
    throw Exception('No upload endpoint available');
  }

  /// Get the appropriate API base URL
  String getApiBaseUrl(String cloudBaseUrl) {
    if (shouldUseCloud) {
      return cloudBaseUrl;
    } else if (_localServerAddress != null) {
      return _localServerAddress!;
    }
    return cloudBaseUrl;
  }

  /// Check if we're on the expected DJ Wi-Fi network
  bool isOnDJNetwork(String expectedWifiName) {
    if (_currentWifiName == null) return false;
    return _currentWifiName!.toLowerCase().contains(expectedWifiName.toLowerCase());
  }

  /// Test connectivity to local server
  Future<bool> testLocalServerConnection() async {
    if (_localServerAddress == null) return false;

    try {
      // In a real implementation, ping the server
      // For now, just return the availability flag
      return _isLocalNetworkAvailable;
    } catch (e) {
      return false;
    }
  }

  /// Get connection status summary
  String get statusSummary {
    final buffer = StringBuffer();

    buffer.write('Mode: ${_currentMode.name}');
    buffer.write(' | Online: ${_isOnline ? "Yes" : "No"}');

    if (_currentWifiName != null) {
      buffer.write(' | Wi-Fi: $_currentWifiName');
    }

    if (_localServerAddress != null) {
      buffer.write(' | Local Server: $_localServerAddress');
    }

    return buffer.toString();
  }

  /// Get detailed connection info
  Map<String, dynamic> get connectionInfo {
    return {
      'mode': _currentMode.name,
      'isOnline': _isOnline,
      'isLocalNetworkAvailable': _isLocalNetworkAvailable,
      'currentWifiName': _currentWifiName,
      'localServerAddress': _localServerAddress,
      'shouldUseCloud': shouldUseCloud,
      'shouldUseLocal': shouldUseLocal,
    };
  }
}
