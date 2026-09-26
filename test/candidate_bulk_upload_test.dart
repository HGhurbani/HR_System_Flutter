import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/auth/domain/entities/user_role.dart';
import 'package:hr_sys/features/candidates/application/candidates_providers.dart';
import 'package:hr_sys/l10n/app_localizations_ar.dart';
import 'package:hr_sys/l10n/app_localizations_en.dart';

void main() {
  group('Bulk candidate creation', () {
    test('reports successful and failed candidates independently', () {
      const result = CandidateCreationResult(
        createdIds: {'created-1', 'created-2'},
        failedIds: {'failed-1'},
      );

      expect(result.createdCount, 2);
      expect(result.failedCount, 1);
      expect(result.isSuccessful, isFalse);
    });

    test('provides localized sequential default names', () {
      expect(AppLocalizationsAr().defaultCvName(1), 'سيفي 1');
      expect(AppLocalizationsEn().defaultCvName(2), 'CV 2');
    });
  });

  group('Candidate deletion role access', () {
    test('allows supervisors and administrators but not employees', () {
      expect(UserRole.admin.canManageCandidates, isTrue);
      expect(UserRole.supervisor.canManageCandidates, isTrue);
      expect(UserRole.employee.canManageCandidates, isFalse);
    });
  });
}
