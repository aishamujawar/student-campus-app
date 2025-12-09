import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find<LoginController>();

  final email = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call this from your UI "Sign In" button.
  /// Example:
  /// LoginController.instance.loginUser(
  ///   LoginController.instance.email.text.trim(),
  ///   LoginController.instance.password.text.trim(),
  /// );
  Future<bool> loginUser(String email, String password) async {
    try {
      isLoading.value = true;

      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      Get.snackbar(
        'Welcome back',
        'Logged in successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login failed',
        e.message ?? 'Invalid credentials.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Optional: log out from anywhere (Profile screen, etc.)
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}