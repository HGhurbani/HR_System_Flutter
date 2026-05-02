import '../entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;
  Future<AppUser?> get currentUser;
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  });
  Future<void> signOut();
  Future<AppUser?> getUserById(String uid);
}
