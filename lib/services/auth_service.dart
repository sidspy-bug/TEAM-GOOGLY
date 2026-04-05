import 'package:firebase_auth/firebase_auth.dart';

/// Centralized Firebase authentication service.
/// Wraps FirebaseAuth for login, signup, Google, Facebook, and logout.
class AuthService {
  static AuthService? _instance;
  factory AuthService() => _instance ??= AuthService._();
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Current Firebase user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Create a new account with email and password.
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign in with Google (web popup).
  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    provider.addScope('email');
    provider.addScope('profile');
    return await _auth.signInWithPopup(provider);
  }

  /// Sign in with Facebook (web popup).
  Future<UserCredential> signInWithFacebook() async {
    final provider = FacebookAuthProvider();
    provider.addScope('email');
    provider.addScope('public_profile');
    return await _auth.signInWithPopup(provider);
  }

  /// Send email verification to the current user.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Reload the current user (to refresh emailVerified flag).
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Get the current ID token for API calls.
  Future<String?> getIdToken() async {
    return await _auth.currentUser?.getIdToken();
  }
}
