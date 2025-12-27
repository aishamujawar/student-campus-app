import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:student_campus_app/repository/authentication_repository.dart';
import 'package:student_campus_app/repository/user_repository.dart';
import 'package:student_campus_app/models/user_model.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find<SignUpController>();

  // -----------------------------
  // TEXT CONTROLLERS
  // -----------------------------
  final fullName = TextEditingController();
  final email = TextEditingController();
  final phoneNo = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // -----------------------------
  // PHONE AUTH TRIGGER
  // -----------------------------
  void triggerPhoneAuth() {
    final phone = phoneNo.text.trim();

    if (phone.isEmpty) {
      Get.snackbar("Error", "Phone number cannot be empty");
      return;
    }

    AuthRepository.instance.phoneAuthentication(phone);
  }

  // -----------------------------
  // EMAIL + PASSWORD SIGNUP
  // -----------------------------
  Future<void> registerUser(String email, String password) async {
    try {
      isLoading.value = true;

      // 🔐 Create Firebase Auth user
      final UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      // 🧾 Create user model
      final user = UserModel(
        uid: uid,
        fullName: fullName.text.trim(),
        email: email,
        phone: phoneNo.text.trim(),
      );

      // ☁️ Save user to Firestore
      await UserRepository.instance.createUser(user);

      // 📲 Trigger phone OTP
      triggerPhoneAuth();

      Get.snackbar(
        "Success",
        "Account created successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        "Signup failed",
        e.message ?? "Something went wrong",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Unexpected error occurred",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // -----------------------------
  // CLEANUP
  // -----------------------------
  @override
  void onClose() {
    fullName.dispose();
    email.dispose();
    phoneNo.dispose();
    password.dispose();
    super.onClose();
  }
}
