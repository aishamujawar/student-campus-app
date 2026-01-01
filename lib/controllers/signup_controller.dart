import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final fullName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;

  /// 🔐 SIGN UP + SEND EMAIL VERIFICATION
  Future<void> signUp() async {
    try {
      isLoading.value = true;

      // 1️⃣ Create user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );

      final user = userCredential.user;

      // 🚨 SAFETY CHECK (prevents "unexpected null value")
      if (user == null) {
        throw Exception('User creation failed');
      }

      // 2️⃣ Send verification email
      await user.sendEmailVerification();

      // 3️⃣ Navigate to Verify Email screen
      Get.offAllNamed('/verify-email');

      // 4️⃣ Notify user
      Get.snackbar(
        'Verify your email',
        'A verification link has been sent to ${email.text.trim()}',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Signup failed',
        e.message ?? 'Something went wrong',
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

  /// ✅ CHECK IF EMAIL IS VERIFIED
  Future<void> checkEmailVerified() async {
    try {
      isLoading.value = true;

      final user = _auth.currentUser;

      if (user == null) {
        Get.offAllNamed('/login');
        return;
      }

      // 🔄 Refresh user data from Firebase
      await user.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        // ✅ Email verified → enter app
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
