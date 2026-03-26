import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:student_campus_app/screens/budgeting/personal_expenses/controllers/personal_expense_controller.dart';
import 'package:student_campus_app/screens/budgeting/personal_expenses/models/personal_expense_model.dart';

// =====================================================
// PERSONAL EXPENSES PAGE
// =====================================================

class PersonalExpensesPage extends StatelessWidget {
  const PersonalExpensesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PersonalExpenseController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE7F2FF),
              Color(0xFFD8F7F8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: FractionallySizedBox(
                widthFactor: 0.9,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: _card(controller, context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(PersonalExpenseController controller, BuildContext context) =>
      Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.98),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 26,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(context),
            const SizedBox(height: 16),
            _summaryCards(controller),
            const SizedBox(height: 20),
            
            // Monthly Trend and Weekly Breakdown SIDE BY SIDE
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 340,
                    child: _MonthlyTrendChartCard(controller: controller),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 340,
                    child: _WeeklyBreakdownChart(controller: controller),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Category Pie Chart and Calendar Heatmap side by side
            Row(
              children: [
                // Category Pie Chart (50% width)
                Expanded(
                  child: SizedBox(
                    height: 400,
                    child: _CategoryPieChartCard(controller: controller),
                  ),
                ),
                const SizedBox(width: 16),
                // Calendar Heatmap (50% width)
                Expanded(
                  child: SizedBox(
                    height: 400,
                    child: _CalendarHeatmapCard(controller: controller),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Spending Day Insight
            _SpendingDayInsight(controller: controller),
            const SizedBox(height: 20),
            
            _expenseListHeader(controller, context),
            const SizedBox(height: 12),
            _expenseList(controller, context),
          ],
        ),
      );

  Widget _header(BuildContext context) => Row(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: const LinearGradient(
                colors: [Color(0xFF4CBBD1), Color(0xFF57E4C9)],
              ),
            ),
            child: const Icon(
              Icons.currency_rupee_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Personal Expenses',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  Widget _summaryCards(PersonalExpenseController controller) {
    return Obx(() {
      return Row(
        children: [
          Expanded(
            child: _SummaryCard(
              title: 'Total Spent',
              value: '₹${controller.totalAmount.value.toInt()}',
              color: const Color(0xFF3AA8F7),
              icon: Icons.currency_rupee_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              title: 'This Month',
              value: '₹${controller.thisMonthAmount.value.toInt()}',
              color: const Color(0xFF55D7C7),
              icon: Icons.calendar_month_rounded,
            ),
          ),
        ],
      );
    });
  }

  Widget _expenseListHeader(
          PersonalExpenseController controller, BuildContext context) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Expenses',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openAddExpenseSheet(controller, context),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Expense'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3AA8F7),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: const Color(0xFF3AA8F7).withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _expenseList(
      PersonalExpenseController controller, BuildContext context) {
    return Obx(() {
      if (controller.filteredExpenses.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: Color(0xFF7A8A9C),
              ),
              const SizedBox(height: 12),
              const Text(
                'No expenses recorded',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap "Add Expense" above to get started',
                style: TextStyle(color: Color(0xFF7A8A9C)),
              ),
            ],
          ),
        );
      }

      // Get only the 5 most recent expenses
      final recentExpenses = controller.filteredExpenses.take(5).toList();

      return Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentExpenses.length,
            itemBuilder: (_, i) {
              final expense = recentExpenses[i];
              return _ExpenseTile(
                expense: expense,
                onDelete: () => _deleteExpense(expense, controller, context),
              );
            },
          ),
          // Show "Show All" button if there are more than 5 expenses
          if (controller.filteredExpenses.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E6F0)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      // Show all expenses in bottom sheet
                      _showAllExpensesDialog(controller, context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.list_alt_rounded,
                            size: 14,
                            color: Color(0xFF3AA8F7),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Show All (${controller.filteredExpenses.length})',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3AA8F7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  // Show all expenses in a bottom sheet
  void _showAllExpensesDialog(
      PersonalExpenseController controller, BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E6F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Text(
                    'All Expenses',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Expenses list
            Expanded(
              child: Obx(() {
                if (controller.filteredExpenses.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.receipt_long_rounded,
                          size: 48,
                          color: Color(0xFF7A8A9C),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No expenses',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your first expense to see it here',
                          style: TextStyle(color: Color(0xFF7A8A9C)),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: controller.filteredExpenses.length,
                  itemBuilder: (_, i) {
                    final expense = controller.filteredExpenses[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: _getCategoryColor(expense.category)
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              _getCategoryIcon(expense.category),
                              size: 16,
                              color: _getCategoryColor(expense.category),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${expense.category} • ${DateFormat('dd MMM, yyyy').format(expense.expenseDate)}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7A8A9C),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${expense.amount.toInt()}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  // Delete with undo snackbar
                                  await _deleteExpense(expense, controller, context);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF5350)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFFEF5350),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              }),
            ),
            // Padding at bottom for safety
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // Add these helper methods (copy them from _ExpenseTile class)
  Color _getCategoryColor(String category) {
    const colors = [
      Color(0xFF2877E0),
      Color(0xFF4B6BFF),
      Color(0xFF3AA8F7),
      Color(0xFF55D7C7),
      Color(0xFF7B7CFF),
      Color(0xFF61C2FF),
      Color(0xFF6FE0F4),
    ];

    const categories = [
      'Food',
      'Travel',
      'Shopping',
      'Rent',
      'Entertainment',
      'Other'
    ];
    final index = categories.indexOf(category);
    return colors[(index < 0 ? 0 : index) % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Travel':
        return Icons.flight_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Rent':
        return Icons.home_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Other':
        return Icons.category_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Future<void> _openAddExpenseSheet(
      PersonalExpenseController controller, BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddExpenseSheet(controller: controller),
    );
  }

  Future<void> _deleteExpense(PersonalExpense expense,
      PersonalExpenseController controller, BuildContext context) async {
    // Only delete without undo snackbar from controller
    await controller.deleteExpense(expense);
    
    // Show single premium blue snackbar
    Get.rawSnackbar(
      messageText: const Text(
        'Expense deleted',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      backgroundColor: const Color(0xFF3AA8F7),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(20),
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      mainButton: TextButton(
        onPressed: () {
          Get.back(); // Close snackbar
          controller.undoDelete(); // Call your controller's undo method
        },
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: const Text(
          'UNDO',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// =====================================================
// SUMMARY CARD WIDGET
// =====================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8A9C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CATEGORY PIE CHART CARD (50% width with left-aligned legend)
// =====================================================

class _CategoryPieChartCard extends StatelessWidget {
  final PersonalExpenseController controller;

  const _CategoryPieChartCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF16222C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Across all months',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF7A8A9C),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 220, // Bigger chart height
                  child: Obx(() {
                    final totals = controller.categoryTotals;
                    
                    if (totals.isEmpty) {
                      return Center(
                        child: Text(
                          'No data',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFF7A8A9C).withOpacity(0.7),
                          ),
                        ),
                      );
                    }

                    final entries = totals.entries.toList();
                    final total = entries.fold(0.0, (sum, entry) => sum + entry.value);
                    if (total == 0) {
                      return Center(
                        child: Text(
                          'No data',
                          style: TextStyle(
                            fontSize: 10,
                            color: const Color(0xFF7A8A9C).withOpacity(0.7),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 200,
                      width: 200,
                      child: CustomPaint(
                        painter: _PieChartPainter(
                          entries: entries,
                          total: total,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _CategoryLegendLeftAligned(controller: controller),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================
// CATEGORY PIE CHART PAINTER (unchanged)
// =====================================================

class _PieChartPainter extends CustomPainter {
  final List<MapEntry<String, double>> entries;
  final double total;

  const _PieChartPainter({
    required this.entries,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    final palette = const [
      Color(0xFF2877E0), // strong blue
      Color(0xFF4B6BFF), // deep indigo
      Color(0xFF3AA8F7), // bright sky blue
      Color(0xFF55D7C7), // teal green
      Color(0xFF7B7CFF), // bluish violet
      Color(0xFF61C2FF), // lighter blue
      Color(0xFF6FE0F4), // lighter cyan
    ];

    double startAngle = -90;
    double currentAngle = startAngle;

    for (int i = 0; i < entries.length; i++) {
      final sweepAngle = 360 * (entries[i].value / total);
      final paint = Paint()
        ..color = palette[i % palette.length]
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle * (pi / 180),
        sweepAngle * (pi / 180),
        true,
        paint,
      );

      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) =>
      oldDelegate.entries != entries || oldDelegate.total != total;
}

// =====================================================
// CATEGORY LEGEND LEFT ALIGNED (for 50% width)
// =====================================================

class _CategoryLegendLeftAligned extends StatelessWidget {
  final PersonalExpenseController controller;

  const _CategoryLegendLeftAligned({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.categoryTotals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final total = entries.fold(0.0, (s, e) => s + e.value);

      if (total == 0) {
        return Center(
          child: Text(
            'No spending data',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF7A8A9C).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: entries.length,
        itemBuilder: (context, index) {
          final entry = entries[index];
          final percent = (entry.value / total) * 100;
          final palette = const [
            Color(0xFF2877E0),
            Color(0xFF4B6BFF),
            Color(0xFF3AA8F7),
            Color(0xFF55D7C7),
            Color(0xFF7B7CFF),
            Color(0xFF61C2FF),
          ];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: palette[index % palette.length],
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${percent.toStringAsFixed(0)}% of spending',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF7A8A9C),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E6F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '₹${entry.value.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF16222C),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }
}

// =====================================================
// CALENDAR HEATMAP CARD (REAL GITHUB-STYLE)
// =====================================================

class _CalendarHeatmapCard extends StatefulWidget {
  final PersonalExpenseController controller;

  const _CalendarHeatmapCard({required this.controller});

  @override
  State<_CalendarHeatmapCard> createState() => _CalendarHeatmapCardState();
}

class _CalendarHeatmapCardState extends State<_CalendarHeatmapCard> {
  DateTime _selectedMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar Heatmap',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF16222C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Daily spending intensity',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF7A8A9C),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),
          _monthSelector(),
          const SizedBox(height: 12),
          _weekdayHeader(),
          const SizedBox(height: 8),
          Expanded(
            child: Obx(() => _calendarGrid()),
          ),
          const SizedBox(height: 12),
          _intensityLegend(),
        ],
      ),
    );
  }

  Widget _monthSelector() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E6F0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_left, size: 18),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              foregroundColor: const Color(0xFF3AA8F7),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE0E6F0)),
              ),
              child: Text(
                DateFormat('MMMM yyyy').format(_selectedMonth),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Color(0xFF16222C),
                ),
              ),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE0E6F0)),
          ),
          child: IconButton(
            icon: const Icon(Icons.chevron_right, size: 18),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
            style: IconButton.styleFrom(
              padding: const EdgeInsets.all(8),
              foregroundColor: const Color(0xFF3AA8F7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _weekdayHeader() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days
          .map((d) => SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    d,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF7A8A9C),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _calendarGrid() {
    final controller = widget.controller;
    final firstDay = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final daysInMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0).day;

    final startWeekday = firstDay.weekday; // 1 = Monday

    final List<Widget> cells = [];

    // Empty cells before month starts
    for (int i = 1; i < startWeekday; i++) {
      cells.add(_emptyCell());
    }

    // Collect all amounts for the month for percentile calculation
    final List<double> allAmounts = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final amount = controller.dailyTotals[date] ?? 0.0;
      allAmounts.add(amount);
    }

    // Calculate intensities based on percentiles
    final List<double> intensities = [];
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final amount = controller.dailyTotals[date] ?? 0.0;
      final intensity = _calculateIntensity(amount, allAmounts);
      intensities.add(intensity);
    }

    // Actual days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_selectedMonth.year, _selectedMonth.month, day);
      final amount = controller.dailyTotals[date] ?? 0.0;
      final intensity = intensities[day - 1];

      cells.add(_dayCell(day, amount, intensity));
    }

    // Calculate how many rows we need (5 or 6)
    final totalCells = cells.length;
    final rowsNeeded = (totalCells / 7).ceil();

    // Add empty cells to complete the last row
    final cellsNeeded = rowsNeeded * 7;
    while (cells.length < cellsNeeded) {
      cells.add(_emptyCell());
    }

    // Build rows
    final List<Widget> rows = [];
    for (int i = 0; i < rowsNeeded; i++) {
      final rowCells = cells.sublist(i * 7, (i + 1) * 7);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowCells,
          ),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: rows,
    );
  }

  double _calculateIntensity(double amount, List<double> allAmounts) {
    if (amount == 0) return 0;
    
    // Filter out zeros and sort
    final nonZero = allAmounts.where((a) => a > 0).toList();
    if (nonZero.isEmpty) return 0;
    
    nonZero.sort();
    
    // Use percentiles: 33rd and 66th percentile
    final lowPercentileIndex = ((nonZero.length - 1) * 0.33).floor();
    final mediumPercentileIndex = ((nonZero.length - 1) * 0.66).floor();
    
    final lowThreshold = nonZero[lowPercentileIndex];
    final mediumThreshold = nonZero[mediumPercentileIndex];
    
    if (amount < lowThreshold) return 0.3;    // Bottom 33% → Green
    if (amount < mediumThreshold) return 0.6; // Middle 33% → Orange
    return 1.0;                               // Top 33% → Red
  }

  Widget _emptyCell() => const SizedBox(width: 28, height: 28);

  Widget _dayCell(int day, double amount, double intensity) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _getHeatmapColor(intensity),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          if (intensity > 0)
            BoxShadow(
              color: _getHeatmapColor(intensity).withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: intensity > 0.5 ? Colors.white : const Color(0xFF16222C),
          ),
        ),
      ),
    );
  }

  Color _getHeatmapColor(double intensity) {
    if (intensity == 0) return const Color(0xFFE0E6F0);
    if (intensity >= 0.7) return const Color(0xFFF44336); // Red
    if (intensity >= 0.4) return const Color(0xFFFF9800); // Orange
    return const Color(0xFF4CAF50); // Green
  }

  Widget _intensityLegend() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E6F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(const Color(0xFFE0E6F0), 'None'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFF4CAF50), 'Low'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFFF9800), 'Medium'),
          const SizedBox(width: 8),
          _legendItem(const Color(0xFFF44336), 'High'),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF7A8A9C),
          ),
        ),
      ],
    );
  }
}

