import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OtpController extends GetxController {
  static OtpController get instance => Get.find<OtpController>();

  final otp = TextEditingController();
  final isLoading = false.obs;

  late String verificationId;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ✅ VERIFY OTP
  Future<void> verifyOtp() async {
    if (otp.text.trim().length != 6) {
      Get.snackbar('Error', 'Enter valid 6-digit OTP');
      return;
    }

    try {
      isLoading.value = true;

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp.text.trim(),
      );

      await _auth.signInWithCredential(credential);

      // ✅ SUCCESS
      Get.offAllNamed('/home');
    } catch (e) {
      Get.snackbar('Error', 'Invalid OTP');
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
