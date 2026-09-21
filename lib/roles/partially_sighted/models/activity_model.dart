// File: lib/roles/partially_sighted/models/activity_model.dart
// No Flutter imports required here; keep model pure Dart to simplify analysis

class ActivityModel {
  final String title;
  final String description;
  final int iconCode;
  final bool isEmergency;
  final DateTime? timestamp;

  ActivityModel({
    required this.title,
    required this.description,
    required this.iconCode,
    this.isEmergency = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Create from JSON
  factory ActivityModel.fromJson(Map<String, dynamic> json) {
    return ActivityModel(
      title: json['title'] as String,
      description: json['description'] as String,
      iconCode: json['iconCode'] as int,
      isEmergency: json['isEmergency'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'iconCode': iconCode,
      'isEmergency': isEmergency,
      'timestamp': timestamp?.toIso8601String(),
    };
  }

  // Copy with method for immutable updates
  ActivityModel copyWith({
    String? newTitle,
    String? newDescription,
    int? icon,
    bool? newIsEmergency,
    DateTime? newTimestamp,
  }) {
    return ActivityModel(
      title: newTitle ?? title,
      description: newDescription ?? description,
      iconCode: icon ?? iconCode,
      isEmergency: newIsEmergency ?? isEmergency,
      timestamp: newTimestamp ?? timestamp,
    );
  }

  @override
  String toString() {
    return 'ActivityModel(title: $title, description: $description, isEmergency: $isEmergency)';
  }
}
