import 'package:cloud_firestore/cloud_firestore.dart';

class AttendancePolicyModel {
  static const double defaultThresholdPercent = 98;
  static const List<int> defaultWeeklyRestDays = [DateTime.friday];

  final List<int> weeklyRestDays;
  final double attendanceThresholdPercent;
  final bool lateCountsAsPresent;

  const AttendancePolicyModel({
    this.weeklyRestDays = defaultWeeklyRestDays,
    this.attendanceThresholdPercent = defaultThresholdPercent,
    this.lateCountsAsPresent = true,
  });

  factory AttendancePolicyModel.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const AttendancePolicyModel();
    final rawRestDays = data['weeklyRestDays'];
    final restDays = rawRestDays is Iterable
        ? rawRestDays
            .whereType<num>()
            .map((day) => day.toInt())
            .where((day) => day >= DateTime.monday && day <= DateTime.sunday)
            .toSet()
            .toList()
        : defaultWeeklyRestDays;

    return AttendancePolicyModel(
      weeklyRestDays:
          restDays.isEmpty ? defaultWeeklyRestDays : List.unmodifiable(restDays),
      attendanceThresholdPercent:
          (data['attendanceThresholdPercent'] as num?)?.toDouble() ??
              defaultThresholdPercent,
      lateCountsAsPresent: data['lateCountsAsPresent'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklyRestDays': weeklyRestDays,
      'attendanceThresholdPercent': attendanceThresholdPercent,
      'lateCountsAsPresent': lateCountsAsPresent,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AttendancePolicyModel copyWith({
    List<int>? weeklyRestDays,
    double? attendanceThresholdPercent,
    bool? lateCountsAsPresent,
  }) {
    return AttendancePolicyModel(
      weeklyRestDays: weeklyRestDays ?? this.weeklyRestDays,
      attendanceThresholdPercent:
          attendanceThresholdPercent ?? this.attendanceThresholdPercent,
      lateCountsAsPresent: lateCountsAsPresent ?? this.lateCountsAsPresent,
    );
  }
}
