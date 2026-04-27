import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../auth/application/auth_providers.dart';
import '../data/models/company_holiday_model.dart';

final companyHolidaysProvider =
    StreamProvider<List<CompanyHolidayModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.companyHolidaysCollection)
      .orderBy('date', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map(CompanyHolidayModel.fromFirestore).toList());
});

final companyHolidaysInRangeProvider = StreamProvider.family
    <List<CompanyHolidayModel>, ({DateTime start, DateTime end})>((ref, range) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(AppConstants.companyHolidaysCollection)
      .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
      .where('date', isLessThan: Timestamp.fromDate(range.end))
      .orderBy('date', descending: false)
      .snapshots()
      .map((snap) =>
          snap.docs.map(CompanyHolidayModel.fromFirestore).toList());
});

