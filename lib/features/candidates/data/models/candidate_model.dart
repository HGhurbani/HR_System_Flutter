import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/candidate_status.dart';

class CandidateModel {
  final String id;
  final String fullName;
  final CandidateNationality nationality;
  final int age;
  final String? religion;
  final String? maritalStatus;
  final int experienceYears;
  final List<String> spokenLanguages;
  final String? jobType;
  final String? notes;
  final String? imageUrl;
  final String? videoUrl;
  final String? cvFileUrl;
  final CandidateStatus status;
  final String? assignedEmployeeId;
  final String? assignedEmployeeName;
  final String? convertedEmployeeId;
  final DateTime? convertedAt;
  final String? convertedByAdminId;
  final String createdBySupervisorId;
  final String? createdBySupervisorName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CandidateModel({
    required this.id,
    required this.fullName,
    required this.nationality,
    required this.age,
    this.religion,
    this.maritalStatus,
    required this.experienceYears,
    required this.spokenLanguages,
    this.jobType,
    this.notes,
    this.imageUrl,
    this.videoUrl,
    this.cvFileUrl,
    required this.status,
    this.assignedEmployeeId,
    this.assignedEmployeeName,
    this.convertedEmployeeId,
    this.convertedAt,
    this.convertedByAdminId,
    required this.createdBySupervisorId,
    this.createdBySupervisorName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CandidateModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final assignedEmployeeId = data['assignedEmployeeId'] as String?;
    final assignedEmployeeName = data['assignedEmployeeName'] as String?;
    final rawStatus = data['status'] as String? ?? 'available';
    final parsedStatus = CandidateStatus.fromString(rawStatus);
    // If it's assigned to an employee, treat it as reserved even if legacy status says otherwise.
    final normalizedStatus =
        assignedEmployeeId != null ? CandidateStatus.reserved : parsedStatus;
    return CandidateModel(
      id: doc.id,
      fullName: data['fullName'] as String? ?? '',
      nationality: CandidateNationality.fromString(
          data['nationality'] as String? ?? 'philippines'),
      age: (data['age'] as num?)?.toInt() ?? 0,
      religion: data['religion'] as String?,
      maritalStatus: data['maritalStatus'] as String?,
      experienceYears: (data['experienceYears'] as num?)?.toInt() ?? 0,
      spokenLanguages: List<String>.from(data['spokenLanguages'] ?? []),
      jobType: data['jobType'] as String?,
      notes: data['notes'] as String?,
      imageUrl: data['imageUrl'] as String?,
      videoUrl: data['videoUrl'] as String?,
      cvFileUrl: data['cvFileUrl'] as String?,
      status: normalizedStatus,
      assignedEmployeeId: assignedEmployeeId,
      assignedEmployeeName: assignedEmployeeName,
      convertedEmployeeId: data['convertedEmployeeId'] as String?,
      convertedAt: data['convertedAt'] != null
          ? (data['convertedAt'] as Timestamp).toDate()
          : null,
      convertedByAdminId: data['convertedByAdminId'] as String?,
      createdBySupervisorId:
          data['createdBySupervisorId'] as String? ?? '',
      createdBySupervisorName:
          data['createdBySupervisorName'] as String?,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// No age/experience/job/languages filled — profile is image + name only.
  bool get isImageOnlyProfile =>
      age <= 0 &&
      experienceYears <= 0 &&
      (jobType == null || jobType!.trim().isEmpty) &&
      spokenLanguages.isEmpty;

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'nationality': nationality.value,
      'age': age,
      'religion': religion,
      'maritalStatus': maritalStatus,
      'experienceYears': experienceYears,
      'spokenLanguages': spokenLanguages,
      'jobType': jobType,
      'notes': notes,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'cvFileUrl': cvFileUrl,
      'status': status.value,
      'assignedEmployeeId': assignedEmployeeId,
      'assignedEmployeeName': assignedEmployeeName,
      'convertedEmployeeId': convertedEmployeeId,
      'convertedAt':
          convertedAt != null ? Timestamp.fromDate(convertedAt!) : null,
      'convertedByAdminId': convertedByAdminId,
      'createdBySupervisorId': createdBySupervisorId,
      'createdBySupervisorName': createdBySupervisorName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  CandidateModel copyWith({
    String? fullName,
    CandidateNationality? nationality,
    int? age,
    String? religion,
    String? maritalStatus,
    int? experienceYears,
    List<String>? spokenLanguages,
    String? jobType,
    String? notes,
    String? imageUrl,
    String? videoUrl,
    String? cvFileUrl,
    CandidateStatus? status,
    String? assignedEmployeeId,
    String? assignedEmployeeName,
    String? convertedEmployeeId,
    DateTime? convertedAt,
    String? convertedByAdminId,
    DateTime? updatedAt,
  }) {
    return CandidateModel(
      id: id,
      fullName: fullName ?? this.fullName,
      nationality: nationality ?? this.nationality,
      age: age ?? this.age,
      religion: religion ?? this.religion,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      experienceYears: experienceYears ?? this.experienceYears,
      spokenLanguages: spokenLanguages ?? this.spokenLanguages,
      jobType: jobType ?? this.jobType,
      notes: notes ?? this.notes,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      cvFileUrl: cvFileUrl ?? this.cvFileUrl,
      status: status ?? this.status,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      assignedEmployeeName:
          assignedEmployeeName ?? this.assignedEmployeeName,
      convertedEmployeeId:
          convertedEmployeeId ?? this.convertedEmployeeId,
      convertedAt: convertedAt ?? this.convertedAt,
      convertedByAdminId:
          convertedByAdminId ?? this.convertedByAdminId,
      createdBySupervisorId: createdBySupervisorId,
      createdBySupervisorName: createdBySupervisorName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
