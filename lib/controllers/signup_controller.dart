import 'package:campus_app/repository/authentication_repository.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find<SignUpController>();

  // TextField controllers
  final fullName = TextEditingController();
  final uid = TextEditingController();
  final email = TextEditingController();
  final phoneNo = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -------------------------------------------
  // PHONE AUTHENTICATION TRIGGER (IMPORTANT)
  // -------------------------------------------
  void triggerPhoneAuth() {
    final phone = phoneNo.text.trim();
    if (phone.isEmpty) {
      Get.snackbar("Error", "Phone number cannot be empty.");
      return;
    }
    AuthRepository.instance.phoneAuthentication(phone);
  }

  // -------------------------------------------
  // EMAIL + PASSWORD SIGN-UP
  // -------------------------------------------
  Future<void> registerUser(String email, String password) async {
    try {
      isLoading.value = true;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔥 START PHONE OTP AFTER EMAIL SIGNUP
      triggerPhoneAuth();

      Get.snackbar(
        'Success',
        'Account created successfully. Verification code sent to phone.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Sign up failed',
        e.message ?? 'Something went wrong.',
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
    fullName.dispose();
    uid.dispose();
    email.dispose();
    phoneNo.dispose();
    password.dispose();
    super.onClose();
  }
}
