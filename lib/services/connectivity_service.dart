import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global service for tracking Infiniteer API connection status
/// Connected = successful API response (200-299)
/// Disconnected = any API failure (400-500, timeouts, network errors)
class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get instance => _instance;

  ConnectivityService._internal();

  bool _isConnected = true; // Start optimistic
  bool get isConnected => _isConnected;

  /// Mark as connected (call after any successful HTTP response)
  void markConnected() {
    if (!_isConnected) {
      _isConnected = true;
      debugPrint('🌐 Connectivity: CONNECTED');
      notifyListeners();
    }
  }

  /// Mark as disconnected (call for any API failure: 400-500, timeouts, network errors)
  void markDisconnected() {
    if (_isConnected) {
      _isConnected = false;
      debugPrint('📵 Connectivity: DISCONNECTED');
      notifyListeners();
    }
  }

  /// Get status text for display
  String get statusText => _isConnected ? 'Connected' : 'Service issue with your network or Infiniteer';

  /// Get status icon
  IconData get statusIcon => _isConnected
    ? Icons.info_outline
    : Icons.error;

  /// Get status color
  Color get statusColor => _isConnected
    ? Colors.blue.shade600
    : Colors.orange.shade600;
}