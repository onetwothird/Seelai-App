import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

ValueNotifier<AuthService> authService = ValueNotifier(AuthService());

class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  
  // FIX 1: Use the singleton instance instead of the constructor
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance; 
  
  // FIX 2: Track initialization state
  bool _isGoogleSignInInitialized = false;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();

  // Helper to ensure Google Sign-In is initialized exactly once
  Future<void> _ensureGoogleSignInInitialized() async {
    if (!_isGoogleSignInInitialized) {
      await _googleSignIn.initialize();
      _isGoogleSignInInitialized = true;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      // FIX 3: Use authenticate() instead of signIn()
      // Note: This method throws an exception if the user cancels, it does not return null.
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // FIX 4: Retrieve tokens correctly. 
      // 'accessToken' is removed from googleAuth. We can usually rely on idToken for Firebase.
      // If you specifically need the accessToken, you now get it via authorizationClient.
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: null, // Usually not needed if idToken is present for Firebase
        idToken: googleAuth.idToken,
      );

      return await firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      // FIX 5: Catch cancellation or errors explicitly since authenticate() throws
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