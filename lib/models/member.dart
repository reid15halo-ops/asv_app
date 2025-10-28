import 'package:asv_app/models/member_group.dart';

/// Member Model - Repräsentiert ein Vereinsmitglied
class Member {
  final int? id;
  final String userId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final DateTime? birthDate;
  final MemberGroup memberGroup;
  final String? profileImageUrl;
  final DateTime? joinedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Member({
    this.id,
    required this.userId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.birthDate,
    this.memberGroup = MemberGroup.aktive,
    this.profileImageUrl,
    this.joinedAt,
    this.createdAt,
    this.updatedAt,
  });

  /// Vollständiger Name
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    if (firstName != null) return firstName!;
    if (lastName != null) return lastName!;
    return 'Unbenanntes Mitglied';
  }

  /// Initialen für Avatar
  String get initials {
    String result = '';
    if (firstName != null && firstName!.isNotEmpty) {
      result += firstName![0].toUpperCase();
    }
    if (lastName != null && lastName!.isNotEmpty) {
      result += lastName![0].toUpperCase();
    }
    if (result.isEmpty) {
      result = 'M';
    }
    return result;
  }

  /// Alter berechnen
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// Mitgliedsdauer in Jahren
  int? get membershipYears {
    if (joinedAt == null) return null;
    final now = DateTime.now();
    int years = now.year - joinedAt!.year;
    if (now.month < joinedAt!.month ||
        (now.month == joinedAt!.month && now.day < joinedAt!.day)) {
      years--;
    }
    return years > 0 ? years : 0;
  }

  /// Erstelle Member aus JSON
  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      memberGroup: MemberGroup.fromString(json['member_group'] as String?),
      profileImageUrl: json['profile_image_url'] as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Konvertiere Member zu JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
      'member_group': memberGroup.value,
      if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
      if (joinedAt != null) 'joined_at': joinedAt!.toIso8601String(),
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Erstelle eine Kopie mit geänderten Werten
  Member copyWith({
    int? id,
    String? userId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? birthDate,
    MemberGroup? memberGroup,
    String? profileImageUrl,
    DateTime? joinedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      memberGroup: memberGroup ?? this.memberGroup,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joinedAt: joinedAt ?? this.joinedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Member{id: $id, name: $fullName, group: ${memberGroup.displayName}}';
  }
}
