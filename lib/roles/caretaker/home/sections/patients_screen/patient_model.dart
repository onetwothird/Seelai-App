// File: lib/roles/caretaker/home/sections/patients_screen/patient_model.dart

class PatientModel {
  final String id;
  final String name;
  final int age;
  final String disabilityType;
  final String? contactNumber;
  final String? address;
  final Map<String, dynamic>? lastLocation;
  final DateTime? lastActive;
  final bool isOnline;
  final String? profileImageUrl;
  final String? patientProfileImageUrl; // Add this line

  PatientModel({
    required this.id,
    required this.name,
    required this.age,
    required this.disabilityType,
    this.contactNumber,
    this.address,
    this.lastLocation,
    this.lastActive,
    this.isOnline = false,
    this.profileImageUrl, 
    this.patientProfileImageUrl, // Add this line

  });

  factory PatientModel.fromJson(Map<String, dynamic> json, String id) {
    return PatientModel(
      id: id,
      name: json['name'] as String,
      age: json['age'] as int,
      disabilityType: json['disabilityType'] as String? ?? 'Not specified',
      contactNumber: json['contactNumber'] as String?,
      address: json['address'] as String?,
      lastLocation: json['lastLocation'] as Map<String, dynamic>?,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'] as String)
          : null,
      isOnline: json['isOnline'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'disabilityType': disabilityType,
      'contactNumber': contactNumber,
      'address': address,
      'lastLocation': lastLocation,
      'lastActive': lastActive?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  PatientModel copyWith({
    String? id,
    String? name,
    int? age,
    String? disabilityType,
    String? contactNumber,
    String? address,
    Map<String, dynamic>? lastLocation,
    DateTime? lastActive,
    bool? isOnline,
  }) {
    return PatientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      disabilityType: disabilityType ?? this.disabilityType,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      lastLocation: lastLocation ?? this.lastLocation,
      lastActive: lastActive ?? this.lastActive,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}