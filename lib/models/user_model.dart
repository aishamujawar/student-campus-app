import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String? profilePictureUrl; // 👈 NEW: Profile picture URL

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.profilePictureUrl,
  });

  /// 🔁 App → Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      if (profilePictureUrl != null) 'profilePictureUrl': profilePictureUrl,
    };
  }

  /// 🔁 Firestore Map → App
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
    );
  }

  /// 🔁 Firestore Document → App
  factory UserModel.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return UserModel(
      uid: doc.id,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      profilePictureUrl: data['profilePictureUrl'],
    );
  }
}