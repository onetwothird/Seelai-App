
// File: lib/roles/partially_sighted/services/accessibility_service.dart
import 'package:flutter/foundation.dart';

class AccessibilityService {
  final List<Function(String)> _listeners = [];

  /// Announce a message to screen readers
  void announce(String message) {
    debugPrint('Accessibility announcement: $message');
    // Notify all listeners
    for (var listener in _listeners) {
      listener(message);
    }
  }

  void addListener(Function(String) listener) {
    _listeners.add(listener);
  }

  void removeListener(Function(String) listener) {
    _listeners.remove(listener);
  }

  void clearListeners() {
    _listeners.clear();
  }

  Future<void> announceDelayed(String message, Duration delay) async {
    await Future.delayed(delay);
    announce(message);
  }

  Future<void> announceSequence(List<String> messages, Duration delayBetween) async {
    for (var message in messages) {
      announce(message);
      if (message != messages.last) {
        await Future.delayed(delayBetween);
      }
    }
  }
}