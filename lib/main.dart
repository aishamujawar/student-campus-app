import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:student_campus_app/screens/budgeting/shared_expenses/controllers/expense_controller.dart';

import 'firebase_options.dart';

// 🔐 Repositories
import 'repository/authentication_repository.dart';

// 🔐 Controllers
import 'controllers/main_shell_controller.dart';
import 'controllers/login_controller.dart';
import 'controllers/signup_controller.dart';
import 'controllers/forgot_password_controller.dart';
import 'controllers/profile_controller.dart';

// 💰 Budgeting Controllers
import 'screens/budgeting/personal_expenses/controllers/personal_expense_controller.dart';
import 'screens/budgeting/shared_expenses/controllers/group_controller.dart';

// 💬 Chat Controller
import 'screens/chat/controllers/chat_controller.dart';

// 🔐 Auth Screens
import 'screens/auth/splash_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/auth_login_screen.dart';
import 'screens/auth/auth_signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/verify_email_screen.dart';

// 🏠 Core Screens
import 'screens/home/home_screen.dart';
import 'screens/assistant/campus_assistant.dart';
import 'screens/academic_hub/academic_hub_screen.dart';
import 'screens/budgeting/smart_budgeting.dart';
import 'screens/chat/chat_groups_list_screen.dart';
import 'screens/home/profile_page.dart';

// 📅 Timetable Screen
import 'screens/academic_hub/timetable_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔐 Core
  Get.put(AuthRepository(), permanent: true);
  Get.put(MainShellController(), permanent: true);

  // 🔐 Auth Controllers
  Get.put(LoginController(), permanent: true);
  Get.put(SignUpController(), permanent: true);
  Get.put(ForgotPasswordController(), permanent: true);
  Get.put(ProfileController(), permanent: true);

  // 💰 Budgeting Controllers
  Get.lazyPut<PersonalExpenseController>(
    () => PersonalExpenseController(),
    fenix: true,
  );
  Get.lazyPut<GroupController>(
    () => GroupController(),
    fenix: true,
  );
  Get.lazyPut<ExpenseController>(
    () => ExpenseController(),
    fenix: true,
  );
  
  // 💬 Chat Controller
  Get.lazyPut<ChatController>(
    () => ChatController(),
    fenix: true,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF3AA8F7);
    const secondary = Color(0xFF47D6C4);

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Campus App',
      initialRoute: '/splash',
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: primary,
        scaffoldBackgroundColor: const Color(0xFFE7F2FF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
        ),
      ),
      getPages: [
        // 🔐 AUTH
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/login', page: () => const AuthLoginScreen()),
        GetPage(name: '/signup', page: () => AuthSignupScreen()),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(name: '/verify-email', page: () => VerifyEmailScreen()),

        // 🏠 MAIN SHELL
        GetPage(name: '/home', page: () => const _MainShell()),

        // 📅 TIMETABLE
        GetPage(
          name: '/timetable',
          page: () => const TimetablePage(),
        ),
      ],
    );
  }
}

/// 🧭 MAIN SHELL WITH BOTTOM NAV
class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<MainShellController>();

    final pages = const [
      HomeScreen(),
      CampusAssistantScreen(),
      AcademicHubScreen(),
      SmartBudgetingScreen(),
      ChatGroupsListScreen(),
      ProfilePage(),
    ];

    return Obx(() {
      return Scaffold(
        extendBody: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE7F2FF), Color(0xFFD8F7F8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: IndexedStack(
            index: controller.selectedIndex.value,
            children: pages,
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
                currentIndex: controller.selectedIndex.value,
                onTap: controller.changeTab,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedItemColor: Theme.of(context).primaryColor,
                unselectedItemColor: const Color(0xFF9AA6B5),
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded), label: 'Home'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.chat_bubble_rounded), label: 'Chatbot'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.school_rounded), label: 'Academic'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.account_balance_wallet_rounded),
                      label: 'Budgeting'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.chat_rounded),
                      label: 'Chat'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded), label: 'Profile'),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}