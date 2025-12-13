import 'package:campus_app/screens/auth/otp_screen.dart';
import 'package:campus_app/screens/auth/welcome_screen.dart';
import 'package:campus_app/screens/home/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../controllers/otp_controller.dart';

class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final Rx<User?> firebaseUser;

  // Store verificationId using obs
  var verificationId = ''.obs;

  @override
  void onReady() {
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());
    ever(firebaseUser, _setInitialScreen);
  }

  // SHOW EITHER LOGIN OR HOME SCREEN
  void _setInitialScreen(User? user) {
    if (user == null) {
      Get.offAll(() => const WelcomeScreen());
    } else {
      Get.offAll(
        () => HomeScreen(
          onFeatureSelected: (feature) {},
          onProfileTap: () {},
        ),
      );
    }
  }

  // ---------------------------------------------------------------------
  // PHONE AUTHENTICATION
  // ---------------------------------------------------------------------
  Future<void> phoneAuthentication(String phoneNo) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNo,

      // Auto fetch OTP on Android
      verificationCompleted: (PhoneAuthCredential credential) async {
        await _auth.signInWithCredential(credential);
      },

      verificationFailed: (FirebaseAuthException e) {
        if (e.code == 'invalid-phone-number') {
          Get.snackbar("Error", "Invalid phone number.");
        } else {
          Get.snackbar("Error", e.message ?? "Phone auth failed.");
        }
      },

      codeSent: (String verificationId, int? resendToken) {
        this.verificationId.value = verificationId;

        // PASS verification id to OtpController
        final otpController = Get.put(OtpController());
        otpController.verificationId = verificationId;

        // MOVE to OTP screen
        Get.to(() => const OtpScreen());
      },

      codeAutoRetrievalTimeout: (String verificationId) {
        this.verificationId.value = verificationId;
      },
    );
  }

  // ---------------------------------------------------------------------
  // VERIFY OTP
  // ---------------------------------------------------------------------
  Future<bool> verifyOTP(String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId.value,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential.user != null;
    } catch (e) {
      Get.snackbar("Error", "Invalid OTP. Try again.");
      return false;
    }
  }

  // ---------------------------------------------------------------------
  // EMAIL REGISTER
  // ---------------------------------------------------------------------
  Future<String?> registerUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // EMAIL LOGIN
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
