import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                onProfileTap: () => Get.toNamed('/profile'),
              ),
              const SizedBox(height: 24),
              Text(
                'What would you like to do today?',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.95,
                  children: [
                    _FeatureCard(
                      icon: Icons.chat_bubble_rounded,
                      title: 'Campus Assistant',
                      subtitle: 'Ask anything instantly',
                      color: const Color(0xFF4A90E2),
                      onTap: () => Get.toNamed('/assistant'),
                    ),
                    _FeatureCard(
                      icon: Icons.school_rounded,
                      title: 'Academic Hub',
                      subtitle: 'Notes & resources',
                      color: const Color(0xFF7B61FF),
                      onTap: () => Get.toNamed('/academic-hub'),
                    ),
                    _FeatureCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Smart Budgeting',
                      subtitle: 'Track expenses',
                      color: const Color(0xFF2BB673),
                      onTap: () => Get.toNamed('/smart-budgeting'),
                    ),
                    _FeatureCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'CampusPay',
                      subtitle: 'Scan & pay fast',
                      color: const Color(0xFFFF8C42),
                      onTap: () => Get.toNamed('/scanner'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🔹 Header with greeting + profile icon
class _Header extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _Header({required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good day 👋',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5A6A7A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Welcome to Campus',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16222C),
              ),
            ),
          ],
        ),
        const Spacer(),
        InkWell(
          onTap: onProfileTap,
          borderRadius: BorderRadius.circular(24),
          child: const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE7F2FF),
            child: Icon(
              Icons.person_rounded,
              color: Color(0xFF3AA8F7),
            ),
          ),
        ),
      ],
    );
  }
}

/// 🔹 Feature Card
class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16222C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5A6A7A),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
