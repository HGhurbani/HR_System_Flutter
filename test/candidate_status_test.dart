import 'package:flutter_test/flutter_test.dart';
import 'package:hr_sys/features/candidates/domain/entities/candidate_status.dart';

void main() {
  test('only available and reserved; legacy maps to available', () {
    expect(CandidateStatus.fromString('available'), CandidateStatus.available);
    expect(CandidateStatus.fromString('reserved'), CandidateStatus.reserved);
    expect(CandidateStatus.fromString('hired'), CandidateStatus.available);
    expect(CandidateStatus.fromString('new'), CandidateStatus.available);
    expect(CandidateStatus.available.value, 'available');
    expect(CandidateStatus.reserved.value, 'reserved');
  });
}
