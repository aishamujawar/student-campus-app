import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../controllers/otp_controller.dart';

class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find<AuthRepository>();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📲 SEND OTP
  Future<void> phoneAuthentication(String phoneNo) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNo,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verification (rare on emulator)
        await _auth.signInWithCredential(credential);
        Get.offAllNamed('/home');
      },
      verificationFailed: (FirebaseAuthException e) {
        Get.snackbar(
          'Verification failed',
          e.message ?? 'Something went wrong',
        );
      },
      codeSent: (String verificationId, int? resendToken) {
        // 🔑 Save verification ID
        OtpController.instance.verificationId = verificationId;

        // ➡️ Go to OTP screen
        Get.toNamed('/otp');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        OtpController.instance.verificationId = verificationId;
      },
    );
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}
