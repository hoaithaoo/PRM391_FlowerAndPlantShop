import '../enums/app_enums.dart';

class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? phone;
  final String? avatarUrl;
  final UserRole role;
  final AccountStatus status;

  const UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.phone,
    this.avatarUrl,
    required this.role,
    required this.status,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isActive => status == AccountStatus.active;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String?,
      phone: json['phone'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      status: AccountStatus.fromString(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'phone': phone,
    'avatarUrl': avatarUrl,
    'role': role.toApiString(),
    'status': status.toApiString(),
  };
}
