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
    // CRITICAL FIX: Safely parse age to prevent silent crashes in release mode
    // if Firestore accidentally returns it as a String (e.g., "25") instead of an int.
    int parsedAge = 0;
    if (json['age'] != null) {
      parsedAge = json['age'] is int 
          ? json['age'] 
          : int.tryParse(json['age'].toString()) ?? 0;
    }

    return PatientModel(
      id: id,
      name: json['name']?.toString() ?? 'Unknown',
      age: parsedAge,
      disabilityType: json['disabilityType']?.toString() ?? 'Not specified',
      contactNumber: json['contactNumber']?.toString(),
      address: json['address']?.toString(),
      lastLocation: json['lastLocation'] as Map<String, dynamic>?,
      lastActive: json['lastActive'] != null
          ? DateTime.tryParse(json['lastActive'].toString())
          : null,
      isOnline: json['isOnline'] == true,
      profileImageUrl: json['profileImageUrl']?.toString(),
      patientProfileImageUrl: json['patientProfileImageUrl']?.toString(),
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
      'profileImageUrl': profileImageUrl,
      'patientProfileImageUrl': patientProfileImageUrl,
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
    String? profileImageUrl,
    String? patientProfileImageUrl,
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
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      patientProfileImageUrl: patientProfileImageUrl ?? this.patientProfileImageUrl,
    );
  }
}