import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/personal_expense_controller.dart';
import '../widgets/charts/category_pie_chart.dart';
import '../widgets/charts/monthly_bar_chart.dart';
import '../widgets/filter_bottom_sheet.dart';

class PersonalDashboardScreen extends StatelessWidget {
  const PersonalDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PersonalExpenseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) => const FilterBottomSheet(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/add-personal-expense'),
        child: const Icon(Icons.add),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ================= METRICS =================
              _metricCard(
                title: 'Total Spent (Filtered)',
                value: controller.totalAmount.value,
                icon: Icons.account_balance_wallet,
              ),
              _metricCard(
                title: 'This Month',
                value: controller.thisMonthAmount.value,
                icon: Icons.calendar_month,
              ),

              const SizedBox(height: 24),

              // ================= CATEGORY =================
              const Text(
                'Category Split',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              controller.categoryTotals.isEmpty
                  ? _emptyState(
                      Icons.pie_chart_outline,
                      'Add expenses to see category insights',
                    )
                  : CategoryPieChart(
                      data: Map<String, double>.from(
                        controller.categoryTotals,
                      ),
                    ),

              const SizedBox(height: 32),

              // ================= MONTHLY =================
              const Text(
                'Monthly Spend Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              controller.monthlyTotals.isEmpty
                  ? _emptyState(
                      Icons.bar_chart,
                      'Add expenses to track monthly trends',
                    )
                  : MonthlyBarChart(
                      monthlyTotals: Map<String, double>.from(
                        controller.monthlyTotals,
                      ),
                    ),

              const SizedBox(height: 32),

              // ================= VIEW ALL =================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('View All Expenses'),
                  onPressed: () {
                    Get.toNamed('/personal-expense-list');
                  },
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ================= UI HELPERS =================

  Widget _metricCard({
    required String title,
    required double value,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Colors.blue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 4),
              Text(
                '₹ ${value.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
