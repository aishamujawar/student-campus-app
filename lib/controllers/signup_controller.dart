import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUpController extends GetxController {
  static SignUpController get instance => Get.find<SignUpController>();

  // TextField controllers
  final fullName = TextEditingController();
  final email = TextEditingController();
  final phoneNo = TextEditingController();
  final password = TextEditingController();

  final isLoading = false.obs;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Call this from your UI "Create account" button.
  /// Example:
  /// SignUpController.instance.registerUser(
  ///   SignUpController.instance.email.text.trim(),
  ///   SignUpController.instance.password.text.trim(),
  /// );
  Future<void> registerUser(String email, String password) async {
    try {
      isLoading.value = true;

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // TODO: Optionally save fullName, phoneNo, etc. to Firestore here.
      // Example (later):
      // await FirebaseFirestore.instance
      //   .collection('users')
      //   .doc(userCredential.user!.uid)
      //   .set({
      //     'fullName': fullName.text.trim(),
      //     'phoneNo': phoneNo.text.trim(),
      //     'email': email,
      //   });

      // You can show a success snackbar or let UI navigate to /home.
      Get.snackbar(
        'Success',
        'Account created successfully.',
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
    email.dispose();
    phoneNo.dispose();
    password.dispose();
    super.onClose();
  }
}