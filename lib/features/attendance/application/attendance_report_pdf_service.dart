import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/models/attendance_model.dart';
import '../data/models/attendance_report.dart';

class AttendanceReportPdfService {
  const AttendanceReportPdfService();

  Future<Uint8List> build({
    required AttendanceDateRange range,
    required List<AttendanceReportRow> rows,
    required bool isArabic,
  }) async {
    final fontData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
    final font = pw.Font.ttf(fontData);
    final boldFont = pw.Font.ttf(boldFontData);
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');
    final labels = _PdfLabels(isArabic);
    final document = pw.Document(theme: theme);

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(24),
          textDirection: isArabic ? pw.TextDirection.rtl : pw.TextDirection.ltr,
          theme: theme,
        ),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              labels.title,
              style: pw.TextStyle(font: boldFont, fontSize: 18),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${labels.period}: ${dateFormat.format(range.start)} '
              '${labels.to} ${dateFormat.format(range.end)}',
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 12),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
            '${labels.page} ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (_) => [
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(font: boldFont, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.center,
            headerAlignment: pw.Alignment.center,
            columnWidths: {
              0: const pw.FlexColumnWidth(2.2),
              1: const pw.FlexColumnWidth(1.2),
              2: const pw.FlexColumnWidth(1.2),
              3: const pw.FlexColumnWidth(1.1),
              4: const pw.FlexColumnWidth(1.1),
              5: const pw.FlexColumnWidth(0.9),
              6: const pw.FlexColumnWidth(1.2),
            },
            headers: [
              labels.employee,
              labels.date,
              labels.shift,
              labels.checkIn,
              labels.checkOut,
              labels.lateness,
              labels.status,
            ],
            data: rows
                .map(
                  (row) => [
                    row.employeeName,
                    dateFormat.format(row.date),
                    _shiftLabel(row.shiftType, labels),
                    row.checkInTime == null
                        ? '-'
                        : timeFormat.format(row.checkInTime!),
                    row.checkOutTime == null
                        ? '-'
                        : timeFormat.format(row.checkOutTime!),
                    row.latenessMinutes.toString(),
                    _statusLabel(row.status, labels),
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    return document.save();
  }

  String _shiftLabel(ShiftType? shift, _PdfLabels labels) {
    if (shift == null) return '-';
    return shift == ShiftType.morning ? labels.morning : labels.evening;
  }

  String _statusLabel(AttendanceStatus status, _PdfLabels labels) {
    switch (status) {
      case AttendanceStatus.absent:
        return labels.absent;
      case AttendanceStatus.late:
        return labels.late;
      case AttendanceStatus.onLeave:
        return labels.leave;
      case AttendanceStatus.holiday:
        return labels.holiday;
      case AttendanceStatus.present:
        return labels.present;
    }
  }
}

class _PdfLabels {
  final bool isArabic;

  const _PdfLabels(this.isArabic);

  String get title => isArabic ? 'تقرير الحضور والانصراف' : 'Attendance Report';
  String get period => isArabic ? 'الفترة' : 'Period';
  String get to => isArabic ? 'إلى' : 'to';
  String get employee => isArabic ? 'الموظف' : 'Employee';
  String get date => isArabic ? 'التاريخ' : 'Date';
  String get shift => isArabic ? 'الوردية' : 'Shift';
  String get checkIn => isArabic ? 'الحضور' : 'Check-in';
  String get checkOut => isArabic ? 'الانصراف' : 'Check-out';
  String get lateness => isArabic ? 'التأخير' : 'Late (min)';
  String get status => isArabic ? 'الحالة' : 'Status';
  String get morning => isArabic ? 'صباحية' : 'Morning';
  String get evening => isArabic ? 'مسائية' : 'Evening';
  String get present => isArabic ? 'حاضر' : 'Present';
  String get absent => isArabic ? 'غائب' : 'Absent';
  String get late => isArabic ? 'متأخر' : 'Late';
  String get leave => isArabic ? 'إجازة' : 'On leave';
  String get holiday => isArabic ? 'عطلة' : 'Holiday';
  String get page => isArabic ? 'صفحة' : 'Page';
}
