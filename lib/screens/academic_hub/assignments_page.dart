import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/assignment_service.dart';
import '../../services/timetable_service.dart';
import '../../models/assignment_model.dart';

// =====================================================
// ASSIGNMENTS PAGE (PREMIUM FEATURES)
// =====================================================

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => _AssignmentsPageState();
}

class _AssignmentsPageState extends State<AssignmentsPage> {
  // =====================================================
  // STATE
  // =====================================================

  int _sortType = 0;   // 0 urgency, 1 due date, 2 subject
  int _filterType = 0; // 0 all, 1 pending, 2 submitted
  String? _selectedSubject;

  final List<Assignment> _assignments = [];
  final Map<String, bool> _expanded = {};
  final AssignmentService _service = AssignmentService();
  final TimetableService _timetableService = TimetableService();
  List<String> _timetableSubjects = [];

  // =====================================================
  // INIT
  // =====================================================

  @override
  void initState() {
    super.initState();
    _loadAssignments();
    _loadSubjects();
  }

  // =====================================================
  // FIREBASE INTEGRATION
  // =====================================================

  Future<void> _loadAssignments() async {
    try {
      final data = await _service.fetchAssignments();
      setState(() {
        _assignments.clear();
        _assignments.addAll(data);
      });
    } catch (e) {
      print('Error loading assignments: $e');
    }
  }

  Future<void> _loadSubjects() async {
    try {
      final subjects = await _timetableService.fetchSubjects();
      setState(() {
        _timetableSubjects = subjects;
      });
    } catch (e) {
      print('Error loading subjects: $e');
    }
  }

  Future<void> _saveAssignment(Assignment assignment) async {
    try {
      await _service.updateAssignment(assignment);
    } catch (e) {
      print('Error saving assignment: $e');
      // Show error snackbar in production
    }
  }

  Future<void> _deleteAssignment(String id) async {
    try {
      await _service.deleteAssignment(id);
      setState(() {
        _assignments.removeWhere((x) => x.id == id);
      });
    } catch (e) {
      print('Error deleting assignment: $e');
    }
  }

  // =====================================================
  // SORT + FILTER LOGIC
  // =====================================================

  List<Assignment> get _visibleAssignments {
    List<Assignment> list = [..._assignments];

    if (_filterType == 1) {
      list = list
          .where((a) => a.status != AssignmentStatus.submitted)
          .toList();
    } else if (_filterType == 2) {
      list = list
          .where((a) => a.status == AssignmentStatus.submitted)
          .toList();
    }

    if (_selectedSubject != null && _selectedSubject != 'All') {
      list = list.where((a) => a.subject == _selectedSubject).toList();
    }

    if (_sortType == 0) {
      list.sort((a, b) => a.urgencyScore.compareTo(b.urgencyScore));
    } else if (_sortType == 1) {
      list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } else {
      list.sort((a, b) => a.subject.compareTo(b.subject));
    }

    return list;
  }

  // =====================================================
  // LABEL GETTERS FOR DROPDOWNS
  // =====================================================

  String get _sortLabel {
    switch (_sortType) {
      case 1:
        return 'Due Date';
      case 2:
        return 'Subject';
      default:
        return 'Urgency';
    }
  }

  String get _filterLabel {
    switch (_filterType) {
      case 1:
        return 'Pending';
      case 2:
        return 'Submitted';
      default:
        return 'All';
    }
  }

  // =====================================================
  // STATUS TEXT HELPER
  // =====================================================

  String _statusText(AssignmentStatus status) {
    switch (status) {
      case AssignmentStatus.notStarted:
        return 'Not Started';
      case AssignmentStatus.inProgress:
        return 'In Progress';
      case AssignmentStatus.submitted:
        return 'Submitted';
    }
  }

  // =====================================================
  // CALENDAR HEATMAP HELPERS
  // =====================================================

  Map<DateTime, int> get _assignmentDensity {
    final map = <DateTime, int>{};

    for (final a in _assignments) {
      final day = DateTime(a.dueDate.year, a.dueDate.month, a.dueDate.day);
      map[day] = (map[day] ?? 0) + 1;
    }
    return map;
  }

  // =====================================================
  // WEEKLY WORKLOAD INSIGHT
  // =====================================================

