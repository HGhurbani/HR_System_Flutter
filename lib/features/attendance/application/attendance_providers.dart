import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notifications_providers.dart';
import '../data/models/attendance_model.dart';
import '../data/models/attendance_policy_model.dart';
import '../data/models/company_work_schedule.dart';

// ─── Company Location Model ────────────────────────────────────────────────
class CompanyLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final bool isActive;

  const CompanyLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.isActive = true,
  });

  factory CompanyLocation.fromMap(Map<String, dynamic> data, String id) {
    return CompanyLocation(
      id: id,
      name: data['name'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      radius: (data['radius'] as num?)?.toDouble() ??
          AppConstants.defaultGeofenceRadius,
      isActive: data['isActive'] as bool? ?? true,
    );
  }
}

// ─── Today's Attendance ───────────────────────────────────────────────────
final todayAttendanceProvider =
    StreamProvider<AttendanceModel?>((ref) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final firestore = ref.watch(firestoreProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  yield* firestore
      .collection(AppConstants.attendanceLogsCollection)
      .where('employeeId', isEqualTo: user.uid)
      .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThan: Timestamp.fromDate(endOfDay))
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isNotEmpty
          ? AttendanceModel.fromFirestore(snap.docs.first)
          : null);
});

// ─── Attendance History ────────────────────────────────────────────────────
final attendanceHistoryProvider =
    StreamProvider.family<List<AttendanceModel>, String>(
        (ref, employeeId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.attendanceLogsCollection)
      .where('employeeId', isEqualTo: employeeId)
      .orderBy('date', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) =>
          snap.docs.map(AttendanceModel.fromFirestore).toList());
});

// ─── All Attendance (Admin) ────────────────────────────────────────────────
final allAttendanceProvider = StreamProvider<List<AttendanceModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  return firestore
      .collection(AppConstants.attendanceLogsCollection)
      .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(AttendanceModel.fromFirestore).toList());
});

// ─── Company Locations ─────────────────────────────────────────────────────
final companyLocationsProvider =
    StreamProvider<List<CompanyLocation>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.companyLocationsCollection)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => CompanyLocation.fromMap(doc.data(), doc.id))
          .toList());
});

final allCompanyLocationsProvider =
    StreamProvider<List<CompanyLocation>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.companyLocationsCollection)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => CompanyLocation.fromMap(doc.data(), doc.id))
          .toList());
});

/// Shift start times and lateness grace (document `company_settings/work_hours`).
final workScheduleProvider =
    StreamProvider<CompanyWorkSchedule>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.companySettingsCollection)
      .doc(AppConstants.companyWorkHoursDocId)
      .snapshots()
      .map((snap) => CompanyWorkSchedule.fromMap(snap.data()));
});

/// Payroll attendance policy (document `company_settings/attendance_policy`).
final attendancePolicyProvider =
    StreamProvider<AttendancePolicyModel>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.companySettingsCollection)
      .doc(AppConstants.companyAttendancePolicyDocId)
      .snapshots()
      .map((snap) => AttendancePolicyModel.fromMap(snap.data()));
});

