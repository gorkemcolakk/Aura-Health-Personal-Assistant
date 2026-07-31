import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../models/health_profile.dart';
import '../models/chat_session.dart';
import '../models/medication.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _tcToEmail(String tc) => '$tc@aura.com';

  // --- Auth ---
  Future<bool> registerUser(String tc, String name, String password) async {
    try {
      final email = _tcToEmail(tc);
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid ?? tc;

      await _firestore.collection('users').doc(tc).set({
        'tc': tc,
        'name': name,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      debugPrint('Firebase Register Error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String tc, String password) async {
    try {
      final email = _tcToEmail(tc);
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc = await _firestore.collection('users').doc(tc).get();
      if (doc.exists) {
        return doc.data();
      } else {
        return {'tc': tc, 'name': 'Kullanıcı'};
      }
    } catch (e) {
      debugPrint('Firebase Login Error: $e');
      return null;
    }
  }

  Future<bool> updatePassword(String tc, String oldPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Re-authenticate
      final email = _tcToEmail(tc);
      final cred = EmailAuthProvider.credential(email: email, password: oldPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      return true;
    } catch (e) {
      debugPrint('Firebase Update Password Error: $e');
      return false;
    }
  }

  Future<int> resetPasswordWithBirthDate(String tc, String birthDate, String newPassword) async {
    try {
      final userDoc = await _firestore.collection('users').doc(tc).get();
      if (!userDoc.exists) return -1; // User not found

      final profileDoc = await _firestore.collection('profiles').doc(tc).get();
      if (!profileDoc.exists) return -2;

      final dataStr = profileDoc.data()?['data'] as String?;
      if (dataStr == null) return -2;

      final profile = HealthProfile.fromJson(dataStr);
      if (profile.birthDate != birthDate) {
        return -2; // Birthdate mismatch
      }

      // Password reset via email or admin SDK is standard, but for custom reset:
      // Note: Firebase Auth password reset is typically done via sendPasswordResetEmail.
      return 1;
    } catch (e) {
      debugPrint('Firebase Reset Password Error: $e');
      return -2;
    }
  }

  Future<void> deleteUser(String tc) async {
    try {
      await _firestore.collection('users').doc(tc).delete();
      await _firestore.collection('profiles').doc(tc).delete();
      await _firestore.collection('medications').doc(tc).delete();
      
      final chatSnap = await _firestore.collection('chat_sessions').doc(tc).collection('sessions').get();
      for (final doc in chatSnap.docs) {
        await doc.reference.delete();
      }
      await _firestore.collection('chat_sessions').doc(tc).delete();

      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
    } catch (e) {
      debugPrint('Firebase Delete User Error: $e');
    }
  }

  Future<Map<String, dynamic>?> getUser(String tc) async {
    try {
      final doc = await _firestore.collection('users').doc(tc).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasAnyUsers() async {
    try {
      final snap = await _firestore.collection('users').limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // --- Profile ---
  Future<HealthProfile> loadProfile(String tc) async {
    try {
      final doc = await _firestore.collection('profiles').doc(tc).get();
      if (!doc.exists || doc.data()?['data'] == null) {
        final userDoc = await getUser(tc);
        final name = userDoc?['name'] as String? ?? '';
        return HealthProfile.initial(name: name);
      }
      final dataStr = doc.data()!['data'] as String;
      return HealthProfile.fromJson(dataStr);
    } catch (e) {
      debugPrint('Firebase Load Profile Error: $e');
      return HealthProfile.initial(name: '');
    }
  }

  Future<void> saveProfile(String tc, HealthProfile profile) async {
    try {
      await _firestore.collection('profiles').doc(tc).set({
        'tc': tc,
        'data': profile.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firebase Save Profile Error: $e');
    }
  }

  // --- Medications ---
  Future<List<Medication>> loadMedications(String tc) async {
    try {
      final doc = await _firestore.collection('medications').doc(tc).get();
      if (!doc.exists || doc.data()?['items'] == null) {
        return [];
      }
      final items = doc.data()!['items'] as List<dynamic>;
      return items
          .map((item) => Medication.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (e) {
      debugPrint('Firebase Load Meds Error: $e');
      return [];
    }
  }

  Future<void> saveMedications(String tc, List<Medication> medications) async {
    try {
      final items = medications.map((m) => m.toMap()).toList();
      await _firestore.collection('medications').doc(tc).set({
        'tc': tc,
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firebase Save Meds Error: $e');
    }
  }

  // --- Chat Sessions ---
  Future<List<ChatSession>> loadChatSessions(String tc) async {
    try {
      final snap = await _firestore
          .collection('chat_sessions')
          .doc(tc)
          .collection('sessions')
          .get();

      if (snap.docs.isEmpty) return [];

      final sessions = snap.docs
          .map((doc) => ChatSession.fromJson(doc.data()['data'] as String))
          .toList();

      sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return sessions;
    } catch (e) {
      debugPrint('Firebase Load Chat Error: $e');
      return [];
    }
  }

  Future<void> saveChatSession(String tc, ChatSession session) async {
    try {
      await _firestore
          .collection('chat_sessions')
          .doc(tc)
          .collection('sessions')
          .doc(session.id)
          .set({
        'id': session.id,
        'data': session.toJson(),
        'updatedAt': session.updatedAt,
      });
    } catch (e) {
      debugPrint('Firebase Save Chat Error: $e');
    }
  }

  Future<void> deleteChatSession(String tc, String sessionId) async {
    try {
      await _firestore
          .collection('chat_sessions')
          .doc(tc)
          .collection('sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      debugPrint('Firebase Delete Chat Error: $e');
    }
  }
}
