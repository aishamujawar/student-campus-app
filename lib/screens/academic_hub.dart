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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
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
                  Row(
                    children: [
                      Text(
                        'Academic Hub',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: const Color(0xFFE7F2FF),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.school_rounded,
                              size: 16,
                              color: Color(0xFF2877E0),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Tools',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2877E0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _AcademicHeroBanner(theme: theme),
                  const SizedBox(height: 18),
                  _buildToolGrid(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToolGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AcademicToolCard(
                title: 'Calendar',
                icon: Icons.calendar_month_rounded,
                onTap: () => _open(context, const CalendarPage()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AcademicToolCard(
                title: 'CGPA',
                icon: Icons.calculate_rounded,
                onTap: () => _open(context, const CgpaPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AcademicToolCard(
                title: 'Attendance',
                icon: Icons.fact_check_rounded,
                onTap: () => _open(context, const AttendancePage()),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _AcademicToolCard(
                title: 'Assignments',
                icon: Icons.task_rounded,
                onTap: () => _open(context, const AssignmentsPage()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AcademicToolCard(
                title: 'Timetable',
                icon: Icons.schedule_rounded,
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

class _AcademicHeroBanner extends StatelessWidget {
  final ThemeData theme;

  const _AcademicHeroBanner({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CBBD1),
            Color(0xFF57E4C9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stay on top of academics',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 19,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quick access to calendar, CGPA, attendance, and more.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.insights_rounded,
            color: Colors.white,
            size: 32,
          ),
        ],
      ),
    );
  }
}

class _AcademicToolCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _AcademicToolCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Ink(
        height: 112,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE7F2FF),
              Color(0xFFDDF9F3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 22,
                color: const Color(0xFF2877E0),
              ),
              const Spacer(),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16222C),
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Open',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF7A8A9C),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}