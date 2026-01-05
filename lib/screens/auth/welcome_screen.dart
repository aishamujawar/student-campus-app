import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final LiquidController _liquidController = LiquidController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    /// ✅ Auto-skip onboarding if user already logged in
    Future.microtask(() {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Get.offAllNamed('/home');
      }
    });
  }

  void _skip() {
    Get.offAllNamed('/login');
  }

  void _onPageChange(int page) {
    setState(() => _currentPage = page);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _OnboardPage(
        title: 'Campus App',
        subtitle:
            'Your unified campus companion for academics, budgeting and campus life.',
        icon: Icons.grid_view_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF3AA8F7), Color(0xFF47D6C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _OnboardPage(
        title: 'Campus Assistant',
        subtitle:
            'AI chatbot, voice assistant and FAQs to help instantly.',
        icon: Icons.smart_toy_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF54C3F7), Color(0xFF6FE0F4)],
        ),
      ),
      _OnboardPage(
        title: 'Academic Hub',
        subtitle:
            'Attendance, CGPA, timetable, assignments and calendar.',
        icon: Icons.menu_book_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF55D7C7), Color(0xFF7BE6D9)],
        ),
      ),
      _OnboardPage(
        title: 'Smart Budgeting',
        subtitle:
            'Track expenses, analyse spending and manage shared costs.',
        icon: Icons.account_balance_wallet_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF4B6BFF), Color(0xFF61C2FF)],
        ),
      ),
      _FinalPage(
        onGetStarted: () => Get.offAllNamed('/login'),
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe(
            pages: pages,
            liquidController: _liquidController,
            onPageChangeCallback: _onPageChange,
            waveType: WaveType.liquidReveal,
            enableSideReveal: true,
            slideIconWidget: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
            positionSlideIcon: 0.55,
          ),

          /// 🔹 Skip button
          Positioned(
            top: 16,
            right: 16,
            child: TextButton(
              onPressed: _skip,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          /// 🔹 Dots indicator
          Positioned(
            bottom: 28,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.white.withOpacity(
                      _currentPage == index ? 0.9 : 0.4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔹 STANDARD ONBOARD PAGE
class _OnboardPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;

  const _OnboardPage({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(40),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 58,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🔹 FINAL PAGE WITH CTA
class _FinalPage extends StatelessWidget {
  final VoidCallback onGetStarted;

  const _FinalPage({required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF3AA8F7), Color(0xFF47D6C4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.rocket_launch_rounded,
                  size: 72,
                  color: Colors.white,
                ),
                const SizedBox(height: 28),
                const Text(
                  'Ready to get started?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Sign in and start managing your campus life smarter.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.4,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF2877E0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: onGetStarted,
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}