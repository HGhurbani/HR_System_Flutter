import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../../notifications/application/notifications_providers.dart';
import '../data/models/candidate_model.dart';
import '../domain/entities/candidate_status.dart';

// ─── Filter State ─────────────────────────────────────────────────────────
class CandidateFilter {
  final CandidateStatus? status;
  final String searchQuery;

  const CandidateFilter({
    this.status,
    this.searchQuery = '',
  });

  CandidateFilter copyWith({
    CandidateStatus? status,
    String? searchQuery,
    bool clearStatus = false,
  }) {
    return CandidateFilter(
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters => status != null;
}

final candidateFilterProvider =
    StateProvider<CandidateFilter>((ref) => const CandidateFilter());

// ─── Candidates Stream ────────────────────────────────────────────────────
final candidatesStreamProvider =
    StreamProvider.family<List<CandidateModel>, CandidateFilter>(
        (ref, filter) {
  final firestore = ref.watch(firestoreProvider);
  Query<Map<String, dynamic>> query = firestore
      .collection(AppConstants.candidateProfilesCollection)
      .orderBy('createdAt', descending: true);

  if (filter.status != null) {
    query = query.where('status', isEqualTo: filter.status!.value);
  }

  return query.snapshots().map((snap) =>
      snap.docs.map(CandidateModel.fromFirestore).toList());
});

// ─── Single Candidate ─────────────────────────────────────────────────────
final candidateDetailProvider =
    StreamProvider.family<CandidateModel?, String>((ref, id) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.candidateProfilesCollection)
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? CandidateModel.fromFirestore(doc) : null);
});

// ─── Supervisor-scoped candidates ────────────────────────────────────────
final supervisorCandidatesProvider =
    StreamProvider.family<List<CandidateModel>, CandidateFilter>(
        (ref, filter) {
  final firestore = ref.watch(firestoreProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return const Stream.empty();

  Query<Map<String, dynamic>> query = firestore
      .collection(AppConstants.candidateProfilesCollection)
      .orderBy('createdAt', descending: true);

  if (filter.status != null) {
    query = query.where('status', isEqualTo: filter.status!.value);
  }

  return query.snapshots().map((snap) =>
      snap.docs.map(CandidateModel.fromFirestore).toList());
});

// ─── Candidates Notifier ──────────────────────────────────────────────────
class CandidatesNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final String _currentUserName;
  final NotificationsService _notifications;

  CandidatesNotifier({
    required FirebaseFirestore firestore,
    required String currentUserId,
    required String currentUserName,
    required NotificationsService notifications,
  })  : _firestore = firestore,
        _currentUserId = currentUserId,
        _currentUserName = currentUserName,
        _notifications = notifications,
        super(const AsyncValue.data(null));

  Future<String?> createCandidate(CandidateModel candidate) async {
    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final docRef = candidate.id.isNotEmpty
          ? _firestore
              .collection(AppConstants.candidateProfilesCollection)
              .doc(candidate.id)
          : _firestore
              .collection(AppConstants.candidateProfilesCollection)
              .doc();

      final data = CandidateModel(
        id: docRef.id,
        fullName: candidate.fullName,
        nationality: candidate.nationality,
        age: candidate.age,
        religion: candidate.religion,
        maritalStatus: candidate.maritalStatus,
        experienceYears: candidate.experienceYears,
        spokenLanguages: candidate.spokenLanguages,
        jobType: candidate.jobType,
        notes: candidate.notes,
        imageUrl: candidate.imageUrl,
        videoUrl: candidate.videoUrl,
        cvFileUrl: candidate.cvFileUrl,
        status: CandidateStatus.available,
        createdBySupervisorId: _currentUserId,
        createdBySupervisorName: _currentUserName,
        createdAt: now,
        updatedAt: now,
      ).toMap();

      await docRef.set(data);
      await _notify(
        title: 'تمت إضافة سيفي',
        body: 'تمت إضافة سيفي ${candidate.fullName}',
        type: 'candidate_created',
        targetUserId: adminNotificationTarget,
      );
      state = const AsyncValue.data(null);
      return docRef.id;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> updateCandidate(String id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(AppConstants.candidateProfilesCollection)
          .doc(id)
          .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
      await _notify(
        title: 'تم تحديث سيفي',
        body: 'تم تحديث بيانات السيفي',
        type: 'candidate_updated',
        targetUserId: adminNotificationTarget,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus(String id, CandidateStatus status) async {
    if (status == CandidateStatus.available) {
      return updateCandidate(id, {
        'status': status.value,
        'assignedEmployeeId': null,
        'assignedEmployeeName': null,
        'reservedByUserId': null,
        'reservedByUserName': null,
        'reservedAt': null,
      });
    }
    return updateCandidate(id, {'status': status.value});
  }

  Future<bool> assignToEmployee(
    String candidateId,
    String employeeId,
    String employeeName,
  ) async {
    final success = await updateCandidate(candidateId, {
      'assignedEmployeeId': employeeId,
      'assignedEmployeeName': employeeName,
      'reservedByUserId': _currentUserId,
      'reservedByUserName': _currentUserName,
      'reservedAt': FieldValue.serverTimestamp(),
      'status': CandidateStatus.reserved.value,
    });
    if (success) {
      await _notify(
        title: 'تم حجز سيفي',
        body: 'تم إسناد السيفي إلى $employeeName',
        type: 'candidate_assigned',
        targetUserId: employeeId,
      );
    }
    return success;
  }

  Future<bool> deleteCandidate(
    String id, {
    String? imageUrl,
    String? cvFileUrl,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _deleteStorageFile(imageUrl);
      await _deleteStorageFile(cvFileUrl);
      await _firestore
          .collection(AppConstants.candidateProfilesCollection)
          .doc(id)
          .delete();
      await _notify(
        title: 'تم حذف سيفي',
        body: 'تم حذف سيفي من النظام',
        type: 'candidate_deleted',
        targetUserId: adminNotificationTarget,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> _deleteStorageFile(String? url) async {
    if (url?.isNotEmpty != true) return;
    try {
      await FirebaseStorage.instance.refFromURL(url!).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
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

final candidatesNotifierProvider =
    StateNotifierProvider<CandidatesNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return CandidatesNotifier(
    firestore: ref.watch(firestoreProvider),
    currentUserId: user?.uid ?? '',
    currentUserName: user?.fullName ?? '',
    notifications: ref.watch(notificationsServiceProvider),
  );
});
