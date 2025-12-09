import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordController extends GetxController {
  static ForgotPasswordController get instance =>
      Get.find<ForgotPasswordController>();

  final email = TextEditingController();
  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call this from your "Send OTP" / "Reset Password" button
  /// for email-based reset.
  ///
  /// Example:
  /// ForgotPasswordController.instance.resetPassword(
  ///   ForgotPasswordController.instance.email.text.trim(),
  /// );
  Future<void> resetPassword(String email) async {
    try {
      isLoading.value = true;

      await _auth.sendPasswordResetEmail(email: email);

      Get.snackbar(
        'Email sent',
        'Password reset link has been sent to $email',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Reset failed',
        e.message ?? 'Unable to send reset email.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Unexpected error occurred.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}