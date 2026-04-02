import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance; 
  
  bool _isGoogleSignInInitialized = false;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _googleSignIn.initialize(
        serverClientId: '697931553557-304p5dirv4gm14ihl6fhb38gso704gcs.apps.googleusercontent.com', 
      );
      _isGoogleSignInInitialized = true;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, 
        idToken: googleAuth.idToken,
      );

      return await firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      debugPrint('Google Sign-In failed or cancelled: $e');
      return null;
    }
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createAccount({
    required String email,
    required String password,
  }) async {
    return await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await firebaseAuth.signOut();
    await _ensureGoogleSignInInitialized();
    await _googleSignIn.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> updateUsername({
    required String userName,
  }) async {
    await currentUser?.updateDisplayName(userName);
  }

  Future<void> deleteAccount({
    required String email,
    required String password,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    await currentUser?.reauthenticateWithCredential(credential);
    await currentUser?.delete();
    await signOut();
  }  

  Future<void> resetPasswordFromCurrentPassword({
    required String currentPassword,
    required String newPassword,
    required String email,
  }) async {
    AuthCredential credential = EmailAuthProvider.credential(email: email, password: currentPassword);
    await currentUser?.reauthenticateWithCredential(credential);
    await currentUser?.updatePassword(newPassword);
  }
}