// ─── Check-In/Out Notifier ─────────────────────────────────────────────────
class AttendanceState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final Position? currentPosition;
  final bool isInsideGeofence;

  const AttendanceState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.currentPosition,
    this.isInsideGeofence = false,
  });

  AttendanceState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    Position? currentPosition,
    bool? isInsideGeofence,
  }) {
    return AttendanceState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      currentPosition: currentPosition ?? this.currentPosition,
      isInsideGeofence: isInsideGeofence ?? this.isInsideGeofence,
    );
  }
}

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final FirebaseFirestore _firestore;
  final String _employeeId;
  final String _employeeName;
  final NotificationsService _notifications;

  AttendanceNotifier({
    required FirebaseFirestore firestore,
    required String employeeId,
    required String employeeName,
    required NotificationsService notifications,
  })  : _firestore = firestore,
        _employeeId = employeeId,
        _employeeName = employeeName,
        _notifications = notifications,
        super(const AttendanceState());

  Future<bool> getLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const AppException(
          message: 'Location services are disabled',
          code: 'location-disabled',
        );
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw const AppException(
          message: 'Location permission denied',
          code: 'permission-denied',
        );
      }
      if (permission == LocationPermission.deniedForever) {
        throw const AppException(
          message: 'Location permission permanently denied',
          code: 'permission-denied-forever',
        );
      }

      final position = await _getCurrentPositionWithFallback();
      state = state.copyWith(isLoading: false, currentPosition: position);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.code);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'gps-error');
      return false;
    }
  }

  /// Medium accuracy + timeout (works better indoors), then low accuracy, then last known.
  Future<Position> _getCurrentPositionWithFallback() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 22),
        ),
      );
    } on TimeoutException catch (_) {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        final age = DateTime.now().difference(last.timestamp);
        if (age.inMinutes <= 15) {
          return last;
        }
      }
      return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
    }
  }

  bool checkGeofence(
      Position position, List<CompanyLocation> locations) {
    for (final loc in locations) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        loc.latitude,
        loc.longitude,
      );
      if (distance <= loc.radius) {
        state = state.copyWith(isInsideGeofence: true);
        return true;
      }
    }
    state = state.copyWith(isInsideGeofence: false);
    return false;
  }

  Future<bool> checkIn({
    required Position position,
    required bool insideGeofence,
    required ShiftType shiftType,
    required CompanyWorkSchedule workSchedule,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Check if already checked in
      final existing = await _firestore
          .collection(AppConstants.attendanceLogsCollection)
          .where('employeeId', isEqualTo: _employeeId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw const AppException(
            message: 'Already checked in today',
            code: 'already-checked-in');
      }

      final doc = _firestore
          .collection(AppConstants.attendanceLogsCollection)
          .doc();

      final shiftStart = workSchedule.shiftStartOnDay(now, shiftType);
      final grace = workSchedule.graceMinutesFor(shiftType, day: now);
      final lateMinutes = now.isAfter(shiftStart)
          ? now.difference(shiftStart).inMinutes
          : 0;

      final attendance = AttendanceModel(
        id: doc.id,
        employeeId: _employeeId,
        employeeName: _employeeName,
        date: startOfDay,
        shiftType: shiftType,
        checkInTime: now,
        checkInLat: position.latitude,
        checkInLng: position.longitude,
        insideGeofence: insideGeofence,
        status: lateMinutes > grace
            ? AttendanceStatus.late
            : AttendanceStatus.present,
        latenessMinutes: lateMinutes > 0 ? lateMinutes : 0,
        createdAt: now,
      );

      await doc.set(attendance.toMap());
      await _notify(
        title: 'تم تسجيل حضور',
        body: 'سجل $_employeeName الحضور',
        type: 'attendance_check_in',
        targetUserId: adminNotificationTarget,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> checkOut({
    required String attendanceId,
    required Position position,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _firestore
          .collection(AppConstants.attendanceLogsCollection)
          .doc(attendanceId)
          .update({
        'checkOutTime': FieldValue.serverTimestamp(),
          'checkOutLat': position.latitude,
          'checkOutLng': position.longitude,
      });
      await _notify(
        title: 'تم تسجيل انصراف',
        body: 'سجل $_employeeName الانصراف',
        type: 'attendance_check_out',
        targetUserId: adminNotificationTarget,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
          isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    state = const AttendanceState();
  }

  Future<void> _notify({
    required String title,
    required String body,
    required String type,
    required String targetUserId,
  }) async {
    try {
      await _notifications.create(
        title: title,
        body: body,
        type: type,
        targetUserId: targetUserId,
      );
    } catch (_) {}
  }
}

final attendanceNotifierProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final user = ref.watch(currentUserProvider);
  return AttendanceNotifier(
    firestore: ref.watch(firestoreProvider),
    employeeId: user?.uid ?? '',
    employeeName: user?.fullName ?? '',
    notifications: ref.watch(notificationsServiceProvider),
  );
});
