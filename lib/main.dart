import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';

// Repositories & Controllers
import 'repository/authentication_repository.dart';
import 'controllers/otp_controller.dart';

// Auth & Splash
import 'screens/auth/splash_screen.dart';
import 'screens/auth/auth_login_screen.dart';
import 'screens/auth/auth_signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/welcome_screen.dart';

// Core Screens
import 'screens/home/home_screen.dart';
import 'screens/assistant/campus_assistant.dart';
import 'screens/academic_hub/academic_hub_screen.dart';
import 'screens/budgeting/smart_budgeting.dart';
import 'screens/payments/campuspay_scanner.dart';
import 'screens/home/profile_page.dart';

/// ---------------------------------------------------------------------------
/// MAIN
/// ---------------------------------------------------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// ✅ Inject dependencies ONCE
  Get.put(AuthRepository());
  Get.put(OtpController());

  runApp(const CampusCompanionApp());
}

/// ---------------------------------------------------------------------------
/// MAIN SHELL (BOTTOM NAV)  ✅ MUST BE ABOVE APP WIDGET
/// ---------------------------------------------------------------------------
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(
        onFeatureSelected: _handleHomeFeatureTap,
        onProfileTap: () => _onItemTapped(5),
      ),
      CampusAssistantScreen(),
      AcademicHubScreen(),
      SmartBudgetingScreen(),
      CampusPayScannerScreen(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _handleHomeFeatureTap(HomeFeature feature) {
    switch (feature) {
      case HomeFeature.campusAssistant:
        _onItemTapped(1);
        break;
      case HomeFeature.academicHub:
        _onItemTapped(2);
        break;
      case HomeFeature.smartBudgeting:
        _onItemTapped(3);
        break;
      case HomeFeature.campusPayScanner:
        _onItemTapped(4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;
    const unselectedColor = Color(0xFF9AA6B5);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chatbot'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Academic'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Pay'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// APP ROOT
/// ---------------------------------------------------------------------------
class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF3AA8F7);
    const Color secondary = Color(0xFF47D6C4);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus Companion',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: primary,
        scaffoldBackgroundColor: const Color(0xFFE7F2FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          brightness: Brightness.light,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const AuthLoginScreen(),
        '/signup': (_) => const AuthSignupScreen(),
        '/forgot-password': (_) => const ForgotPasswordScreen(),
        '/otp': (_) => const OtpScreen(),
        '/welcome': (_) => const WelcomeScreen(),
        '/home': (_) => const MainShell(),
      },
    );
  }
}
