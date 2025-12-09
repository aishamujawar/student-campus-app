import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpController extends GetxController {
  static OtpController get instance => Get.find<OtpController>();

  final otp = TextEditingController();
  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// For phone auth, you usually get this from Firebase when you request OTP.
  /// Your friend can set this value when starting the verification process.
  String? verificationId;

  /// Call this from your OTP "Verify & Continue" button.
  ///
  /// Example:
  /// OtpController.instance.verifyOtp(
  ///   OtpController.instance.otp.text.trim(),
  /// );
  Future<bool> verifyOtp(String code) async {
    if (verificationId == null) {
      Get.snackbar(
        'Error',
        'No verification ID found. Please request a new OTP.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    }

    try {
      isLoading.value = true;

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: code,
      );

      await _auth.signInWithCredential(credential);

      Get.snackbar(
        'Verified',
        'OTP verified successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Verification failed',
        e.message ?? 'Invalid OTP.',
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

  @override
  void onClose() {
    otp.dispose();
    super.onClose();
  }
}