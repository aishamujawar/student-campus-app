import 'package:flutter/material.dart';

import 'calendar_page.dart';
import 'cgpa_page.dart';
import 'attendance_page.dart';
import 'assignments_page.dart';
import 'timetable_page.dart';

class AcademicHubScreen extends StatelessWidget {
  const AcademicHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.9,
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
            ),
          );
        },
      ),
    );
  }

  // 🔹 HEADER (same pattern as Home)
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
                    Color(0xFF55D7C7),
                    Color(0xFF7BE6D9),
                  ],
                ),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.menu_book_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Academic Hub',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 🔹 HERO BANNER (same structure as Home)
  Widget _buildHeroBanner(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF55D7C7),
            Color(0xFF7BE6D9),
          ],
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
                    'Stay on top of academics',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Track attendance, CGPA, assignments\nand schedules in one place.',
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
          const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }

  // 🔹 FEATURE GRID (IDENTICAL TO HOME, JUST DIFFERENT CONTENT)
  Widget _buildFeatureGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AcademicFeatureCard(
                title: 'Calendar',
                subtitle: 'Academic events & deadlines',
                icon: Icons.calendar_month_rounded,
                startColor: const Color(0xFF54C3F7),
                endColor: const Color(0xFF6FE0F4),
                onTap: () => _open(context, const CalendarPage()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AcademicFeatureCard(
                title: 'CGPA',
                subtitle: 'Grades & performance',
                icon: Icons.calculate_rounded,
                startColor: const Color(0xFF4B6BFF),
                endColor: const Color(0xFF61C2FF),
                onTap: () => _open(context, const CgpaPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AcademicFeatureCard(
                title: 'Attendance',
                subtitle: 'Presence & shortage tracking',
                icon: Icons.fact_check_rounded,
                startColor: const Color(0xFF55D7C7),
                endColor: const Color(0xFF7BE6D9),
                onTap: () => _open(context, const AttendancePage()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AcademicFeatureCard(
                title: 'Assignments',
                subtitle: 'Tasks & submissions',
                icon: Icons.task_rounded,
                startColor: const Color(0xFF7B7CFF),
                endColor: const Color(0xFFB0A8FF),
                onTap: () => _open(context, const AssignmentsPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AcademicFeatureCard(
                title: 'Timetable',
                subtitle: 'Class schedules',
                icon: Icons.schedule_rounded,
                startColor: const Color(0xFF3AA8F7),
                endColor: const Color(0xFF47D6C4),
                onTap: () => _open(context, const TimetablePage()),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(child: SizedBox.shrink()),
          ],
        ),
      ],
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

/// 🔹 FEATURE CARD (CLONE OF HOME FEATURE CARD)
class _AcademicFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color startColor;
  final Color endColor;
  final VoidCallback onTap;

  const _AcademicFeatureCard({
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
            ),
            boxShadow: [
              BoxShadow(
                color: startColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
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
                    child: Icon(icon, size: 20, color: Colors.white),
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
    );
  }
}