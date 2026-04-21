import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../data/models/candidate_model.dart';
import '../domain/entities/candidate_status.dart';

// ─── Filter State ─────────────────────────────────────────────────────────
class CandidateFilter {
  final CandidateNationality? nationality;
  final CandidateStatus? status;
  final String? assignedEmployeeId;
  final String searchQuery;

  const CandidateFilter({
    this.nationality,
    this.status,
    this.assignedEmployeeId,
    this.searchQuery = '',
  });

  CandidateFilter copyWith({
    CandidateNationality? nationality,
    CandidateStatus? status,
    String? assignedEmployeeId,
    String? searchQuery,
    bool clearNationality = false,
    bool clearStatus = false,
    bool clearEmployee = false,
  }) {
    return CandidateFilter(
      nationality: clearNationality ? null : (nationality ?? this.nationality),
      status: clearStatus ? null : (status ?? this.status),
      assignedEmployeeId: clearEmployee
          ? null
          : (assignedEmployeeId ?? this.assignedEmployeeId),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      nationality != null || status != null || assignedEmployeeId != null;
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

  if (filter.nationality != null) {
    query = query.where('nationality',
        isEqualTo: filter.nationality!.value);
  }
  if (filter.status != null) {
    query = query.where('status', isEqualTo: filter.status!.value);
  }
  if (filter.assignedEmployeeId != null) {
    query = query.where('assignedEmployeeId',
        isEqualTo: filter.assignedEmployeeId);
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

  if (filter.nationality != null) {
    query = query.where('nationality', isEqualTo: filter.nationality!.value);
  }
  if (filter.status != null) {
    query = query.where('status', isEqualTo: filter.status!.value);
  }
  if (filter.assignedEmployeeId != null) {
    query = query.where('assignedEmployeeId', isEqualTo: filter.assignedEmployeeId);
  }

  return query.snapshots().map((snap) =>
      snap.docs.map(CandidateModel.fromFirestore).toList());
});

// ─── Candidates Notifier ──────────────────────────────────────────────────
class CandidatesNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseFirestore _firestore;
  final String _currentUserId;
  final String _currentUserName;

  CandidatesNotifier({
    required FirebaseFirestore firestore,
    required String currentUserId,
    required String currentUserName,
  })  : _firestore = firestore,
        _currentUserId = currentUserId,
        _currentUserName = currentUserName,
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
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateStatus(String id, CandidateStatus status) async {
    return updateCandidate(id, {'status': status.value});
  }

  Future<bool> assignToEmployee(
    String candidateId,
    String employeeId,
    String employeeName,
  ) async {
    return updateCandidate(candidateId, {
      'assignedEmployeeId': employeeId,
      'assignedEmployeeName': employeeName,
      'status': CandidateStatus.reserved.value,
    });
  }

  Future<bool> deleteCandidate(String id) async {
    state = const AsyncValue.loading();
    try {
      await _firestore
          .collection(AppConstants.candidateProfilesCollection)
          .doc(id)
          .delete();
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final candidatesNotifierProvider =
    StateNotifierProvider<CandidatesNotifier, AsyncValue<void>>((ref) {
  final user = ref.watch(currentUserProvider);
  return CandidatesNotifier(
    firestore: ref.watch(firestoreProvider),
    currentUserId: user?.uid ?? '',
    currentUserName: user?.fullName ?? '',
  );
});
