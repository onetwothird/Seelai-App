// File: lib/roles/caretaker/services/notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';

class NotificationService {
  final StreamController<String> _notificationController = StreamController<String>.broadcast();
  
  Stream<String> get notificationStream => _notificationController.stream;
  
  void sendNotification(String message) {
    debugPrint('Notification: $message');
    _notificationController.add(message);
  }
  
  void dispose() {
    _notificationController.close();
  }
}