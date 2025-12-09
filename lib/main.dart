import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

// import 'firebase_options.dart'; // only if you use flutterfire CLI
import 'controllers/signup_controller.dart';
import 'controllers/login_controller.dart';
import 'controllers/forgot_password_controller.dart';
import 'controllers/otp_controller.dart';

import 'screens/auth/welcome_screen.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/auth_login_screen.dart';
import 'screens/auth/auth_signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/otp_screen.dart';

import 'screens/home/home_screen.dart';
import 'screens/home/profile_page.dart';

import 'screens/assistant/campus_assistant.dart';
import 'screens/academic_hub/academic_hub_screen.dart';
import 'screens/budgeting/smart_budgeting.dart';
import 'screens/payments/campuspay_scanner.dart';

void main() {
  runApp(const CampusCompanionApp());
}

class CampusCompanionApp extends StatelessWidget {
  const CampusCompanionApp({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF3AA8F7);
    final Color secondary = const Color(0xFF47D6C4);

    return MaterialApp(
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
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF16222C),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF16222C),
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF16222C),
          ),
          bodyMedium: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF5A6A7A),
          ),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const AuthLoginScreen(),
        '/signup': (_) => const AuthSignupScreen(),
        '/home': (_) => const _MainShell(), // your main app with bottom nav
        '/forgot-password': (_) => const ForgotPasswordScreen(), 
        '/otp': (_) => const OtpScreen(),
        '/welcome': (_) => const WelcomeScreen(), 
      },
    );
  }
}

/// Main shell with persistent bottom navigation bar.
/// All top-level pages (Home, Chatbot, Academic Hub, Budgeting,
/// CampusPay, Profile) live here.
class _MainShell extends StatefulWidget {
  const _MainShell({super.key});

  @override
  State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
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
      const CampusAssistantScreen(),
      const AcademicHubScreen(),
      const SmartBudgetingScreen(),
      const CampusPayScannerScreen(),
      const ProfilePage(),
    ];
  }

  void _onItemTapped(int index) {
    if (!mounted) return;
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Mapping from home feature cards to bottom-nav destinations.
  void _handleHomeFeatureTap(HomeFeature feature) {
    switch (feature) {
      case HomeFeature.campusAssistant:
        _onItemTapped(1); // Chatbot / Campus Assistant
        break;
      case HomeFeature.smartBudgeting:
        _onItemTapped(3); // Budgeting
        break;
      case HomeFeature.academicHub:
        _onItemTapped(2); // Academic Hub
        break;
      case HomeFeature.campusPayScanner:
        _onItemTapped(4); // CampusPay
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedColor = theme.colorScheme.primary;
    final unselectedColor = const Color(0xFF9AA6B5);

    return Scaffold(
      extendBody: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE7F2FF),
              Color(0xFFD8F7F8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BottomNavigationBar(
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              elevation: 0,
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: selectedColor,
              unselectedItemColor: unselectedColor,
              showUnselectedLabels: true,
              selectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_bubble_rounded),
                  label: 'Chatbot',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.school_rounded),
                  label: 'Academic',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_rounded),
                  label: 'Budgeting',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.qr_code_scanner_rounded),
                  label: 'CampusPay',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}