  int get _thisWeekLoad {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));

    return _assignments.where((a) {
      return a.dueDate.isAfter(start.subtract(const Duration(days: 1))) &&
             a.dueDate.isBefore(end.add(const Duration(days: 1))) &&
             a.status != AssignmentStatus.submitted;
    }).length;
  }

  // =====================================================
  // SUBMISSION SNACKBAR (POLISHED WITH TWO ACTIONS)
  // =====================================================

  void _showSubmissionSnack(Assignment a) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 5),
        content: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: Color(0xFF3AA8F7),
                    size: 26,
                  ),
                  const SizedBox(width: 14),

                  /// TEXT
                  const Expanded(
                    child: Text(
                      'Progress is complete.\nSubmit this assignment?',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: Color(0xFF16222C),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  /// ACTIONS
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        child: const Text(
                          'Not yet',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF7A8A9C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            final index =
                                _assignments.indexWhere((x) => x.id == a.id);
                            _assignments[index] = a.copyWith(
                              status: AssignmentStatus.submitted,
                              progress: 100,
                            );
                          });
                          _saveAssignment(_assignments.firstWhere((x) => x.id == a.id));
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3AA8F7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // UI
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE7F2FF), Color(0xFFD8F7F8)],
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
                  child: _card(),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3AA8F7),
        onPressed: _openAddSheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _card() => Container(
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
            _controlRow(),
            const SizedBox(height: 16),
            _calendarHeatmap(),
            const SizedBox(height: 12),
            _weeklyInsight(),
            const SizedBox(height: 24),
            if (_visibleAssignments.isEmpty)
              _emptyState()
            else
              ..._visibleAssignments.map(_assignmentTile),
          ],
        ),
      );

  // =====================================================
  // HEADER
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
              Icons.assignment_rounded,
              size: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Assignments',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );

  // =====================================================
  // CONTROL ROW WITH NATIVE DROPDOWNS
  // =====================================================

  Widget _controlRow() {
    return Row(
      children: [
        _dropdownButton(
          label: 'Sort',
          valueText: _sortLabel,
          items: const ['Urgency', 'Due Date', 'Subject'],
          onChanged: (v) => setState(() => _sortType = v),
        ),
        const SizedBox(width: 8),
        _dropdownButton(
          label: 'Filter',
          valueText: _filterLabel,
          items: const ['All', 'Pending', 'Submitted'],
          onChanged: (v) => setState(() => _filterType = v),
        ),
        const SizedBox(width: 8),
        _subjectDropdown(),
      ],
    );
  }

  Widget _dropdownButton({
    required String label,
    required String valueText,
    required List<String> items,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8A9C),
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: items.indexOf(valueText),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16222C),
              ),
              items: List.generate(items.length, (i) {
                return DropdownMenuItem<int>(
                  value: i,
                  child: Text(items[i]),
                );
              }),
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _subjectDropdown() {
    final subjects = _timetableSubjects;
    
    // If no subjects exist yet, show disabled state
    if (subjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E6F0)),
        ),
        child: const Row(
          children: [
            Text(
              'Subject: All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF7A8A9C),
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF7A8A9C)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E6F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Subject: ',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8A9C),
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject ?? 'All',
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF16222C),
              ),
              items: [
                const DropdownMenuItem(
                  value: 'All',
                  child: Text('All'),
                ),
                ...subjects.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value == 'All' ? null : value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // CALENDAR HEATMAP
  // =====================================================

  Widget _calendarHeatmap() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'This Month',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(daysInMonth, (i) {
            final day = firstDay.add(Duration(days: i));
            final count = _assignmentDensity[day] ?? 0;

            Color color;
            if (count == 0) {
              color = const Color(0xFFE0E6F0);
            } else if (count == 1) {
              color = const Color(0xFFB6E3FF);
            } else {
              color = const Color(0xFF3AA8F7);
            }

            return Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 10,
                    color: count == 0 ? Colors.black54 : Colors.white,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // =====================================================
  // WEEKLY INSIGHT (CLEAN TEXT-ONLY)
  // =====================================================

  Widget _weeklyInsight() {
    String text;
    Color color;

    if (_thisWeekLoad == 0) {
      text = 'No deadlines this week';
      color = Colors.green;
    } else if (_thisWeekLoad <= 2) {
      text = 'Light workload this week';
      color = Colors.orange;
    } else {
      text = 'Heavy workload this week';
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // =====================================================
  // ASSIGNMENT TILE (WITH ANIMATED PROGRESS)
  // =====================================================

  Widget _assignmentTile(Assignment a) {
    final expanded = _expanded[a.id] ?? false;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: a.progress == 100
            ? const Color(0xFFEAF6FF) // soft blue glow
            : const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(24),
        boxShadow: a.progress == 100
            ? [
                BoxShadow(
                  color: const Color(0xFF3AA8F7).withOpacity(0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  a.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              if (a.status != AssignmentStatus.submitted)
                _urgencyChip(a),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            a.subject,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A8A9C),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusChip(a),
              const Spacer(),
              GestureDetector(
                onTap: () =>
                    setState(() => _expanded[a.id] = !expanded),
                child: Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: const Color(0xFF7A8A9C),
                ),
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 16),
            Text(
              a.description,
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            Text(
              'Due: ${DateFormat('dd MMM yyyy').format(a.dueDate)}',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF7A8A9C),
              ),
            ),
            const SizedBox(height: 16),
            if (a.status != AssignmentStatus.submitted) ...[
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7A8A9C),
                ),
              ),
              const SizedBox(height: 8),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                    elevation: 2,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                ),
                child: Slider(
                  value: a.progress.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 20,
                  label: '${a.progress}%',
                  activeColor: _getProgressColor(a.progress),
                  inactiveColor: const Color(0xFFE0E6F0),
                  onChanged: (value) {
                    final newProgress = value.round();
                    final index = _assignments.indexWhere((x) => x.id == a.id);

                    setState(() {
                      _assignments[index] = a.copyWith(progress: newProgress);

                      if (newProgress == 0) {
                        _assignments[index] = _assignments[index].copyWith(
                          status: AssignmentStatus.notStarted,
                        );
                      } else if (newProgress < 100) {
                        _assignments[index] = _assignments[index].copyWith(
                          status: AssignmentStatus.inProgress,
                        );
                      }
                    });

                    _saveAssignment(_assignments[index]);

                    if (newProgress == 100 &&
                        a.status != AssignmentStatus.submitted) {
                      _showSubmissionSnack(a);
                    }
                  },
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '0%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A8A9C),
                    ),
                  ),
                  Text(
                    '${a.progress}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3AA8F7),
                    ),
                  ),
                  const Text(
                    '100%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF7A8A9C),
                    ),
                  ),
                ],
              ),
              
              // SUBMIT BUTTON (appears when progress is 100% but not submitted)
              if (a.progress == 100 &&
                  a.status != AssignmentStatus.submitted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        final index = _assignments.indexWhere((x) => x.id == a.id);
                        _assignments[index] = a.copyWith(
                          status: AssignmentStatus.submitted,
                        );
                      });
                      _saveAssignment(_assignments.firstWhere((x) => x.id == a.id));
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3AA8F7)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Submit Assignment',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3AA8F7),
                      ),
                    ),
                  ),
                ),
              ],

              // DELETE BUTTON (appears in expanded view)
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await _deleteAssignment(a.id);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Delete assignment',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Submitted (${DateFormat('dd MMM').format(a.dueDate)})',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () async {
                    await _deleteAssignment(a.id);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text(
                    'Delete assignment',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Color _getProgressColor(int progress) {
    if (progress < 30) return Colors.red;
    if (progress < 70) return Colors.orange;
    return Colors.green;
  }

  // =====================================================
  // CHIPS (WITH EDITABLE STATUS)
  // =====================================================

  Widget _statusChip(Assignment a) {
    Color color;
    String text = _statusText(a.status);

    switch (a.status) {
      case AssignmentStatus.notStarted:
        color = Colors.grey;
        break;
      case AssignmentStatus.inProgress:
        color = Colors.orange;
        break;
      case AssignmentStatus.submitted:
        color = Colors.green;
        break;
    }

    return GestureDetector(
      onTap: () => _openStatusPicker(a),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _urgencyChip(Assignment a) {
    final days = a.daysLeft;
    Color color;
    String text;

    if (days < 0) {
      color = Colors.red;
      text = 'Overdue';
    } else if (days == 0) {
      color = Colors.red;
      text = 'Due today';
    } else if (days == 1) {
      color = Colors.orange;
      text = '1 day left';
    } else if (days <= 2) {
      color = Colors.orange;
      text = '$days days left';
    } else {
      color = Colors.green;
      text = '$days days';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // =====================================================
  // STATUS PICKER BOTTOM SHEET
  // =====================================================

  void _openStatusPicker(Assignment a) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Update Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ...AssignmentStatus.values.map((status) {
                final selected = status == a.status;
                return ListTile(
                  title: Text(
                    _statusText(status),
                    style: TextStyle(
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                  trailing: selected
                      ? const Icon(Icons.check_rounded,
                          color: Color(0xFF3AA8F7))
                      : null,
                  onTap: () {
                    setState(() {
                      final index = _assignments.indexWhere((x) => x.id == a.id);
                      _assignments[index] = a.copyWith(
                        status: status,
                        progress: status == AssignmentStatus.submitted
                            ? 100
                            : status == AssignmentStatus.notStarted
                                ? 0
                                : a.progress == 0
                                    ? 50
                                    : a.progress,
                      );
                    });
                    _saveAssignment(_assignments.firstWhere((x) => x.id == a.id));
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================

  Widget _emptyState() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          children: [
            Icon(Icons.inbox_rounded,
                size: 48, color: Color(0xFF9AA6B5)),
            SizedBox(height: 12),
            Text(
              'No assignments yet',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6),
            Text(
              'Add assignments to track deadlines and progress.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF7A8A9C)),
            ),
          ],
        ),
      );

  // =====================================================
  // ADD ASSIGNMENT
  // =====================================================

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddAssignmentSheet(
        onAdd: () => _loadAssignments(),
        timetableSubjects: _timetableSubjects,
      ),
    );
  }
}

// =====================================================
// ADD ASSIGNMENT SHEET (WITH FIREBASE INTEGRATION)
// =====================================================

class _AddAssignmentSheet extends StatefulWidget {
  final VoidCallback onAdd;
  final List<String> timetableSubjects;
  
  const _AddAssignmentSheet({
    required this.onAdd,
    required this.timetableSubjects,
  });

  @override
  State<_AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends State<_AddAssignmentSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedSubject;
  DateTime? _dueDate;
  String? _errorText;

  Widget _dueDatePicker(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime(2100),
        );

        if (picked != null) {
          setState(() {
            _dueDate = picked;
            _errorText = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
            const SizedBox(width: 10),
            Text(
              _dueDate == null
                  ? 'Due Date'
                  : DateFormat('dd MMM yyyy').format(_dueDate!),
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                    _dueDate == null ? FontWeight.w500 : FontWeight.w700,
                color: _dueDate == null
                    ? const Color(0xFF7A8A9C)
                    : const Color(0xFF16222C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAssignment() async {
    if (_selectedSubject == null || _dueDate == null || _titleController.text.trim().isEmpty) {
      setState(() {
        _errorText = 'Please fill all required fields';
      });
      return;
    }

    try {
      final newAssignment = Assignment(
        id: '',
        subject: _selectedSubject!,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        dueDate: _dueDate!,
        status: AssignmentStatus.notStarted,
        progress: 0,
      );

      await AssignmentService().addAssignment(newAssignment);
      widget.onAdd();
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assignment added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding assignment: $e');
      setState(() {
        _errorText = 'Failed to add assignment: $e';
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subjects = widget.timetableSubjects;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
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
          const Text(
            'Add Assignment',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _titleController,
            onChanged: (value) => setState(() => _errorText = null),
            decoration: InputDecoration(
              labelText: 'Title',
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          subjects.isEmpty
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_rounded, color: Color(0xFF7A8A9C), size: 18),
                      SizedBox(width: 10),
                      Text(
                        'No subjects in timetable yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF7A8A9C),
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedSubject,
                  onChanged: (value) {
                    setState(() {
                      _selectedSubject = value;
                      _errorText = null;
                    });
                  },
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Select a subject'),
                    ),
                    ...subjects.map((subject) {
                      return DropdownMenuItem(
                        value: subject,
                        child: Text(subject),
                      );
                    }),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    filled: true,
                    fillColor: const Color(0xFFF4F7FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

          const SizedBox(height: 12),
          _dueDatePicker(context),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            onChanged: (value) => setState(() => _errorText = null),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              filled: true,
              fillColor: const Color(0xFFF4F7FB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          if (_errorText != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAssignment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3AA8F7),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Add Assignment',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}