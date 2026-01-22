import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/user.dart';

/// Authentication Service
///
/// Handles:
/// - DJ/Admin authentication with Firebase Auth
/// - Guest device identification (no login required)
/// - User profile management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  static const String _deviceIdKey = 'luminique_device_id';

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  // Current user state
  User? get currentFirebaseUser => _auth.currentUser;
  bool get isLoggedIn => currentFirebaseUser != null;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password (for DJ/Admin)
  Future<AppUser?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update last login
        await _updateLastLogin(credential.user!.uid);
        return await getUser(credential.user!.uid);
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<AppUser?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user profile
        final user = AppUser(
          id: credential.user!.uid,
          email: email,
          displayName: displayName,
          role: UserRole.dj,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );

        await _usersCollection.doc(user.id).set(user.toFirestore());

        // Update display name in Firebase Auth
        if (displayName != null) {
          await credential.user!.updateDisplayName(displayName);
        }

        return user;
      }
      return null;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Get user profile
  Future<AppUser?> getUser(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Get current user profile
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = currentFirebaseUser;
    if (firebaseUser == null) return null;
    return await getUser(firebaseUser.uid);
  }

  /// Update user profile
  Future<void> updateUser(AppUser user) async {
    await _usersCollection.doc(user.id).update(user.toFirestore());
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin(String userId) async {
    await _usersCollection.doc(userId).update({
      'lastLoginAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get or create device ID for guest users
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    return deviceId;
  }

  /// Clear device ID (for testing)
  Future<void> clearDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceIdKey);
  }

  /// Record guest device visit
  Future<void> recordGuestDevice(String eventId) async {
    final deviceId = await getDeviceId();

    // Get device info (simplified)
    final deviceModel = 'Web Browser'; // In production, use device_info_plus

    final guestDevice = GuestDevice(
      deviceId: deviceId,
      deviceModel: deviceModel,
      uploadCount: 0,
      firstSeenAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );

    // Store in event's devices subcollection
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('devices')
        .doc(deviceId)
        .set(guestDevice.toMap(), SetOptions(merge: true));
  }

  /// Update guest device upload count
  Future<void> incrementGuestUploadCount(String eventId, String deviceId) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('devices')
        .doc(deviceId)
        .update({
      'uploadCount': FieldValue.increment(1),
      'lastSeenAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Check if guest has exceeded upload limit
  Future<bool> hasExceededUploadLimit(
    String eventId,
    String deviceId,
    int maxUploads,
  ) async {
    final doc = await _firestore
        .collection('events')
        .doc(eventId)
        .collection('devices')
        .doc(deviceId)
        .get();

    if (!doc.exists) return false;

    final uploadCount = doc.data()?['uploadCount'] ?? 0;
    return uploadCount >= maxUploads;
  }

  /// Get error message from FirebaseAuthException
  String getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'An error occurred.';
    }
  }
}
