import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepositoryImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      return _fetchUser(firebaseUser.uid);
    });
  }

  @override
  Future<AppUser?> get currentUser async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _fetchUser(firebaseUser.uid);
  }

  @override
  Future<AppUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = await _fetchUser(credential.user!.uid);
      if (user == null) {
        throw AppException(
          message: 'User profile not found',
          code: 'user-profile-not-found',
        );
      }

      if (!user.isActive) {
        await _auth.signOut();
        throw AppException(
          message: 'Account is disabled',
          code: 'user-disabled',
        );
      }

      return user;
    } on FirebaseAuthException catch (e) {
      throw AppException.auth(e.code);
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.unknown(e);
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException.auth(e.code);
    } catch (e) {
      throw AppException.unknown(e);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<AppUser?> getUserById(String uid) => _fetchUser(uid);

  Future<AppUser?> _fetchUser(String uid) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw AppException.unknown(e);
    }
  }

  // NOTE: Quick-login auto-provisioning has been removed.
}
