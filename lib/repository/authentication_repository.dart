import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository extends GetxController {
  static AuthRepository get instance => Get.find<AuthRepository>();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final isLoading = false.obs;

  /// 🔐 LOGIN WITH EMAIL & PASSWORD
  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      // 1️⃣ Sign in
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final user = userCredential.user;

      // 🚨 Safety check
      if (user == null) {
        throw Exception('Login failed');
      }

      // 🔄 Refresh user state
      await user.reload();
      final refreshedUser = _auth.currentUser;

      // 2️⃣ Enforce email verification
      if (refreshedUser != null && refreshedUser.emailVerified) {
        // ✅ Verified → allow entry
        Get.offAllNamed('/home');
      } else {
        // ❌ Not verified → block login
        await _auth.signOut();

        Get.snackbar(
          'Email not verified',
          'Please verify your email before logging in',
          snackPosition: SnackPosition.BOTTOM,
        );

        Get.offAllNamed('/verify-email');
      }
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Login failed',
        e.message ?? 'Invalid credentials',
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Login failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// 👤 CURRENT USER
  User? get currentUser => _auth.currentUser;

  /// 🚪 LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
    Get.offAllNamed('/login');
  }
}
