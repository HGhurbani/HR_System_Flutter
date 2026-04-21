import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/data/models/user_model.dart';
import '../../auth/domain/entities/user_role.dart';

final employeesProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.usersCollection)
      .where('role', isEqualTo: UserRole.employee.value)
      .orderBy('fullName')
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
});

final supervisorsProvider = StreamProvider<List<UserModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.usersCollection)
      .where('role', isEqualTo: UserRole.supervisor.value)
      .orderBy('fullName')
      .snapshots()
      .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
});

class ManagedUserCreationResult {
  final String requestId;
  final String userId;
  final String temporaryPassword;

  const ManagedUserCreationResult({
    required this.requestId,
    required this.userId,
    required this.temporaryPassword,
  });
}

class ManagedUserService {
  final FirebaseFirestore _firestore;
  final String _adminId;
  final String _adminName;

  const ManagedUserService({
    required FirebaseFirestore firestore,
    required String adminId,
    required String adminName,
  })  : _firestore = firestore,
        _adminId = adminId,
        _adminName = adminName;

  Future<ManagedUserCreationResult> createManagedUser({
    required UserRole role,
    required String fullName,
    required String email,
    String? phone,
    String? position,
    String? department,
    String? employeeCode,
    DateTime? hireDate,
    bool isActive = true,
    bool mustChangePassword = true,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    if (_adminId.isEmpty) {
      throw const AppException(
        message: 'Admin session not available',
        code: 'admin-session-missing',
      );
    }

    final temporaryPassword = _generateTemporaryPassword();
    final docRef = _firestore
        .collection(AppConstants.adminUserCreationRequestsCollection)
        .doc();

    await docRef.set({
      'fullName': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone?.trim(),
      'role': role.value,
      'position': position?.trim(),
      'department': department?.trim(),
      'employeeCode': employeeCode?.trim(),
      'hireDate': hireDate != null ? Timestamp.fromDate(hireDate) : null,
      'temporaryPassword': temporaryPassword,
      'mustChangePassword': mustChangePassword,
      'isActive': isActive,
      'status': 'pending',
      'requestedByAdminId': _adminId,
      'requestedByAdminName': _adminName,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final completer = Completer<ManagedUserCreationResult>();
    late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>
        subscription;

    subscription = docRef.snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;

      final status = (data['status'] as String?) ?? 'pending';
      if (status == 'completed' && !completer.isCompleted) {
        completer.complete(
          ManagedUserCreationResult(
            requestId: docRef.id,
            userId: data['createdUserId'] as String? ?? '',
            temporaryPassword: temporaryPassword,
          ),
        );
      }

      if (status == 'failed' && !completer.isCompleted) {
        completer.completeError(
          AppException(
            message:
                data['errorMessage'] as String? ?? 'Managed user creation failed',
            code: 'managed-user-create-failed',
          ),
        );
      }
    });

    try {
      final result = await completer.future.timeout(
        timeout,
        onTimeout: () {
          throw const AppException(
            message:
                'User creation request is still pending. Ensure the admin backend function is deployed.',
            code: 'managed-user-create-timeout',
          );
        },
      );
      return result;
    } finally {
      await subscription.cancel();
    }
  }

  String _generateTemporaryPassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#';
    final random = Random.secure();
    return List.generate(
      10,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }
}

final managedUserServiceProvider = Provider<ManagedUserService>((ref) {
  final currentUser = ref.watch(currentUserProvider);
  return ManagedUserService(
    firestore: ref.watch(firestoreProvider),
    adminId: currentUser?.uid ?? '',
    adminName: currentUser?.fullName ?? '',
  );
});
