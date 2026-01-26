import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/personal_expense_controller.dart';
import '../screens/add_personal_expense_screen.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final controller = Get.find<PersonalExpenseController>();

  String? selectedCategory;
  DateTime? selectedMonth;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Expenses',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            items: ExpenseCategories.all
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedCategory = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<DateTime>(
            value: selectedMonth,
            decoration: const InputDecoration(
              labelText: 'Month',
              border: OutlineInputBorder(),
            ),
            items: _monthOptions()
                .map(
                  (d) => DropdownMenuItem(
                    value: d,
                    child: Text('${_monthName(d.month)} ${d.year}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedMonth = v),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    controller.clearFilters();
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    controller.applyFilters(
                      category: selectedCategory,
                      month: selectedMonth,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DateTime> _monthOptions() {
    final now = DateTime.now();
    return List.generate(
      12,
      (i) => DateTime(now.year, now.month - i, 1),
    );
  }

  String _monthName(int m) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[m - 1];
  }
}
