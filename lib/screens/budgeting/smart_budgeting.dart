import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:student_campus_app/screens/budgeting/personal_expenses/screens/personal_expenses_page.dart';
import 'package:student_campus_app/screens/budgeting/shared_expenses/groups_list_screen.dart';

class SmartBudgetingScreen extends StatelessWidget {
  const SmartBudgetingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme),
                          const SizedBox(height: 20),

                          Text(
                            'Manage your spending smartly',
                            style: theme.textTheme.titleMedium,
                          ),

                          const SizedBox(height: 24),

                          /// 🔹 Personal Expenses (✅ FIXED ROUTE - UPDATED)
                          BudgetOptionCard(
                            title: 'Personal Expenses',
                            subtitle: 'Track your own spending',
                            icon: Icons.person_rounded,
                            color: const Color(0xFF4B6BFF),
                            onTap: () {
                              // CHANGED FROM Get.toNamed TO Navigator.push
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PersonalExpensesPage(),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          /// 🔹 Shared Expenses
                          BudgetOptionCard(
                            title: 'Shared Expenses',
                            subtitle: 'Split bills with friends',
                            icon: Icons.group_rounded,
                            color: const Color(0xFF2BB673),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GroupsListPage(),
                                ),
                              );
                            },
                          ),
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

  /// 🔹 Header
  Widget _buildHeader(ThemeData theme) {
    return Row(
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
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Smart Budgeting',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// 🔹 Budget option card
class BudgetOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const BudgetOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F7FB),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF9AA6B5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}