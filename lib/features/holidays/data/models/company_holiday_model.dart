import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyHolidayModel {
  final String id;
  final DateTime date;
  final String name;
  final bool isPaid;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CompanyHolidayModel({
    required this.id,
    required this.date,
    required this.name,
    this.isPaid = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompanyHolidayModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    final dateTs = data['date'] as Timestamp?;
    final createdTs = data['createdAt'] as Timestamp?;
    final updatedTs = data['updatedAt'] as Timestamp?;

    return CompanyHolidayModel(
      id: doc.id,
      date: dateTs?.toDate() ?? DateTime.now(),
      name: data['name'] as String? ?? '',
      isPaid: data['isPaid'] as bool? ?? true,
      createdAt: createdTs?.toDate() ?? DateTime.now(),
      updatedAt: updatedTs?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'name': name.trim(),
      'isPaid': isPaid,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static String dayKey(DateTime day) =>
      '${day.year.toString().padLeft(4, '0')}-'
      '${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';
}