// =====================================================
// MONTHLY TREND CHART CARD (Full width) - UNCHANGED
// =====================================================

class _MonthlyTrendChartCard extends StatelessWidget {
  final PersonalExpenseController controller;

  const _MonthlyTrendChartCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Trend',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF16222C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Spending over time',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF7A8A9C),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _MonthlyTrendChartContent(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendChartContent extends StatelessWidget {
  final PersonalExpenseController controller;

  const _MonthlyTrendChartContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final entries = controller.monthlyTotals.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      if (entries.isEmpty) {
        return Center(
          child: Text(
            'No monthly data',
            style: TextStyle(
              color: const Color(0xFF7A8A9C).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return SizedBox(
        height: 220, // Fixed height
        width: double.infinity, // Full width
        child: CustomPaint(
          painter: _MonthlyTrendPainter(
            monthlyData: entries.map((e) => MapEntry(e.key, e.value)).toList(),
          ),
        ),
      );
    });
  }
}

class _MonthlyTrendPainter extends CustomPainter {
  final List<MapEntry<String, double>> monthlyData;

  const _MonthlyTrendPainter({
    required this.monthlyData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (monthlyData.isEmpty) return;

    // Find min and max values
    final maxValue = monthlyData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    final minValue = monthlyData
        .map((e) => e.value)
        .reduce((a, b) => a < b ? a : b);

    final padding = 28.0; // Reduced padding for edges
    final chartWidth = size.width - 2 * padding;
    final chartHeight = size.height - 2 * padding;
    
    // Draw Y-axis
    final axisPaint = Paint()
      ..color = const Color(0xFF7A8A9C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Y-axis line
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    
    // X-axis line
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Draw Y-axis labels
    final textStyle = const TextStyle(
      fontSize: 10,
      color: Color(0xFF7A8A9C),
    );
    
    for (int i = 0; i <= 5; i++) {
      final value = minValue + (maxValue - minValue) * i / 5;
      final y = size.height - padding - (chartHeight * i / 5);
      
      // Draw grid line
      final gridPaint = Paint()
        ..color = const Color(0xFFE0E6F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
      
      // Draw Y-axis label
      final labelText = TextPainter(
        text: TextSpan(
          text: '₹${value.toInt()}',
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelText.layout();
      labelText.paint(
        canvas,
        Offset(padding - labelText.width - 4, y - labelText.height / 2),
      );
    }

    // Calculate points
    final List<Offset> points = [];
    for (int i = 0; i < monthlyData.length; i++) {
      final value = monthlyData[i].value;

      double normalizedY = 0.5;
      if (maxValue != minValue) {
        normalizedY = (value - minValue) / (maxValue - minValue);
        normalizedY = normalizedY.clamp(0.0, 1.0);
      }

      final x = monthlyData.length == 1
          ? padding + chartWidth / 2
          : padding + (chartWidth * i / (monthlyData.length - 1));
      final y = size.height - padding - (chartHeight * normalizedY);
      
      if (!x.isNaN && !y.isNaN) {
        points.add(Offset(x, y));
      }
    }

    // Draw filled area under the line
    final bgPaint = Paint()
      ..color = const Color(0xFF3AA8F7).withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, size.height - padding);
      for (final point in points) {
        path.lineTo(point.dx, point.dy);
      }
      path.lineTo(points.last.dx, size.height - padding);
      path.close();
      canvas.drawPath(path, bgPaint);
    }

    // Draw line
    final linePaint = Paint()
      ..color = const Color(0xFF3AA8F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    for (int i = 0; i < points.length - 1; i++) {
      if (!points[i].dx.isNaN && !points[i].dy.isNaN && 
          !points[i + 1].dx.isNaN && !points[i + 1].dy.isNaN) {
        canvas.drawLine(points[i], points[i + 1], linePaint);
      }
    }

    // Draw points
    final pointPaint = Paint()
      ..color = const Color(0xFF3AA8F7)
      ..style = PaintingStyle.fill;
    
    for (final point in points) {
      if (!point.dx.isNaN && !point.dy.isNaN) {
        canvas.drawCircle(point, 4.0, pointPaint);
        // Draw white center for points
        final centerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(point, 2.0, centerPaint);
      }
    }

    // Draw month labels on X-axis
    for (int i = 0; i < monthlyData.length; i++) {
      final monthText = _formatMonthLabel(monthlyData[i].key);
      final textPainter = TextPainter(
        text: TextSpan(
          text: monthText,
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      
      final x = monthlyData.length == 1
          ? padding + chartWidth / 2
          : padding + (chartWidth * i / (monthlyData.length - 1));
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height - padding + 10),
      );
    }

    // Draw value labels
    for (int i = 0; i < monthlyData.length; i++) {
      if (i < points.length && !points[i].dx.isNaN && !points[i].dy.isNaN) {
        final valueText = TextPainter(
          text: TextSpan(
            text: '₹${monthlyData[i].value.toInt()}',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xFF16222C),
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        );
        valueText.layout();
        valueText.paint(
          canvas,
          Offset(points[i].dx - valueText.width / 2, points[i].dy - 20),
        );
      }
    }
  }

  String _formatMonthLabel(String monthKey) {
    try {
      final date = DateTime.parse('$monthKey-01');
      return DateFormat('MMM').format(date);
    } catch (e) {
      return monthKey.length > 3 ? monthKey.substring(0, 3) : monthKey;
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) =>
      oldDelegate.monthlyData != monthlyData;
}

// =====================================================
// WEEKLY BREAKDOWN CHART (Full width) - UNCHANGED
// =====================================================

class _WeeklyBreakdownChart extends StatelessWidget {
  final PersonalExpenseController controller;

  const _WeeklyBreakdownChart({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Breakdown',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF16222C),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Last 4 weeks',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF7A8A9C),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _WeeklyBreakdownChartContent(controller: controller),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBreakdownChartContent extends StatelessWidget {
  final PersonalExpenseController controller;

  const _WeeklyBreakdownChartContent({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final weeklyData = _calculateWeeklySpending(controller);
      
      if (weeklyData.isEmpty) {
        return Center(
          child: Text(
            'No weekly data',
            style: TextStyle(
              color: const Color(0xFF7A8A9C).withOpacity(0.7),
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return SizedBox(
        height: 220, // Fixed height
        width: double.infinity, // Full width
        child: CustomPaint(
          painter: _WeeklyBreakdownPainter(weeklyData: weeklyData),
        ),
      );
    });
  }

  List<MapEntry<String, double>> _calculateWeeklySpending(
      PersonalExpenseController controller) {
    
    final now = DateTime.now();
    final fourWeeksAgo = now.subtract(const Duration(days: 28));

    final expenses = controller.filteredExpenses.where((e) {
      return e.expenseDate.isAfter(fourWeeksAgo);
    });

    final weeklyMap = <String, double>{};

    for (final e in expenses) {
      final weekStart =
          e.expenseDate.subtract(Duration(days: e.expenseDate.weekday - 1));
      final key = DateFormat('dd MMM').format(weekStart);

      weeklyMap[key] = (weeklyMap[key] ?? 0) + e.amount;
    }

    return weeklyMap.entries.toList()
      ..sort((a, b) {
        final da = DateFormat('dd MMM').parse(a.key);
        final db = DateFormat('dd MMM').parse(b.key);
        return da.compareTo(db);
      });
  }
}

class _WeeklyBreakdownPainter extends CustomPainter {
  final List<MapEntry<String, double>> weeklyData;

  const _WeeklyBreakdownPainter({
    required this.weeklyData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (weeklyData.isEmpty) return;

    final maxValue = weeklyData
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);
    
    final padding = 28.0; // Reduced padding for edges
    final barWidth = (size.width - 2 * padding) / weeklyData.length;
    final chartHeight = size.height - 2 * padding;
    final palette = const [
      Color(0xFF2877E0),
      Color(0xFF4B6BFF),
      Color(0xFF3AA8F7),
      Color(0xFF55D7C7),
    ];

    // Draw axes
    final axisPaint = Paint()
      ..color = const Color(0xFF7A8A9C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Y-axis
    canvas.drawLine(
      Offset(padding, padding),
      Offset(padding, size.height - padding),
      axisPaint,
    );
    
    // X-axis
    canvas.drawLine(
      Offset(padding, size.height - padding),
      Offset(size.width - padding, size.height - padding),
      axisPaint,
    );

    // Draw Y-axis labels and grid
    final textStyle = const TextStyle(
      fontSize: 10,
      color: Color(0xFF7A8A9C),
    );
    
    for (int i = 0; i <= 5; i++) {
      final value = (maxValue * i / 5);
      final y = size.height - padding - (chartHeight * i / 5);
      
      // Draw grid line
      final gridPaint = Paint()
        ..color = const Color(0xFFE0E6F0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
      
      // Draw Y-axis label
      final labelText = TextPainter(
        text: TextSpan(
          text: '₹${value.toInt()}',
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelText.layout();
      labelText.paint(
        canvas,
        Offset(padding - labelText.width - 4, y - labelText.height / 2),
      );
    }

    // Draw bars
    for (int i = 0; i < weeklyData.length; i++) {
      final entry = weeklyData[i];
      final barHeight = (entry.value / maxValue) * chartHeight;
      final x = padding + i * barWidth + barWidth * 0.2;
      final y = size.height - padding - barHeight;

      // Draw bar with gradient
      final barRect = Rect.fromLTWH(x, y, barWidth * 0.6, barHeight);
      final gradient = LinearGradient(
        colors: [
          palette[i % palette.length],
          palette[i % palette.length].withOpacity(0.7),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );
      final barPaint = Paint()
        ..shader = gradient.createShader(barRect)
        ..style = PaintingStyle.fill;
      
      canvas.drawRect(barRect, barPaint);

      // Draw value on top
      final textPainter = TextPainter(
        text: TextSpan(
          text: '₹${entry.value.toInt()}',
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: Color(0xFF16222C),
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x + barWidth * 0.3 - textPainter.width / 2, y - 15),
      );

      // Draw week label on X-axis
      final labelPainter = TextPainter(
        text: TextSpan(
          text: entry.key,
          style: textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x + barWidth * 0.3 - labelPainter.width / 2, size.height - padding + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBreakdownPainter oldDelegate) =>
      oldDelegate.weeklyData != weeklyData;
}

// =====================================================
// SPENDING DAY INSIGHT (With date) - UNCHANGED
// =====================================================

class _SpendingDayInsight extends StatelessWidget {
  final PersonalExpenseController controller;

  const _SpendingDayInsight({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final map = <String, double>{};

      for (final e in controller.filteredExpenses) {
        final day = DateFormat('EEEE, dd MMM').format(e.expenseDate);
        map[day] = (map[day] ?? 0) + e.amount;
      }

      if (map.isEmpty) {
        return const SizedBox();
      }

      final top = map.entries.reduce((a, b) => a.value > b.value ? a : b);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.insights_rounded, color: Color(0xFF3AA8F7)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Highest spending happens on ${top.key} (₹${top.value.toInt()})',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

// =====================================================
// EXPENSE TILE - UNCHANGED
// =====================================================

class _ExpenseTile extends StatelessWidget {
  final PersonalExpense expense;
  final VoidCallback onDelete;

  const _ExpenseTile({
    required this.expense,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          // Category icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getCategoryColor(expense.category).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Icon(
              _getCategoryIcon(expense.category),
              size: 18,
              color: _getCategoryColor(expense.category),
            ),
          ),
          const SizedBox(width: 12),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  expense.category,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF7A8A9C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd MMM, yyyy').format(expense.expenseDate),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF7A8A9C),
                  ),
                ),
              ],
            ),
          ),
          // Amount and delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${expense.amount.toInt()}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF5350).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFFEF5350),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    const colors = [
      Color(0xFF2877E0),
      Color(0xFF4B6BFF),
      Color(0xFF3AA8F7),
      Color(0xFF55D7C7),
      Color(0xFF7B7CFF),
      Color(0xFF61C2FF),
      Color(0xFF6FE0F4),
    ];

    const categories = [
      'Food',
      'Travel',
      'Shopping',
      'Rent',
      'Entertainment',
      'Other'
    ];
    final index = categories.indexOf(category);
    return colors[(index < 0 ? 0 : index) % colors.length];
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Travel':
        return Icons.flight_rounded;
      case 'Shopping':
        return Icons.shopping_bag_rounded;
      case 'Rent':
        return Icons.home_rounded;
      case 'Entertainment':
        return Icons.movie_rounded;
      case 'Other':
        return Icons.category_rounded;
      default:
        return Icons.help_rounded;
    }
  }
}

// =====================================================
// ADD EXPENSE SHEET - UNCHANGED
// =====================================================

class _AddExpenseSheet extends StatefulWidget {
  final PersonalExpenseController controller;

  const _AddExpenseSheet({required this.controller});

  @override
  State<_AddExpenseSheet> createState() => __AddExpenseSheetState();
}

class __AddExpenseSheetState extends State<_AddExpenseSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _otherCategoryController = TextEditingController();
  final List<String> _categories = [
    'Food',
    'Travel',
    'Shopping',
    'Rent',
    'Entertainment',
    'Other'
  ];
  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _errorText;
  bool _showOtherField = false;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _otherCategoryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      setState(() => _errorText = 'Please enter a valid amount');
      return;
    }

    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _errorText = 'Please enter a title');
      return;
    }

    if (_selectedCategory == null) {
      setState(() => _errorText = 'Please select a category');
      return;
    }

    String category = _selectedCategory!;
    if (category == 'Other') {
      final otherText = _otherCategoryController.text.trim();
      if (otherText.isEmpty) {
        setState(() => _errorText = 'Please specify the "Other" category');
        return;
      }
      category = otherText;
    }

    await widget.controller.addExpense(
      title: title,
      amount: amount,
      category: category,
      date: _selectedDate,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E6F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            // Title
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: const Icon(Icons.title_rounded),
                filled: true,
                fillColor: const Color(0xFFF4F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Amount
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                prefixIcon: const Icon(Icons.currency_rupee_rounded),
                filled: true,
                fillColor: const Color(0xFFF4F7FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category with placeholder
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7FB),
                borderRadius: BorderRadius.circular(18),
              ),
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                underline: const SizedBox(),
                hint: const Text(
                  'Select a category',
                  style: TextStyle(color: Color(0xFF7A8A9C)),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                    _showOtherField = value == 'Other';
                    if (value != 'Other') {
                      _otherCategoryController.clear();
                    }
                  });
                },
              ),
            ),
            // Other category text field (appears when "Other" is selected)
            if (_showOtherField) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _otherCategoryController,
                decoration: InputDecoration(
                  labelText: 'Specify other category',
                  prefixIcon: const Icon(Icons.edit_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF4F7FB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Date
            GestureDetector(
              onTap: _selectDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FB),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Color(0xFF7A8A9C),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('dd MMM, yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 24),
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3AA8F7),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: const Text(
                  'Save Expense',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}