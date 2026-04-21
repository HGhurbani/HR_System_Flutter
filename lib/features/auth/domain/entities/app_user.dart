import 'user_role.dart';

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final String languagePreference;
  final bool isActive;
  final String? avatarUrl;
  final String? employeeCode;
  final String? department;
  final String? position;
  final DateTime? hireDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.languagePreference = 'ar',
    this.isActive = true,
    this.avatarUrl,
    this.employeeCode,
    this.department,
    this.position,
    this.hireDate,
    required this.createdAt,
    required this.updatedAt,
  });

  AppUser copyWith({
    String? uid,
    String? fullName,
    String? email,
    String? phone,
    UserRole? role,
    String? languagePreference,
    bool? isActive,
    String? avatarUrl,
    String? employeeCode,
    String? department,
    String? position,
    DateTime? hireDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      languagePreference: languagePreference ?? this.languagePreference,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      employeeCode: employeeCode ?? this.employeeCode,
      department: department ?? this.department,
      position: position ?? this.position,
      hireDate: hireDate ?? this.hireDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppUser && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;

  @override
  String toString() => 'AppUser(uid: $uid, name: $fullName, role: ${role.value})';
}
