import 'package:flutter/material.dart';

/// Enum representing the four big feature cards on the home screen.
enum HomeFeature {
  campusAssistant,
  smartBudgeting,
  academicHub,
  campusPayScanner,
}

class HomeScreen extends StatelessWidget {
  final void Function(HomeFeature feature) onFeatureSelected;
  final VoidCallback onProfileTap;

  const HomeScreen({
    super.key,
    required this.onFeatureSelected,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.95, // 95% of screen width
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.96),
                      borderRadius: BorderRadius.circular(36),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 20),
                        _buildHeroBanner(context),
                        const SizedBox(height: 18),
                        _buildFeatureGrid(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Row(
          children: [
            Container(
              height: 32,
              width: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF3AA8F7),
                    Color(0xFF47D6C4),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.grid_view_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'CampusApp',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: onProfileTap,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Welcome back,',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: const Color(0xFF8A96A5),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Student',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4FC3F7),
                      Color(0xFF7E8BFF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4FC3F7).withOpacity(0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2),
                child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    color: Color(0xFF4C5D73),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF3AA8F7),
            Color(0xFF47D6C4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Unified Campus Companion',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Organise academics, money,\nattendance and campus life\nin one intelligent assistant.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2877E0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  onFeatureSelected(HomeFeature.campusAssistant);
                },
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.35),
                    width: 0.95,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'AI-powered',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HomeFeatureCard(
                title: 'Campus Assistant',
                subtitle: 'AI chatbot + voice assistant + FAQ',
                icon: Icons.smart_toy_rounded,
                startColor: const Color(0xFF54C3F7),
                endColor: const Color(0xFF6FE0F4),
                onTap: () => onFeatureSelected(HomeFeature.campusAssistant),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HomeFeatureCard(
                title: 'Smart Budgeting',
                subtitle:
                    'Expense tracking + analytics + auto categorization',
                icon: Icons.pie_chart_rounded,
                startColor: const Color(0xFF4B6BFF),
                endColor: const Color(0xFF61C2FF),
                onTap: () => onFeatureSelected(HomeFeature.smartBudgeting),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HomeFeatureCard(
                title: 'Academic Hub',
                subtitle:
                    'Calendar + attendance + GPA + assignments + timetable',
                icon: Icons.menu_book_rounded,
                startColor: const Color(0xFF55D7C7),
                endColor: const Color(0xFF7BE6D9),
                onTap: () => onFeatureSelected(HomeFeature.academicHub),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _HomeFeatureCard(
                title: 'CampusPay Scanner',
                subtitle: 'QR payments + ESP32 simulator',
                icon: Icons.qr_code_scanner_rounded,
                startColor: const Color(0xFF7B7CFF),
                endColor: const Color(0xFFB0A8FF),
                onTap: () => onFeatureSelected(HomeFeature.campusPayScanner),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final VoidCallback onTap;

  const _HomeFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.startColor,
    required this.endColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 132,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                startColor.withOpacity(0.98),
                endColor.withOpacity(0.96),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: startColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 11.5,
                    height: 1.3,
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