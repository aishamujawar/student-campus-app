import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

// 🔐 Repository
import 'repository/authentication_repository.dart';

// 🤝 Controllers
import 'screens/budgeting/shared_expenses/controllers/group_controller.dart';

// 🔐 Auth & Splash
import 'screens/auth/splash_screen.dart';
import 'screens/auth/auth_login_screen.dart';
import 'screens/auth/auth_signup_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/auth/verify_email_screen.dart'; // ✅ ADD THIS

// 🏠 Core Screens
import 'screens/home/home_screen.dart';
import 'screens/assistant/campus_assistant.dart';
import 'screens/academic_hub/academic_hub_screen.dart';
import 'screens/budgeting/smart_budgeting.dart';
import 'screens/payments/campuspay_scanner.dart';
import 'screens/home/profile_page.dart';

// 💰 Budgeting
import 'screens/budgeting/personal_expenses_screen.dart';
import 'screens/budgeting/shared_expenses/shared_expenses_screen.dart';

// 🤝 Shared Expenses
import 'screens/budgeting/shared_expenses/groups_list_screen.dart';
import 'screens/budgeting/shared_expenses/create_group_screen.dart';
import 'screens/budgeting/shared_expenses/group_detail_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  /// ✅ Dependency Injection
  Get.put(AuthRepository(), permanent: true);
  Get.lazyPut<GroupController>(() => GroupController(), fenix: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Campus App',
      initialRoute: '/splash',
      getPages: [
        // 🔐 AUTH FLOW
        GetPage(name: '/splash', page: () => const SplashScreen()),
        GetPage(name: '/welcome', page: () => const WelcomeScreen()),
        GetPage(name: '/login', page: () => const AuthLoginScreen()),
        GetPage(name: '/signup', page: () => AuthSignupScreen()),
        GetPage(
          name: '/forgot-password',
          page: () => const ForgotPasswordScreen(),
        ),
        GetPage(
          name: '/verify-email',
          page: () => VerifyEmailScreen(), // ✅ ADD THIS
        ),

        // 🏠 CORE APP
        GetPage(name: '/home', page: () => const HomeScreen()),
        GetPage(name: '/assistant', page: () => const CampusAssistantScreen()),
        GetPage(name: '/academic-hub', page: () => const AcademicHubScreen()),
        GetPage(
          name: '/smart-budgeting',
          page: () => const SmartBudgetingScreen(),
        ),
        GetPage(name: '/scanner', page: () => const CampusPayScannerScreen()),
        GetPage(name: '/profile', page: () => const ProfilePage()),

        // 💰 BUDGETING
        GetPage(
          name: '/personal-expenses',
          page: () => const PersonalExpensesScreen(),
        ),
        GetPage(
          name: '/shared-expenses',
          page: () => SharedExpensesScreen(),
        ),

        // 🤝 SHARED EXPENSES FLOW
        GetPage(name: '/groups', page: () => const GroupsListScreen()),
        GetPage(name: '/create-group', page: () => CreateGroupScreen()),
        GetPage(
          name: '/group-detail',
          page: () {
            final args = Get.arguments as Map<String, dynamic>? ?? {};
            return GroupDetailScreen(
              groupId: args['groupId'],
              groupData: args['groupData'],
            );
          },
        ),
      ],
    );
  }
}
