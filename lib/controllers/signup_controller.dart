import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignUpController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 🔤 Input controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  // ⏳ Loading state
  final isLoading = false.obs;

  /// 🔐 SIGN UP + CREATE FIRESTORE USER + EMAIL VERIFICATION
  Future<void> signUp() async {
    try {
      isLoading.value = true;

      // 🧪 Basic validation
      if (fullName.text.trim().isEmpty ||
          email.text.trim().isEmpty ||
          password.text.trim().length < 6) {
        throw Exception('Please fill all fields correctly');
      }

      // 1️⃣ Create Firebase Auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = userCredential.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // 2️⃣ Create Firestore user document (🔥 THIS FIXES EVERYTHING)
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.text.trim(),
        'email': email.text.trim(),
        'phone': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3️⃣ Send email verification
      await user.sendEmailVerification();

      // 4️⃣ Navigate to verify email screen
      Get.offAllNamed('/verify-email');

      Get.snackbar(
        'Verify your email',
        'Verification link sent to ${email.text.trim()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Signup failed',
        e.message ?? 'Authentication error',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Signup failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// ✅ CHECK EMAIL VERIFICATION STATUS
  Future<void> checkEmailVerified() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;
      if (user == null) {
        Get.offAllNamed('/login');
        return;
      }

      // 🔄 Reload user from Firebase
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // ✅ Verified → allow entry
        Get.offAllNamed('/home');
      } else {
        Get.snackbar(
          'Not verified',
          'Please verify your email first',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
