import 'attendance_model.dart';

/// Company-wide shift start times and grace minutes before marking late.
class CompanyWorkSchedule {
  final int morningHour;
  final int morningMinute;
  final int morningEndHour;
  final int morningEndMinute;
  final int eveningHour;
  final int eveningMinute;
  final int eveningEndHour;
  final int eveningEndMinute;
  final int morningGraceMinutes;
  final int eveningGraceMinutes;

  const CompanyWorkSchedule({
    this.morningHour = 8,
    this.morningMinute = 0,
    this.morningEndHour = 16,
    this.morningEndMinute = 0,
    this.eveningHour = 16,
    this.eveningMinute = 0,
    this.eveningEndHour = 23,
    this.eveningEndMinute = 0,
    this.morningGraceMinutes = 15,
    this.eveningGraceMinutes = 15,
  });

  factory CompanyWorkSchedule.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const CompanyWorkSchedule();
    }
    int h(String key, int fallback) {
      final v = (data[key] as num?)?.toInt();
      if (v == null || v < 0 || v > 23) return fallback;
      return v;
    }

    int m(String key, int fallback) {
      final v = (data[key] as num?)?.toInt();
      if (v == null || v < 0 || v > 59) return fallback;
      return v;
    }

    int g(String key, int fallback) {
      final v = (data[key] as num?)?.toInt();
      if (v == null || v < 0) return fallback;
      return v;
    }

    return CompanyWorkSchedule(
      morningHour: h('morningHour', 8),
      morningMinute: m('morningMinute', 0),
      morningEndHour: h('morningEndHour', 16),
      morningEndMinute: m('morningEndMinute', 0),
      eveningHour: h('eveningHour', 16),
      eveningMinute: m('eveningMinute', 0),
      eveningEndHour: h('eveningEndHour', 23),
      eveningEndMinute: m('eveningEndMinute', 0),
      morningGraceMinutes: g('morningGraceMinutes', 15),
      eveningGraceMinutes: g('eveningGraceMinutes', 15),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'morningHour': morningHour,
      'morningMinute': morningMinute,
      'morningEndHour': morningEndHour,
      'morningEndMinute': morningEndMinute,
      'eveningHour': eveningHour,
      'eveningMinute': eveningMinute,
      'eveningEndHour': eveningEndHour,
      'eveningEndMinute': eveningEndMinute,
      'morningGraceMinutes': morningGraceMinutes,
      'eveningGraceMinutes': eveningGraceMinutes,
    };
  }

  DateTime shiftStartOnDay(DateTime day, ShiftType shiftType) {
    if (shiftType == ShiftType.morning) {
      return DateTime(day.year, day.month, day.day, morningHour, morningMinute);
    }
    return DateTime(day.year, day.month, day.day, eveningHour, eveningMinute);
  }

  DateTime shiftEndOnDay(DateTime day, ShiftType shiftType) {
    if (shiftType == ShiftType.morning) {
      return DateTime(
          day.year, day.month, day.day, morningEndHour, morningEndMinute);
    }
    return DateTime(
        day.year, day.month, day.day, eveningEndHour, eveningEndMinute);
  }

  int graceMinutesFor(ShiftType shiftType) {
    return shiftType == ShiftType.morning
        ? morningGraceMinutes
        : eveningGraceMinutes;
  }
}
