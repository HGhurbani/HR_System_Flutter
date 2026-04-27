import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/domain/entities/user_role.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/admin/presentation/screens/admin_shell.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/employees_list_screen.dart';
import '../../features/admin/presentation/screens/admin_attendance_screen.dart';
import '../../features/admin/presentation/screens/admin_leaves_screen.dart';
import '../../features/admin/presentation/screens/admin_salary_screen.dart';
import '../../features/admin/presentation/screens/admin_reports_screen.dart';
import '../../features/admin/presentation/screens/admin_settings_screen.dart';
import '../../features/admin/presentation/screens/admin_holidays_screen.dart';
import '../../features/supervisor/presentation/screens/supervisor_shell.dart';
import '../../features/supervisor/presentation/screens/supervisor_dashboard_screen.dart';
import '../../features/candidates/presentation/screens/candidates_list_screen.dart';
import '../../features/candidates/presentation/screens/candidate_form_screen.dart';
import '../../features/candidates/presentation/screens/candidate_detail_screen.dart';
import '../../features/employee/presentation/screens/employee_shell.dart';
import '../../features/employee/presentation/screens/employee_dashboard_screen.dart';
import '../../features/employee/presentation/screens/employee_attendance_screen.dart';
import '../../features/employee/presentation/screens/employee_salary_screen.dart';
import '../../features/employee/presentation/screens/employee_leaves_screen.dart';
import '../../features/employee/presentation/screens/employee_profile_screen.dart';
import '../../features/settings/presentation/screens/user_app_settings_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';

// Route names
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const notifications = '/notifications';

  // Admin
  static const adminShell = '/admin';
  static const adminDashboard = '/admin/dashboard';
  static const adminEmployees = '/admin/employees';
  static const adminSupervisors = '/admin/supervisors';
  static const adminCandidates = '/admin/candidates';
  static const adminCandidateDetail = '/admin/candidates/:id';
  static const adminAddCandidate = '/admin/candidates/add';
  static const adminEditCandidate = '/admin/candidates/:id/edit';
  static const adminAttendance = '/admin/attendance';
  static const adminLeaves = '/admin/leaves';
  static const adminSalary = '/admin/salary';
  static const adminReports = '/admin/reports';
  static const adminSettings = '/admin/settings';
  static const adminHolidays = '/admin/settings/holidays';

  // Supervisor
  static const supervisorShell = '/supervisor';
  static const supervisorDashboard = '/supervisor/dashboard';
  static const supervisorCandidates = '/supervisor/candidates';
  static const supervisorCandidateDetail = '/supervisor/candidates/:id';
  static const supervisorAddCandidate = '/supervisor/candidates/add';
  static const supervisorEditCandidate = '/supervisor/candidates/:id/edit';
  static const supervisorSettings = '/supervisor/settings';

  // Employee
  static const employeeShell = '/employee';
  static const employeeDashboard = '/employee/dashboard';
  static const employeeAttendance = '/employee/attendance';
  static const employeeSalary = '/employee/salary';
  static const employeeLeaves = '/employee/leaves';
  static const employeeProfile = '/employee/profile';
  static const employeeSettings = '/employee/settings';
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      // Wait for first auth emission; splash can show a spinner meanwhile.
      if (authState.isLoading) return null;

      // Treat stream errors as signed-out for navigation (e.g. Firestore denied).
      final user =
          authState.hasError ? null : authState.valueOrNull;
      final isAuthenticated = user != null;
      final location = state.matchedLocation;

      if (isAuthenticated) {
        // Signed in: leave auth entry points for role home
        if (location == AppRoutes.login ||
            location == AppRoutes.splash ||
            location == AppRoutes.forgotPassword) {
          return _homeRouteForUser(user);
        }

        // Role-based access
        if (location.startsWith('/admin') && !user.role.isAdmin) {
          return _homeRouteForUser(user);
        }
        if (location.startsWith('/supervisor') && !user.role.isSupervisor) {
          return _homeRouteForUser(user);
        }
        if (location.startsWith('/employee') && !user.role.isEmployee) {
          return _homeRouteForUser(user);
        }
        return null;
      }

      // Signed out: only login and forgot-password are allowed
      if (location == AppRoutes.login ||
          location == AppRoutes.forgotPassword) {
        return null;
      }
      return AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ── Admin Shell ──────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AdminShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminDashboard,
              builder: (context, state) => const AdminDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminEmployees,
              builder: (context, state) => const EmployeesListScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminCandidates,
              builder: (context, state) => const CandidatesListScreen(
                isAdminView: true,
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const CandidateFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CandidateDetailScreen(
                    candidateId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => CandidateFormScreen(
                        candidateId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminAttendance,
              builder: (context, state) => const AdminAttendanceScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminLeaves,
              builder: (context, state) => const AdminLeavesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminSalary,
              builder: (context, state) => const AdminSalaryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminReports,
              builder: (context, state) => const AdminReportsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.adminSettings,
              builder: (context, state) => const AdminSettingsScreen(),
              routes: [
                GoRoute(
                  path: 'holidays',
                  builder: (context, state) => const AdminHolidaysScreen(),
                ),
              ],
            ),
          ]),
        ],
      ),

      // ── Supervisor Shell ─────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => SupervisorShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.supervisorDashboard,
              builder: (context, state) => const SupervisorDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.supervisorCandidates,
              builder: (context, state) => const CandidatesListScreen(
                isAdminView: false,
              ),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (context, state) => const CandidateFormScreen(),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => CandidateDetailScreen(
                    candidateId: state.pathParameters['id']!,
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (context, state) => CandidateFormScreen(
                        candidateId: state.pathParameters['id'],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.supervisorSettings,
              builder: (context, state) => const UserAppSettingsScreen(),
            ),
          ]),
        ],
      ),

      // ── Employee Shell ───────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => EmployeeShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.employeeDashboard,
              builder: (context, state) => const EmployeeDashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.employeeAttendance,
              builder: (context, state) => const EmployeeAttendanceScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.employeeSalary,
              builder: (context, state) => const EmployeeSalaryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.employeeLeaves,
              builder: (context, state) => const EmployeeLeavesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.employeeProfile,
              builder: (context, state) => const EmployeeProfileScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.employeeSettings,
              builder: (context, state) => const UserAppSettingsScreen(),
            ),
          ]),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});

String _homeRouteForUser(AppUser user) {
  switch (user.role) {
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    case UserRole.supervisor:
      return AppRoutes.supervisorDashboard;
    case UserRole.employee:
      return AppRoutes.employeeDashboard;
  }
}
