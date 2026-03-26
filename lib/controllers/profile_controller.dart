import 'dart:async';

import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class ProfileController extends GetxController {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  
  late final StreamSubscription<User?> _authStateSubscription;

  final user = Rxn<UserModel>();
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _authStateSubscription = _auth.authStateChanges().listen((User? firebaseUser) {
      if (firebaseUser != null) {
        fetchUser();
      } else {
        _clearUserData();
      }
    });
  }
  
  void _clearUserData() {
    user.value = null;
    isLoading.value = false;
  }

  Future<void> fetchUser() async {
    final uid = _auth.currentUser?.uid;
    
    if (uid == null) {
      _clearUserData();
      return;
    }

    if (isLoading.value) return;

    try {
      isLoading.value = true;

      final doc = await _db.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        user.value = null;
        return;
      }

      user.value = UserModel.fromMap(doc.data()!);
    } catch (e) {
      user.value = null;
    } finally {
      if (_auth.currentUser?.uid == uid) {
        isLoading.value = false;
      }
    }
  }

  Future<void> updateProfile(UserModel updatedUser) async {
    try {
      isLoading.value = true;

      await _db
          .collection('users')
          .doc(updatedUser.uid)
          .update(updatedUser.toMap());

      user.value = updatedUser;
      Get.snackbar('Success', 'Profile updated successfully');
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile');
    } finally {
      isLoading.value = false;
    }
  }
  
  Future<void> refreshUser() async {
    await fetchUser();
  }
  
  @override
  void onClose() {
    _authStateSubscription.cancel();
    super.onClose();
  }
}