import 'user_role.dart';

class AppUser {
  static const String weeklyRestDaysModeCompany = 'company';
  static const String weeklyRestDaysModeCustom = 'custom';

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
  final String weeklyRestDaysMode;
  final List<int> customWeeklyRestDays;
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
    this.weeklyRestDaysMode = weeklyRestDaysModeCompany,
    this.customWeeklyRestDays = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get usesCustomWeeklyRestDays =>
      weeklyRestDaysMode == weeklyRestDaysModeCustom;

  List<int> effectiveWeeklyRestDays(List<int> companyWeeklyRestDays) {
    final customDays = sanitizeWeeklyRestDays(customWeeklyRestDays);
    if (usesCustomWeeklyRestDays && customDays.isNotEmpty) {
      return customDays;
    }
    return sanitizeWeeklyRestDays(companyWeeklyRestDays);
  }

  static String normalizeWeeklyRestDaysMode(String? mode) {
    return mode == weeklyRestDaysModeCustom
        ? weeklyRestDaysModeCustom
        : weeklyRestDaysModeCompany;
  }

  static List<int> sanitizeWeeklyRestDays(Iterable<int> days) {
    final sanitized = days
        .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
        .toSet()
        .toList()
      ..sort();
    if (sanitized.length >= 7) return const [];
    return List.unmodifiable(sanitized);
  }

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
    String? weeklyRestDaysMode,
    List<int>? customWeeklyRestDays,
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
      weeklyRestDaysMode: weeklyRestDaysMode ?? this.weeklyRestDaysMode,
      customWeeklyRestDays: customWeeklyRestDays ?? this.customWeeklyRestDays,
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
  String toString() =>
      'AppUser(uid: $uid, name: $fullName, role: ${role.value})';
}
