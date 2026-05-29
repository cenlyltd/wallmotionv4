import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/models.dart';

class AuthService extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  User?      _firebaseUser;
  UserModel? _userModel;
  bool       _loading = true;

  bool get isLoggedIn  => _firebaseUser != null;
  bool get isLoading   => _loading;
  User? get firebaseUser => _firebaseUser;
  UserModel? get user  => _userModel;

  AuthService() {
    _auth.authStateChanges().listen((u) async {
      _firebaseUser = u;
      if (u != null) {
        await _loadUserModel(u.uid);
      } else {
        _userModel = null;
      }
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> _loadUserModel(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) _userModel = UserModel.fromDoc(doc);
  }

  // ── Register ───────────────────────────────────────────────────────────
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email, password: password,
    );
    final user = cred.user!;

    // Update display name
    await user.updateDisplayName(name);

    // Send email verification
    await user.sendEmailVerification();

    // Save to Firestore
    await _db.collection('users').doc(user.uid).set({
      'name':          name,
      'email':         email,
      'phone':         phone ?? '',
      'emailVerified': false,
      'createdAt':     FieldValue.serverTimestamp(),
    });

    await _loadUserModel(user.uid);
    notifyListeners();
  }

  // ── Login ──────────────────────────────────────────────────────────────
  Future<void> login({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    // authStateChanges listener handles the rest
  }

  // ── Logout ─────────────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
  }

  // ── Resend verification ────────────────────────────────────────────────
  Future<void> resendVerification() async {
    await _firebaseUser?.sendEmailVerification();
  }

  // ── Update profile ─────────────────────────────────────────────────────
  Future<void> updateProfile({String? name, String? phone}) async {
    if (_firebaseUser == null) return;
    final data = <String, dynamic>{};
    if (name  != null) data['name']  = name;
    if (phone != null) data['phone'] = phone;
    if (name  != null) await _firebaseUser!.updateDisplayName(name);
    await _db.collection('users').doc(_firebaseUser!.uid).update(data);
    await _loadUserModel(_firebaseUser!.uid);
    notifyListeners();
  }

  // ── Change password ────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseUser!;
    final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  // ── Reset password ─────────────────────────────────────────────────────
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
