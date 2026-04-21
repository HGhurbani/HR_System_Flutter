class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException({
    required this.message,
    this.code,
    this.originalError,
  });

  factory AppException.auth(String code) {
    return AppException(
      message: _authMessage(code),
      code: code,
    );
  }

  factory AppException.network() {
    return const AppException(
      message: 'Network connection error',
      code: 'network-error',
    );
  }

  factory AppException.permissionDenied() {
    return const AppException(
      message: 'Permission denied',
      code: 'permission-denied',
    );
  }

  factory AppException.notFound() {
    return const AppException(
      message: 'Data not found',
      code: 'not-found',
    );
  }

  factory AppException.unknown(dynamic error) {
    return AppException(
      message: 'An unexpected error occurred',
      code: 'unknown',
      originalError: error,
    );
  }

  static String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password';
      case 'user-disabled':
        return 'Account is disabled';
      case 'too-many-requests':
        return 'Too many attempts, try again later';
      case 'invalid-email':
        return 'Invalid email address';
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'network-request-failed':
        return 'Network connection error';
      default:
        return 'Authentication failed';
    }
  }

  @override
  String toString() => 'AppException(code: $code, message: $message)';
}
