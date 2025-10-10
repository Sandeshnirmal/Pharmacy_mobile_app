class UserProfile {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? emergencyContactName;
  final String? profileImage;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Address information
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? country;

  // Medical information
  final List<String> allergies;
  final List<String> chronicConditions;
  final List<String> currentMedications;
  final String? insuranceProvider;
  final String? insuranceNumber;

  // App preferences
  final bool notificationsEnabled;
  final bool emailNotifications;
  final bool smsNotifications;
  final String preferredLanguage;

  UserProfile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    this.emergencyContact,
    this.emergencyContactName,
    this.profileImage,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.country,
    this.allergies = const [],
    this.chronicConditions = const [],
    this.currentMedications = const [],
    this.insuranceProvider,
    this.insuranceNumber,
    this.notificationsEnabled = true,
    this.emailNotifications = true,
    this.smsNotifications = true,
    this.preferredLanguage = 'English',
  });

  String get fullName => '$firstName $lastName';

  String get displayName {
    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else {
      return email.split('@')[0];
    }
  }

  String get initials {
    String first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    String last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    if (first.isEmpty && last.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : 'U';
    }
    return '$first$last';
  }

  int get age {
    if (dateOfBirth == null) return 0;
    try {
      final birthDate = DateTime.parse(dateOfBirth!);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String get formattedAddress {
    List<String> addressParts = [];
    if (address != null && address!.isNotEmpty) addressParts.add(address!);
    if (city != null && city!.isNotEmpty) addressParts.add(city!);
    if (state != null && state!.isNotEmpty) addressParts.add(state!);
    if (pincode != null && pincode!.isNotEmpty) addressParts.add(pincode!);
    if (country != null && country!.isNotEmpty) addressParts.add(country!);

    return addressParts.join(', ');
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      phone: json['phone'],
      dateOfBirth: json['date_of_birth'],
      gender: json['gender'],
      bloodGroup: json['blood_group'],
      emergencyContact: json['emergency_contact'],
      emergencyContactName: json['emergency_contact_name'],
      profileImage: json['profile_image'],
      isVerified: json['is_verified'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      address: json['address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      country: json['country'],
      allergies: json['allergies'] != null
          ? List<String>.from(json['allergies'])
          : [],
      chronicConditions: json['chronic_conditions'] != null
          ? List<String>.from(json['chronic_conditions'])
          : [],
      currentMedications: json['current_medications'] != null
          ? List<String>.from(json['current_medications'])
          : [],
      insuranceProvider: json['insurance_provider'],
      insuranceNumber: json['insurance_number'],
      notificationsEnabled: json['notifications_enabled'] ?? true,
      emailNotifications: json['email_notifications'] ?? true,
      smsNotifications: json['sms_notifications'] ?? true,
      preferredLanguage: json['preferred_language'] ?? 'English',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'blood_group': bloodGroup,
      'emergency_contact': emergencyContact,
      'emergency_contact_name': emergencyContactName,
      'profile_image': profileImage,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'country': country,
      'allergies': allergies,
      'chronic_conditions': chronicConditions,
      'current_medications': currentMedications,
      'insurance_provider': insuranceProvider,
      'insurance_number': insuranceNumber,
      'notifications_enabled': notificationsEnabled,
      'email_notifications': emailNotifications,
      'sms_notifications': smsNotifications,
      'preferred_language': preferredLanguage,
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? emergencyContact,
    String? emergencyContactName,
    String? profileImage,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? country,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<String>? currentMedications,
    String? insuranceProvider,
    String? insuranceNumber,
    bool? notificationsEnabled,
    bool? emailNotifications,
    bool? smsNotifications,
    String? preferredLanguage,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      profileImage: profileImage ?? this.profileImage,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      country: country ?? this.country,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      currentMedications: currentMedications ?? this.currentMedications,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: $fullName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id && other.email == email;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode;
}
