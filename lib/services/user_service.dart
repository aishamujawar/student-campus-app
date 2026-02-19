import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  static final _db = FirebaseFirestore.instance;

  static Future<Map<String, String>> getUserNames(
    List<String> userIds,
  ) async {
    final Map<String, String> result = {};

    for (final uid in userIds) {
      final doc = await _db.collection('users').doc(uid).get();

      final fullName = doc.data()?['fullName'] as String?;
      final firstName = fullName?.trim().split(' ').first;

      result[uid] = firstName ?? 'User';
    }

    return result;
  }

  // NEW METHOD: Get current user's first name for chatbot
  static Future<String> getCurrentUserFirstName() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'there';

    final doc = await _db.collection('users').doc(uid).get();
    final fullName = doc.data()?['fullName'] as String?;

    if (fullName == null || fullName.trim().isEmpty) {
      return 'there';
    }

    return fullName.trim().split(' ').first;
  }
}