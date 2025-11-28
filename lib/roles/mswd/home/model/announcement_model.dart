// File: C:\seelai_app\lib\roles\mswd\home\model\announcement_model.dart

class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String targetAudience;
  final List<String> specificUsers;
  final DateTime timestamp;
  final String createdBy;
  final String iconCodePoint;
  final int colorValue;

  AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.targetAudience,
    required this.specificUsers,
    required this.timestamp,
    required this.createdBy,
    required this.iconCodePoint,
    required this.colorValue,
  });

  // Convert to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'targetAudience': targetAudience,
      'specificUsers': specificUsers,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'createdBy': createdBy,
      'iconCodePoint': iconCodePoint,
      'colorValue': colorValue,
    };
  }

  // Create from JSON (Firebase)
  factory AnnouncementModel.fromJson(String id, Map<dynamic, dynamic> json) {
    return AnnouncementModel(
      id: id,
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      targetAudience: json['targetAudience'] ?? 'All Users',
      specificUsers: List<String>.from(json['specificUsers'] ?? []),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      createdBy: json['createdBy'] ?? 'Admin',
      iconCodePoint: json['iconCodePoint'] ?? '0xe047',
      colorValue: json['colorValue'] ?? 0xFFFF9800,
    );
  }

  // Copy with method for updates
  AnnouncementModel copyWith({
    String? id,
    String? title,
    String? message,
    String? targetAudience,
    List<String>? specificUsers,
    DateTime? timestamp,
    String? createdBy,
    String? iconCodePoint,
    int? colorValue,
  }) {
    return AnnouncementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      targetAudience: targetAudience ?? this.targetAudience,
      specificUsers: specificUsers ?? this.specificUsers,
      timestamp: timestamp ?? this.timestamp,
      createdBy: createdBy ?? this.createdBy,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      colorValue: colorValue ?? this.colorValue,
    );
  }
}