import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


ValueNotifier<AuthService> authService = ValueNotifier(AuthService());


class AuthService {
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => firebaseAuth.authStateChanges();


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