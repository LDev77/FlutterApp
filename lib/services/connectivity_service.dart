import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global service for tracking app connectivity status
/// Connected = any successful HTTP response
/// Disconnected = TCP/IP connection errors only
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

  /// Mark as disconnected (call only for TCP/IP connection errors)
  void markDisconnected() {
    if (_isConnected) {
      _isConnected = false;
      debugPrint('📵 Connectivity: DISCONNECTED');
      notifyListeners();
    }
  }

  /// Get status text for display
  String get statusText => _isConnected ? 'Connected' : 'No Connection';

  /// Get status icon
  IconData get statusIcon => _isConnected
    ? Icons.info_outline
    : Icons.wifi_off_rounded;

  /// Get status color
  Color get statusColor => _isConnected
    ? Colors.blue.shade600
    : Colors.orange.shade600;
}