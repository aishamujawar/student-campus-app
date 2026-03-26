import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:student_campus_app/controllers/main_shell_controller.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find<LoginController>();

  final email = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call this from your UI "Sign In" button.
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
      
      // Clear fields after successful login
      _clearFields();
      
      // Reset MainShellController to home tab before navigating
      if (Get.isRegistered<MainShellController>()) {
        final mainShellController = Get.find<MainShellController>();
        mainShellController.selectedIndex.value = 0;
      }
      
      // Small delay to ensure everything is ready
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Navigate to home after successful login
      Get.offAllNamed('/home');
      
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

  void _clearFields() {
    email.clear();
    password.clear();
  }

  /// Logout function
  Future<void> logout() async {
    await _auth.signOut();
    _clearFields();
    Get.offAllNamed('/welcome');
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}