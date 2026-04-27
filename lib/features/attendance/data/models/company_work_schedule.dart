import 'attendance_model.dart';

class WorkDayOverride {
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

  const WorkDayOverride({
    required this.morningHour,
    required this.morningMinute,
    required this.morningEndHour,
    required this.morningEndMinute,
    required this.eveningHour,
    required this.eveningMinute,
    required this.eveningEndHour,
    required this.eveningEndMinute,
    required this.morningGraceMinutes,
    required this.eveningGraceMinutes,
  });

  factory WorkDayOverride.fromMap(
    Map<String, dynamic> data, {
    required WorkDayOverride fallback,
  }) {
    int h(String key, int fb) {
      final v = (data[key] as num?)?.toInt();
      if (v == null || v < 0 || v > 23) return fb;
      return v;
    }

    int m(String key, int fb) {
      final v = (data[key] as num?)?.toInt();
      if (v == null || v < 0 || v > 59) return fb;
      return v;
    }

    int g(String key, int fb) {
      final v = (data[key] as num?)?.toInt();
      if (v == null || v < 0) return fb;
      return v;
    }

    return WorkDayOverride(
      morningHour: h('morningHour', fallback.morningHour),
      morningMinute: m('morningMinute', fallback.morningMinute),
      morningEndHour: h('morningEndHour', fallback.morningEndHour),
      morningEndMinute: m('morningEndMinute', fallback.morningEndMinute),
      eveningHour: h('eveningHour', fallback.eveningHour),
      eveningMinute: m('eveningMinute', fallback.eveningMinute),
      eveningEndHour: h('eveningEndHour', fallback.eveningEndHour),
      eveningEndMinute: m('eveningEndMinute', fallback.eveningEndMinute),
      morningGraceMinutes: g('morningGraceMinutes', fallback.morningGraceMinutes),
      eveningGraceMinutes: g('eveningGraceMinutes', fallback.eveningGraceMinutes),
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
}

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
  /// Per-weekday overrides keyed by `DateTime.monday ... DateTime.sunday`.
  final Map<int, WorkDayOverride> dayOverrides;

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
    this.dayOverrides = const {},
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

    final base = CompanyWorkSchedule(
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

    final rawOverrides = data['dayOverrides'];
    final overrides = <int, WorkDayOverride>{};
    if (rawOverrides is Map) {
      final fallback = WorkDayOverride(
        morningHour: base.morningHour,
        morningMinute: base.morningMinute,
        morningEndHour: base.morningEndHour,
        morningEndMinute: base.morningEndMinute,
        eveningHour: base.eveningHour,
        eveningMinute: base.eveningMinute,
        eveningEndHour: base.eveningEndHour,
        eveningEndMinute: base.eveningEndMinute,
        morningGraceMinutes: base.morningGraceMinutes,
        eveningGraceMinutes: base.eveningGraceMinutes,
      );

      for (final entry in rawOverrides.entries) {
        final key = int.tryParse(entry.key.toString());
        final value = entry.value;
        if (key == null ||
            key < DateTime.monday ||
            key > DateTime.sunday ||
            value is! Map) {
          continue;
        }
        overrides[key] = WorkDayOverride.fromMap(
          Map<String, dynamic>.from(value),
          fallback: fallback,
        );
      }
    }

    return CompanyWorkSchedule(
      morningHour: base.morningHour,
      morningMinute: base.morningMinute,
      morningEndHour: base.morningEndHour,
      morningEndMinute: base.morningEndMinute,
      eveningHour: base.eveningHour,
      eveningMinute: base.eveningMinute,
      eveningEndHour: base.eveningEndHour,
      eveningEndMinute: base.eveningEndMinute,
      morningGraceMinutes: base.morningGraceMinutes,
      eveningGraceMinutes: base.eveningGraceMinutes,
      dayOverrides: Map.unmodifiable(overrides),
    );
  }

  Map<String, dynamic> toMap() {
    final overrides = <String, dynamic>{};
    dayOverrides.forEach((weekday, o) {
      overrides[weekday.toString()] = o.toMap();
    });
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
      'dayOverrides': overrides,
    };
  }

  DateTime shiftStartOnDay(DateTime day, ShiftType shiftType) {
    final o = dayOverrides[day.weekday];
    if (shiftType == ShiftType.morning) {
      return DateTime(
        day.year,
        day.month,
        day.day,
        o?.morningHour ?? morningHour,
        o?.morningMinute ?? morningMinute,
      );
    }
    return DateTime(
      day.year,
      day.month,
      day.day,
      o?.eveningHour ?? eveningHour,
      o?.eveningMinute ?? eveningMinute,
    );
  }

  DateTime shiftEndOnDay(DateTime day, ShiftType shiftType) {
    final o = dayOverrides[day.weekday];
    if (shiftType == ShiftType.morning) {
      return DateTime(
        day.year,
        day.month,
        day.day,
        o?.morningEndHour ?? morningEndHour,
        o?.morningEndMinute ?? morningEndMinute,
      );
    }
    return DateTime(
      day.year,
      day.month,
      day.day,
      o?.eveningEndHour ?? eveningEndHour,
      o?.eveningEndMinute ?? eveningEndMinute,
    );
  }

  int graceMinutesFor(ShiftType shiftType, {DateTime? day}) {
    final o = day == null ? null : dayOverrides[day.weekday];
    if (shiftType == ShiftType.morning) {
      return o?.morningGraceMinutes ?? morningGraceMinutes;
    }
    return o?.eveningGraceMinutes ?? eveningGraceMinutes;
  }
}
