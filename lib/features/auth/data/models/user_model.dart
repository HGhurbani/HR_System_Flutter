import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/entities/user_role.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    super.phone,
    required super.role,
    super.languagePreference,
    super.isActive,
    super.avatarUrl,
    super.employeeCode,
    super.department,
    super.position,
    super.hireDate,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      role: UserRole.fromString(data['role'] as String? ?? 'employee'),
      languagePreference: data['languagePreference'] as String? ?? 'ar',
      isActive: data['isActive'] as bool? ?? true,
      avatarUrl: data['avatarUrl'] as String?,
      employeeCode: data['employeeCode'] as String?,
      department: data['department'] as String?,
      position: data['position'] as String?,
      hireDate: data['hireDate'] != null
          ? (data['hireDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String?,
      role: UserRole.fromString(data['role'] as String? ?? 'employee'),
      languagePreference: data['languagePreference'] as String? ?? 'ar',
      isActive: data['isActive'] as bool? ?? true,
      avatarUrl: data['avatarUrl'] as String?,
      employeeCode: data['employeeCode'] as String?,
      department: data['department'] as String?,
      position: data['position'] as String?,
      hireDate: data['hireDate'] != null
          ? (data['hireDate'] as Timestamp).toDate()
          : null,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role.value,
      'languagePreference': languagePreference,
      'isActive': isActive,
      'avatarUrl': avatarUrl,
      'employeeCode': employeeCode,
      'department': department,
      'position': position,
      'hireDate': hireDate != null ? Timestamp.fromDate(hireDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory UserModel.fromAppUser(AppUser user) => UserModel(
        uid: user.uid,
        fullName: user.fullName,
        email: user.email,
        phone: user.phone,
        role: user.role,
        languagePreference: user.languagePreference,
        isActive: user.isActive,
        avatarUrl: user.avatarUrl,
        employeeCode: user.employeeCode,
        department: user.department,
        position: user.position,
        hireDate: user.hireDate,
        createdAt: user.createdAt,
        updatedAt: user.updatedAt,
      );
}
