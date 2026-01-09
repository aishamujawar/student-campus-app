import 'package:cloud_firestore/cloud_firestore.dart';

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
}
