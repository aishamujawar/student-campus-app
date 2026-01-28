import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/calendar_service.dart';
import '../../services/assignment_service.dart';
import '../../services/timetable_service.dart';
import '../../models/assignment_model.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final CalendarService _calendarService = CalendarService();
  final AssignmentService _assignmentService = AssignmentService();
  final TimetableService _timetableService = TimetableService();
  
  DateTime _focusedMonth = DateTime.now();
  DateTime _selectedDate = DateTime.now();
  
  bool _loading = true;
  bool _isEditMode = false;
  bool _isEraserActive = false;
  
  CalendarCategory? _activeCategory;
  final List<CalendarCategory> _categories = [];
  final Map<String, CalendarCategory> _coloredDays = {};
  
  // Real data instead of mock
  Map<String, int> _assignmentsPerDay = {};
  int _todayClassCount = 0;
  
  // Default system categories to seed on first run
  final List<CalendarCategory> _defaultSystemCategories = [
    CalendarCategory(
      id: 'exam',
      name: 'Exam',
      color: const Color(0xFFD32F2F),
      isSystem: true,
    ),
    CalendarCategory(
      id: 'holiday',
      name: 'Holiday',
      color: const Color(0xFF388E3C),
      isSystem: true,
    ),
    CalendarCategory(
      id: 'assignment',
      name: 'Assignment',
      color: const Color(0xFF1976D2),
      isSystem: true,
    ),
    CalendarCategory(
      id: 'event',
      name: 'Event',
      color: const Color(0xFFF57C00),
      isSystem: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCalendarData();
  }

  Future<void> _loadCalendarData() async {
    // Load categories from Firebase
    var categories = await _calendarService.loadCategories();

    // 🔑 SEED DEFAULT CATEGORIES ON FIRST RUN
    if (categories.isEmpty) {
      for (final cat in _defaultSystemCategories) {
        await _calendarService.saveCategory(
          CalendarCategoryModel(
            id: cat.id,
            name: cat.name,
            color: cat.color,
            isSystem: true,
          ),
        );
      }

      // Reload after seeding
      categories = await _calendarService.loadCategories();
    }

    final days = await _calendarService.loadColoredDays();
    final assignments = await _assignmentService.getAssignmentCountByDate();
    
    // Load today's classes count
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Normalize date
    final dayIndex = today.weekday - 1; // Dart: 1=Mon, 7=Sun → 0=Mon, 6=Sun
    final classesToday = await _timetableService.getClassesForWeekday(dayIndex);

    setState(() {
      _categories
        ..clear()
        ..addAll(categories.map((c) => CalendarCategory(
              id: c.id,
              name: c.name,
              color: c.color,
              isSystem: c.isSystem,
            )));

      _coloredDays
        ..clear()
        ..addAll(days.map((k, v) => MapEntry(
              k,
              CalendarCategory(
                id: v.categoryId,
                name: v.categoryName,
                color: v.color,
              ),
            )));

      _assignmentsPerDay = assignments;
      _todayClassCount = classesToday.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                widthFactor: 0.85,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: _loading ? _buildLoading() : _card(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
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
        child: const CircularProgressIndicator(
          color: Color(0xFF3AA8F7),
        ),
      ),
    );
  }

  // =====================================================
  // MAIN CARD
  // =====================================================

  Widget _card(BuildContext context) {
    return Container(
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
          _header(),
          const SizedBox(height: 16),
          _todayCard(),
          const SizedBox(height: 18),
          _monthHeader(),
          const SizedBox(height: 12),
          // Show categories when in edit mode
          if (_isEditMode) ...[
            _categorySelector(),
            const SizedBox(height: 12),
          ],
          _calendarGrid(),
        ],
      ),
    );
  }

  // =====================================================
  // HEADER WITH EDIT/SAVE BUTTON
  // =====================================================

  Widget _header() => Row(
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
              Icons.calendar_month_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Calendar',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const Spacer(),
          // ✅ Updated with clearer text
          TextButton.icon(
            icon: Icon(
              _isEditMode ? Icons.save_rounded : Icons.edit_calendar_rounded,
              color: _isEditMode ? const Color(0xFF388E3C) : const Color(0xFF3AA8F7),
              size: 18,
            ),
            label: Text(
              _isEditMode ? 'Done marking' : 'Mark calendar',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _isEditMode ? const Color(0xFF388E3C) : const Color(0xFF3AA8F7),
              ),
            ),
            onPressed: () {
              setState(() {
                _isEditMode = !_isEditMode;
                _activeCategory = null;
                _isEraserActive = false;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  // =====================================================
  // TODAY SUMMARY CARD
  // =====================================================

  Widget _todayCard() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day); // Normalized date
    final todayKey = DateFormat('yyyy-MM-dd').format(today); // Use normalized date
    final assignmentsToday = _assignmentsPerDay[todayKey] ?? 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Today • ${DateFormat('EEE, dd MMM').format(now)}', // Display actual datetime
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _TodayStat(
                  icon: Icons.schedule,
                  label: 'Classes',
                  value: _todayClassCount.toString(), // ✅ Real data
                ),
              ),
              Expanded(
                child: _TodayStat(
                  icon: Icons.assignment,
                  label: 'Assignments',
                  value: assignmentsToday > 0 ? '$assignmentsToday due' : 'None',
                ),
              ),
              Expanded(
                child: _TodayStat(
                  icon: Icons.flag_outlined,
                  label: 'Mode',
                  value: _isEditMode ? 'Editing' : 'Viewing',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =====================================================
  // MONTH HEADER
  // =====================================================

  Widget _monthHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () {
              setState(() {
                _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month - 1);
              });
            },
          ),
          Text(
            DateFormat('MMMM yyyy').format(_focusedMonth),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () {
              setState(() {
                _focusedMonth =
                    DateTime(_focusedMonth.year, _focusedMonth.month + 1);
              });
            },
          ),
        ],
      );

  // =====================================================
  // CATEGORY SELECTOR (like Timetable subjects)
  // =====================================================

  Widget _categorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select category',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Eraser chip
              _CategoryChip(
                category: CalendarCategory(
                  id: 'eraser',
                  name: 'Eraser',
                  color: Colors.grey,
                  isSystem: false,
                ),
                isActive: _isEraserActive,
                onTap: () {
                  setState(() {
                    _isEraserActive = !_isEraserActive;
                    _activeCategory = null;
                  });
                },
                onRename: null,
                onDelete: null,
              ),
              const SizedBox(width: 8),
              ..._categories.map((category) => _CategoryChip(
                category: category,
                isActive: _activeCategory?.id == category.id,
                onTap: () {
                  setState(() {
                    _isEraserActive = false;
                    _activeCategory = _activeCategory?.id == category.id 
                      ? null 
                      : category;
                  });
                },
                onRename: category.isSystem ? null : () => _renameCategory(category),
                onDelete: category.isSystem ? null : () => _deleteCategory(category),
              )),
              const SizedBox(width: 8),
              // Add new category button
              _AddCategoryChip(
                onTap: () => _showAddCategoryDialog(),
              ),
            ],
          ),
        ),
        if (_activeCategory != null) ...[
          const SizedBox(height: 8),
          Text(
            'Tap dates to mark as "${_activeCategory!.name}"',
            style: TextStyle(
              fontSize: 11,
              color: _activeCategory!.color,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        if (_isEraserActive) ...[
          const SizedBox(height: 8),
          const Text(
            'Tap dates to remove category',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  // =====================================================
  // CALENDAR GRID
  // =====================================================

  Widget _calendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    
    final startOffset = firstDay.weekday - 1; // Monday-first

    final totalCells = startOffset + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final cellCount = rows * 7;

    // Find which row contains today
    final today = DateTime.now();
    final todayDay = today.day;
    final todayIndex = startOffset + todayDay - 1;
    final todayRow = todayIndex ~/ 7;

    return Column(
      children: [
        _weekdayRow(),
        const SizedBox(height: 8),
        
        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            mainAxisExtent: 34,
          ),
          itemBuilder: (context, index) {
            final rowIndex = index ~/ 7;
            final isTodayWeek = rowIndex == todayRow;

            // If this cell is before the first day of month
            if (index < startOffset) {
              final prevMonthLastDay = DateTime(_focusedMonth.year, _focusedMonth.month, 0);
              final prevMonthDay = prevMonthLastDay.day - (startOffset - index) + 1;
              final prevMonthDate = DateTime(
                prevMonthLastDay.year,
                prevMonthLastDay.month,
                prevMonthDay,
              );
              
              return _CalendarDay(
                day: prevMonthDay,
                date: prevMonthDate,
                isCurrentMonth: false,
                isToday: _isSameDay(prevMonthDate, DateTime.now()),
                isSelected: _isSameDay(prevMonthDate, _selectedDate),
                assignmentsCount: _getAssignmentsCount(prevMonthDate),
                isTodayWeek: false,
                category: _coloredDays[DateFormat('yyyy-MM-dd').format(prevMonthDate)] ?? _getAutoAssignmentCategory(prevMonthDate),
                isEditMode: _isEditMode,
                isOverdue: _isOverdue(prevMonthDate),
                onTap: () => _handleDayTap(prevMonthDate),
              );
            }
            
            // If this cell is after the last day of month
            if (index >= startOffset + daysInMonth) {
              final nextMonthDay = index - startOffset - daysInMonth + 1;
              final nextMonthDate = DateTime(
                _focusedMonth.year,
                _focusedMonth.month + 1,
                nextMonthDay,
              );
              
              return _CalendarDay(
                day: nextMonthDay,
                date: nextMonthDate,
                isCurrentMonth: false,
                isToday: _isSameDay(nextMonthDate, DateTime.now()),
                isSelected: _isSameDay(nextMonthDate, _selectedDate),
                assignmentsCount: _getAssignmentsCount(nextMonthDate),
                isTodayWeek: false,
                category: _coloredDays[DateFormat('yyyy-MM-dd').format(nextMonthDate)] ?? _getAutoAssignmentCategory(nextMonthDate),
                isEditMode: _isEditMode,
                isOverdue: _isOverdue(nextMonthDate),
                onTap: () => _handleDayTap(nextMonthDate),
              );
            }

            // Current month's days
            final day = index - startOffset + 1;
            final date = DateTime(
              _focusedMonth.year,
              _focusedMonth.month,
              day,
            );

            return _CalendarDay(
              day: day,
              date: date,
              isCurrentMonth: true,
              isToday: _isSameDay(date, DateTime.now()),
              isSelected: _isSameDay(date, _selectedDate),
              assignmentsCount: _getAssignmentsCount(date),
              isTodayWeek: isTodayWeek,
              category: _coloredDays[DateFormat('yyyy-MM-dd').format(date)] ?? _getAutoAssignmentCategory(date),
              isEditMode: _isEditMode,
              isOverdue: _isOverdue(date),
              onTap: () => _handleDayTap(date),
            );
          },
        ),
      ],
    );
  }

  // =====================================================
  // DAY TAP HANDLER
  // =====================================================

  Future<void> _handleDayTap(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    
    if (_isEditMode) {
      // Edit mode: Apply/remove category
      setState(() {
        if (_isEraserActive) {
          _coloredDays.remove(dateKey);
        } else if (_activeCategory != null) {
          _coloredDays[dateKey] = _activeCategory!;
        }
      });

      // Save to Firebase
      if (_isEraserActive) {
        await _calendarService.clearDay(date);
      } else if (_activeCategory != null) {
        await _calendarService.setDayCategory(
          date: date,
          category: CalendarCategoryModel(
            id: _activeCategory!.id,
            name: _activeCategory!.name,
            color: _activeCategory!.color,
            isSystem: _activeCategory!.isSystem,
          ),
        );
      }
      return;
    } else {
      // View mode: Open bottom sheet
      setState(() => _selectedDate = date);
      _openDaySheet(date);
    }
  }

  // =====================================================
  // WEEKDAY ROW
  // =====================================================

  Widget _weekdayRow() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 7,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 4,
        mainAxisSpacing: 0,
        mainAxisExtent: 24,
      ),
      itemBuilder: (context, index) {
        final isSunday = index == 6;
        final isSaturday = index == 5;

        return Center(
          child: Text(
            labels[index],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSunday
                  ? const Color(0xFFEF5350)
                  : isSaturday
                      ? const Color(0xFF9AA6B5)
                      : const Color(0xFF7A8A9C),
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // DAY BOTTOM SHEET (FIXED VERSION)
  // =====================================================

  void _openDaySheet(DateTime date) async {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    final assignments = _assignmentsPerDay[dateKey] ?? 0;
    final isToday = _isSameDay(date, DateTime.now());
    final category = _coloredDays[dateKey];
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: FutureBuilder<List<Map<String, String>>>(
              future: _timetableService.getClassesForWeekday(date.weekday - 1),
              builder: (context, classesSnapshot) {
                return FutureBuilder<List<Assignment>>(
                  future: _assignmentService.getAssignmentsForDate(date),
                  builder: (context, assignmentsSnapshot) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            height: 4,
                            width: 36,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0E6F0),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              DateFormat('EEEE, dd MMM').format(date),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (category != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: category.color.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: category.color,
                                  ),
                                ),
                              ),
                            ],
                            if (isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3AA8F7).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3AA8F7),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // ✅ FIXED: Classes section with unified bullet layout
                        _DayEvent(
                          icon: Icons.schedule,
                          iconColor: const Color(0xFF4CBBD1),
                          title: 'Classes',
                          items: !classesSnapshot.hasData
                              ? const ['Loading classes…']
                              : classesSnapshot.data!.isEmpty
                                  ? const ['No classes scheduled.']
                                  : classesSnapshot.data!
                                      .map((c) => '${c['subject']} (${c['start']}–${c['end']})')
                                      .toList(),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // ✅ FIXED: Assignments section with strike-through + unified layout
                        _DayEvent(
                          icon: Icons.assignment,
                          iconColor: const Color(0xFFF7B13A),
                          title: 'Assignments',
                          items: !assignmentsSnapshot.hasData
                              ? const ['Loading assignments…']
                              : assignmentsSnapshot.data!.isEmpty
                                  ? const ['No assignments due.']
                                  : assignmentsSnapshot.data!.map((a) {
                                      final isDone = a.status == AssignmentStatus.submitted;
                                      return isDone
                                          ? '${a.title} • ${a.subject} (Submitted)'
                                          : '${a.title} • ${a.subject}';
                                    }).toList(),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // ✅ Calendar info section
                        _DayEvent(
                          icon: Icons.edit_calendar_outlined,
                          iconColor: const Color(0xFF3AA8F7),
                          title: 'Calendar',
                          items: const ['Enter edit mode to mark exam weeks, holidays, etc.'],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        if (assignments > 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7B13A).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '⚠️ Don\'t forget to submit your assignments!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFF7B13A),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  // =====================================================
  // ADD CATEGORY DIALOG
  // =====================================================

  Future<void> _showAddCategoryDialog() async {
    final nameController = TextEditingController();
    
    // ✅ Reduced to only 4 timetable colors
    final List<Color> availableColors = const [
      Color(0xFF2877E0), // Strong blue (focus / academic)
      Color(0xFF7B7CFF), // Indigo-violet (projects)
      Color(0xFF55D7C7), // Teal (activities)
      Color(0xFFB0A8FF), // Soft lavender (personal / misc)
    ];
    
    Color selectedColor = availableColors[_categories.length % availableColors.length];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Add category'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Category name',
                      hintText: 'e.g., Midterm, Vacation, Project',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Colour',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: availableColors.map((color) {
                      final isSelected = color == selectedColor;
                      return GestureDetector(
                        onTap: () {
                          setStateDialog(() {
                            selectedColor = color;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.black54,
                                    width: 1.6,
                                  )
                                : null,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      final newCategory = CalendarCategory(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameController.text.trim(),
        color: selectedColor,
        isSystem: false,
      );

      setState(() {
        _categories.add(newCategory);
      });

      // Save to Firebase
      await _calendarService.saveCategory(
        CalendarCategoryModel(
          id: newCategory.id,
          name: newCategory.name,
          color: newCategory.color,
          isSystem: false,
        ),
      );
    }
  }

  // =====================================================
  // CATEGORY MANAGEMENT
  // =====================================================

  Future<void> _renameCategory(CalendarCategory category) async {
    final controller = TextEditingController(text: category.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Rename category'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isEmpty) return;
              Navigator.pop(context, true);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        final index = _categories.indexWhere((c) => c.id == category.id);
        _categories[index] = category.copyWith(name: controller.text.trim());
      });

      // Save to Firebase
      await _calendarService.saveCategory(
        CalendarCategoryModel(
          id: category.id,
          name: controller.text.trim(),
          color: category.color,
          isSystem: category.isSystem,
        ),
      );
    }
  }

  Future<void> _deleteCategory(CalendarCategory category) async {
    setState(() {
      _categories.removeWhere((c) => c.id == category.id);
      _coloredDays.removeWhere(
        (key, value) => value.id == category.id,
      );
      if (_activeCategory?.id == category.id) {
        _activeCategory = null;
      }
    });

    // Delete from Firebase
    await _calendarService.deleteCategory(category.id);
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  int _getAssignmentsCount(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    return _assignmentsPerDay[key] ?? 0;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isOverdue(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    final count = _assignmentsPerDay[key] ?? 0;

    if (count == 0) return false;
    return date.isBefore(DateTime.now()) &&
        !_isSameDay(date, DateTime.now());
  }

  CalendarCategory? _getAutoAssignmentCategory(DateTime date) {
    final key = DateFormat('yyyy-MM-dd').format(date);
    if (_coloredDays.containsKey(key)) return null;

    final count = _assignmentsPerDay[key] ?? 0;
    if (count == 0) return null;

    for (final c in _categories) {
      if (c.id == 'assignment') return c;
    }

    return null;
  }
}

// =====================================================
// DATA MODELS
// =====================================================

class CalendarCategory {
  final String id;
  final String name;
  final Color color;
  final bool isSystem;

  CalendarCategory({
    required this.id,
    required this.name,
    required this.color,
    this.isSystem = false,
  });

  CalendarCategory copyWith({String? name}) {
    return CalendarCategory(
      id: id,
      name: name ?? this.name,
      color: color,
      isSystem: isSystem,
    );
  }
}

// =====================================================
// CALENDAR DAY WIDGET
// =====================================================

class _CalendarDay extends StatelessWidget {
  final int day;
  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
  final bool isSelected;
  final int assignmentsCount;
  final bool isTodayWeek;
  final CalendarCategory? category;
  final bool isEditMode;
  final bool isOverdue;
  final VoidCallback onTap;

  const _CalendarDay({
    required this.day,
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
    required this.isSelected,
    required this.assignmentsCount,
    required this.isTodayWeek,
    required this.category,
    required this.isEditMode,
    required this.isOverdue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Background color logic
    Color backgroundColor;
    
    // Category color takes highest priority
    if (category != null) {
      backgroundColor = category!.color.withOpacity(0.35);
    } else if (isSelected) {
      backgroundColor = const Color(0xFF3AA8F7);
    } else if (isTodayWeek && isCurrentMonth) {
      backgroundColor = const Color(0xFF3AA8F7).withOpacity(0.16);
    } else if (assignmentsCount >= 3) {
      backgroundColor = const Color(0xFFF7B13A);
    } else if (assignmentsCount == 2) {
      backgroundColor = const Color(0xFFF7B13A).withOpacity(0.45);
    } else if (assignmentsCount == 1) {
      backgroundColor = const Color(0xFFF7B13A).withOpacity(0.28);
    } else if (!isCurrentMonth) {
      backgroundColor = Colors.transparent;
    } else {
      backgroundColor = const Color(0xFFF0F4FA);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(6),
          border: isOverdue
              ? Border.all(color: Colors.red, width: 1.6)
              : isToday
                  ? Border.all(color: const Color(0xFF3AA8F7), width: 1.5)
                  : null,
        ),
        alignment: Alignment.center,
        child: Text(
          '$day',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
            // ✅ Fixed text color logic - white on colored days
            color: category != null
                ? Colors.white
                : isSelected
                    ? Colors.white
                    : isCurrentMonth
                        ? const Color(0xFF16222C)
                        : const Color(0xFF7A8A9C).withOpacity(0.5),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// CATEGORY CHIP WIDGET
// =====================================================

class _CategoryChip extends StatelessWidget {
  final CalendarCategory category;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;

  const _CategoryChip({
    required this.category,
    required this.isActive,
    required this.onTap,
    this.onRename,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: category.isSystem ? null : onRename,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? category.color.withOpacity(0.2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? category.color : Colors.grey.shade300,
            width: isActive ? 2 : 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: category.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? category.color : const Color(0xFF16222C),
              ),
            ),
            // Delete button for custom categories
            if (!category.isSystem && onDelete != null) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Color(0xFF9AA6B5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ADD CATEGORY CHIP
// =====================================================

class _AddCategoryChip extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE0E6F0),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 14,
              color: Color(0xFF3AA8F7),
            ),
            const SizedBox(width: 4),
            Text(
              'Add',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// SMALL WIDGETS
// =====================================================

class _DayEventHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;

  const _DayEventHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _DayEvent extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final List<String> items;

  const _DayEvent({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              ...items.map((item) {
                final isSubmitted = item.contains('(Submitted)');

                if (!isSubmitted) {
                  return Text(
                    '• $item',
                    style: const TextStyle(
                      color: Color(0xFF7A8A9C),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  );
                }

                // Split "Title • Subject (Submitted)"
                final baseText = item.replaceAll(' (Submitted)', '');

                return RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '• ',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF7A8A9C),
                        ),
                      ),
                      TextSpan(
                        text: baseText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.grey,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const TextSpan(
                        text: ' (Submitted)',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.grey,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodayStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TodayStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3AA8F7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Color(0xFF7A8A9C),
          ),
        ),
      ],
    );
  }
}