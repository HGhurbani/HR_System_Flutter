enum UserRole {
  admin,
  supervisor,
  employee;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'supervisor':
        return UserRole.supervisor;
      case 'employee':
        return UserRole.employee;
      default:
        return UserRole.employee;
    }
  }

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.employee:
        return 'employee';
    }
  }

  bool get isAdmin => this == UserRole.admin;
  bool get isSupervisor => this == UserRole.supervisor;
  bool get isEmployee => this == UserRole.employee;

  bool get canManageCandidates =>
      this == UserRole.admin || this == UserRole.supervisor;
  bool get canManageUsers => this == UserRole.admin;
  bool get canApproveLeaves => this == UserRole.admin;
  bool get canManageSalaries => this == UserRole.admin;
  bool get canViewReports => this == UserRole.admin;
}
