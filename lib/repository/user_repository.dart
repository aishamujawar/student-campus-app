import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class UserRepository {
  UserRepository._internal();
  static final UserRepository instance = UserRepository._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔍 Fetch current logged-in user
  /// If profile does not exist in Firestore, create it automatically
  Future<UserModel?> fetchUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;

    final docRef = _db.collection('users').doc(firebaseUser.uid);
    final doc = await docRef.get();

    /// 🆕 Auto-create profile if missing
    if (!doc.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? '',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber ?? '',
      );

      await docRef.set(newUser.toMap());
      return newUser;
    }

    return UserModel.fromSnapshot(doc);
  }

  /// 🆕 Create new user in Firestore
  Future<void> createUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toMap());
  }

  /// ✏️ Update existing user
  Future<void> updateUser(UserModel user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }
}
