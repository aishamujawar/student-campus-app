import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainShellController extends GetxController {
  final RxInt selectedIndex = 0.obs;
  bool _isInitialized = false;

  @override
  void onInit() {
    super.onInit();
    Future.delayed(const Duration(milliseconds: 500), () {
      _isInitialized = true;
      _setupAuthListener();
    });
  }
  
  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (_isInitialized && user == null) {
        // User logged out - go to welcome
        Future.microtask(() {
          if (Get.context != null) {
            Get.offAllNamed('/welcome');
          }
        });
      } else if (_isInitialized && user != null) {
        // User logged in - reset to home tab
        Future.microtask(() {
          selectedIndex.value = 0; // Reset to Home tab
        });
      }
    });
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }
}