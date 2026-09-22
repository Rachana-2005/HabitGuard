/// User Profile model stored under users/{uid} in Firestore
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? guardianName;
  final String? guardianMobile;
  final String countryCode;
  final bool notificationEnabled;
  final bool isProfileComplete;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastLoginAt;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.guardianName,
    this.guardianMobile,
    this.countryCode = '+91',
    this.notificationEnabled = true,
    this.isProfileComplete = false,
    required this.createdAt,
    required this.updatedAt,
    required this.lastLoginAt,
  });

  /// Full normalized guardian mobile number (with country code prefix)
  String get formattedGuardianMobile {
    if (guardianMobile == null || guardianMobile!.isEmpty) return '';
    if (guardianMobile!.startsWith('+')) return guardianMobile!;
    return '$countryCode$guardianMobile';
  }

  /// Creates a copy with specified fields replaced
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? photoUrl,
    String? guardianName,
    String? guardianMobile,
    String? countryCode,
    bool? notificationEnabled,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      guardianName: guardianName ?? this.guardianName,
      guardianMobile: guardianMobile ?? this.guardianMobile,
      countryCode: countryCode ?? this.countryCode,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'guardianName': guardianName,
      'guardianMobile': guardianMobile,
      'countryCode': countryCode,
      'notificationEnabled': notificationEnabled,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      guardianName: map['guardianName'] as String?,
      guardianMobile: map['guardianMobile'] as String?,
      countryCode: map['countryCode'] as String? ?? '+91',
      notificationEnabled: map['notificationEnabled'] as bool? ?? true,
      isProfileComplete: map['isProfileComplete'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.tryParse(map['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      lastLoginAt: map['lastLoginAt'] != null
          ? DateTime.tryParse(map['lastLoginAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
