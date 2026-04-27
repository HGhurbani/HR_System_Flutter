class AppConstants {
  AppConstants._();

  // Firestore Collections
  static const String usersCollection = 'users';
  static const String employeesCollection = 'employees';
  static const String supervisorsCollection = 'supervisors';
  static const String candidateProfilesCollection = 'candidate_profiles';
  static const String attendanceLogsCollection = 'attendance_logs';
  static const String leaveRequestsCollection = 'leave_requests';
  static const String permissionRequestsCollection = 'permission_requests';
  static const String salariesCollection = 'salaries';
  static const String commissionsCollection = 'commissions';
  static const String employeeCompensationCollection =
      'employee_compensation_profiles';
  static const String adminUserCreationRequestsCollection =
      'admin_user_creation_requests';
  static const String companySettingsCollection = 'company_settings';
  /// Company-wide official holidays applied to all employees.
  static const String companyHolidaysCollection = 'company_holidays';
  /// Firestore doc id for shift start times & lateness grace (admin-editable).
  static const String companyWorkHoursDocId = 'work_hours';
  /// Firestore doc id for payroll attendance policy.
  static const String companyAttendancePolicyDocId = 'attendance_policy';
  static const String companyLocationsCollection = 'company_locations';
  static const String activityLogsCollection = 'activity_logs';
  static const String notificationsCollection = 'notifications';

  // SharedPrefs Keys
  static const String prefLanguageCode = 'language_code';
  static const String prefThemeMode = 'theme_mode';
  static const String prefRememberMe = 'remember_me';
  static const String prefUserId = 'user_id';

  // Firebase Storage Paths
  static const String storageAvatars = 'avatars';
  static const String storageCandidateImages = 'candidate_images';
  static const String storageCandidateCVs = 'candidate_cvs';
  static const String storageCandidateVideos = 'candidate_videos';

  // Default Geofence Radius (meters)
  static const double defaultGeofenceRadius = 200.0;

  // Pagination
  static const int defaultPageSize = 20;

  // Date Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'yyyy-MM-dd HH:mm';
  static const String displayDateFormat = 'dd/MM/yyyy';
  static const String displayTimeFormat = 'hh:mm a';
  static const String displayMonthYear = 'MMMM yyyy';

  // Session timeout (minutes)
  static const int sessionTimeoutMinutes = 30;

  // Max file sizes (bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const int maxCvSize = 10 * 1024 * 1024; // 10 MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50 MB

  // App version
  static const String appVersion = '1.0.0';
}
