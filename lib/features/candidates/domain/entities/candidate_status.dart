/// CV workflow: **متاح** (available) ↔ **محجوز** (reserved) only.
/// Legacy Firestore values (`new`, `in_progress`, `hired`, …) map into these two.
enum CandidateStatus {
  available,
  reserved;

  static CandidateStatus fromString(String value) {
    switch (value) {
      case 'reserved':
        return CandidateStatus.reserved;
      case 'available':
        return CandidateStatus.available;
      default:
        return CandidateStatus.available;
    }
  }

  String get value {
    switch (this) {
      case CandidateStatus.available:
        return 'available';
      case CandidateStatus.reserved:
        return 'reserved';
    }
  }
}

enum CandidateNationality {
  philippines,
  kenya,
  uganda,
  ethiopia,
  bangladesh;

  static CandidateNationality fromString(String value) {
    switch (value.toLowerCase()) {
      case 'kenya':
        return CandidateNationality.kenya;
      case 'uganda':
        return CandidateNationality.uganda;
      case 'ethiopia':
        return CandidateNationality.ethiopia;
      case 'bangladesh':
        return CandidateNationality.bangladesh;
      default:
        return CandidateNationality.philippines;
    }
  }

  String get value => name;
}
