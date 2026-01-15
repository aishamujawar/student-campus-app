import 'package:student_campus_app/services/timetable_service.dart';
import 'package:flutter/material.dart';
import 'dart:math';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {

  final TimetableService _timetableService = TimetableService();

  @override
  void initState() {
    super.initState();
    _loadTimetable();
  }

  Future<void> _loadTimetable() async {
    final data = await _timetableService.loadTimetable();
    if (data.isEmpty) return;

    setState(() {
      _timeSlots.clear();
      _subjects.clear();
      _scheduled.clear();

      final Map<String, int> subjectIndexMap = {};

      // ---- 1. Rebuild rows FIRST (by index)
      final rows = data.where((e) => e["type"] == "row").toList()
        ..sort((a, b) => a["rowIndex"].compareTo(b["rowIndex"]));

      for (final row in rows) {
        final startParts = row["startTime"].split(":");
        final endParts = row["endTime"].split(":");

        _timeSlots.add(
          TimeSlot(
            start: TimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1]),
            ),
            end: TimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1]),
            ),
          ),
        );
      }

      // ---- 2. Rebuild scheduled cells
      final cells = data.where((e) => e["type"] == "cell");

      for (final entry in cells) {
        final rowIndex = entry["rowIndex"];
        final dayIndex = entry["dayIndex"];
        final subjectId = entry["subjectId"];
        final subjectName = entry["subjectName"];

        if (!subjectIndexMap.containsKey(subjectId)) {
          final subject = Subject(
            id: subjectId,
            name: subjectName,
            color: _subjectColors[_subjects.length % _subjectColors.length],
          );
          _subjects.add(subject);
          subjectIndexMap[subjectId] = _subjects.length - 1;
        }

        final subject = _subjects[subjectIndexMap[subjectId]!];
        _scheduled["$rowIndex-$dayIndex"] = subject;
      }
    });
  }

  final List<String> _allDays = const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// Active days in the grid – start with Mon–Fri
  final List<String> _activeDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  final List<TimeSlot> _timeSlots = [];

  /// Subjects user creates
  final List<Subject> _subjects = [];

  /// Map of "rowIndex_dayIndex" → Subject
  final Map<String, Subject> _scheduled = {};

  bool _use24HourFormat = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFE7F2FF),
              Color(0xFFD8F7F8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
                  child: Container(
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(theme),
                        const SizedBox(height: 18),
                        _buildControls(theme),
                        const SizedBox(height: 14),
                        _buildTimetableGrid(theme),
                        const SizedBox(height: 18),
                        _buildSubjectsSection(theme),
                        const SizedBox(height: 12),
                        _buildDeleteArea(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------

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
                Color(0xFF4CBBD1),
                Color(0xFF57E4C9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.schedule_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Timetable',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Save',
          icon: const Icon(Icons.save_rounded),
          onPressed: () {
            print("SAVE BUTTON PRESSED");
            _saveTimetable();
          },
        ),
        IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),

      ],
    );
  }

  // ---------------- CONTROLS ----------------

  Widget _buildControls(ThemeData theme) {
    return Row(
      children: [
        Text(
          'Configure slots',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: const Color(0xFF7A8A9C),
          ),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _addTimeRow,
          icon: const Icon(Icons.add_rounded, size: 16),
          label: const Text('Add row'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 4),
        TextButton.icon(
          onPressed: _addDayColumn,
          icon: const Icon(Icons.view_column_rounded, size: 16),
          label: const Text('Add column'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 8),
        _buildTimeFormatToggle(),
      ],
    );
  }

  Widget _buildTimeFormatToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _TimeFormatChip(
            label: '12h',
            selected: !_use24HourFormat,
            onTap: () {
              setState(() => _use24HourFormat = false);
            },
          ),
          const SizedBox(width: 4),
          _TimeFormatChip(
            label: '24h',
            selected: _use24HourFormat,
            onTap: () {
              setState(() => _use24HourFormat = true);
            },
          ),
        ],
      ),
    );
  }

  // ---------------- TIMETABLE GRID ----------------

  Widget _buildTimetableGrid(ThemeData theme) {
    final hasRows = _timeSlots.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: const Color(0xFFF4F7FB),
        border: Border.all(
          color: const Color(0xFFE0E6F0),
          width: 0.8,
        ),
      ),
      child: Column(
        children: [
          _buildGridHeader(theme),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E6F0)),
          if (!hasRows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
              child: Column(
                children: [
                  const Icon(
                    Icons.calendar_view_week_rounded,
                    size: 30,
                    color: Color(0xFF9AA6B5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No time slots yet',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4C5D73),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap "Add row" to start building your timetable.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF9AA6B5),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildGridBody(theme),
        ],
      ),
    );
  }

  Widget _buildGridHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              'Time',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF4C5D73),
              ),
            ),
          ),
          const SizedBox(width: 6),
          for (int i = 0; i < _activeDays.length; i++) ...[
            Expanded(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _activeDays[i].substring(0, 3),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF7A8A9C),
                      ),
                    ),
                    if (_activeDays[i] == 'Saturday' ||
                        _activeDays[i] == 'Sunday')
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0),
                        child: GestureDetector(
                          onTap: () => _removeDayColumn(i),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xFF9AA6B5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (i != _activeDays.length - 1)
              const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildGridBody(ThemeData theme) {
    return Column(
      children: List.generate(_timeSlots.length, (rowIndex) {
        final slot = _timeSlots[rowIndex];
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  // Time label + remove row icon
                  SizedBox(
                    width: 90,
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _editTimeSlot(rowIndex),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE0E6F0),
                                  width: 0.8,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _formatTime(slot.start),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF4C5D73),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(slot.end),
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      color: const Color(0xFF9AA6B5),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeTimeRow(rowIndex),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE7F2FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xFF9AA6B5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Day cells
                  for (int dayIndex = 0;
                      dayIndex < _activeDays.length;
                      dayIndex++) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _buildGridCell(rowIndex, dayIndex),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (rowIndex != _timeSlots.length - 1)
              const Divider(
                height: 1,
                thickness: 0.5,
                color: Color(0xFFE0E6F0),
              ),
          ],
        );
      }),
    );
  }

  Widget _buildGridCell(int rowIndex, int dayIndex) {
    final key = _cellKey(rowIndex, dayIndex);
    final subject = _scheduled[key];

    return DragTarget<DragPayload>(
      onWillAccept: (_) => true,
      onAccept: (payload) {
        setState(() {
          // If dragged from another cell, clear old cell
          if (payload.rowIndex != null && payload.dayIndex != null) {
            final oldKey =
                _cellKey(payload.rowIndex!, payload.dayIndex!);
            _scheduled.remove(oldKey);
          }
          _scheduled[key] = payload.subject;
        });
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 52,
          decoration: BoxDecoration(
            color: subject != null
                ? subject.color.withOpacity(0.18)
                : (isHighlight ? const Color(0xFFE0F3FF) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: subject != null
                  ? subject.color.withOpacity(0.8)
                  : const Color(0xFFE0E6F0),
              width: 0.9,
            ),
          ),
          child: subject == null
              ? const SizedBox.shrink()
              : Center(
                  child: Draggable<DragPayload>(
                    data: DragPayload(
                      subject: subject,
                      rowIndex: rowIndex,
                      dayIndex: dayIndex,
                    ),
                    feedback: Material(
                      color: Colors.transparent,
                      child: _SubjectPill(
                        subject: subject,
                        elevated: true,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: _SubjectPill(subject: subject),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 3),
                      child: Text(
                        subject.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF16222C),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  // ---------------- SUBJECTS SECTION ----------------

  Widget _buildSubjectsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subjects',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4C5D73),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Expanded(
                child: _subjects.isEmpty
                    ? Text(
                        'Add subjects and drag them into the timetable.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF9AA6B5),
                        ),
                      )
                    : SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _subjects.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final subject = _subjects[index];
                            return _buildSubjectChip(subject);
                          },
                        ),
                      ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _showAddSubjectDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectChip(Subject subject) {
    return Draggable<DragPayload>(
      data: DragPayload(subject: subject),
      feedback: Material(
        color: Colors.transparent,
        child: _SubjectPill(
          subject: subject,
          elevated: true,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _SubjectPill(subject: subject),
      ),
      child: _SubjectPill(
        subject: subject,
        onDelete: () => _confirmDeleteSubject(subject),
      ),
    );
  }

  // ---------------- DELETE AREA ----------------

  Widget _buildDeleteArea(ThemeData theme) {
    return DragTarget<DragPayload>(
      onWillAccept: (payload) => payload?.rowIndex != null,
      onAccept: (payload) {
        if (payload.rowIndex != null && payload.dayIndex != null) {
          final oldKey = _cellKey(payload.rowIndex!, payload.dayIndex!);
          setState(() {
            _scheduled.remove(oldKey);
          });
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isActive = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFFFF3F3)
                : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? const Color(0xFFEF5350)
                  : const Color(0xFFE0E6F0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: isActive
                    ? const Color(0xFFEF5350)
                    : const Color(0xFF9AA6B5),
              ),
              const SizedBox(width: 6),
              Text(
                'Drag a subject here to remove from timetable',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF7A8A9C),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- HELPERS ----------------

  /// Greatest common divisor of two ints
  int _gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    if (a == 0) return b;
    if (b == 0) return a;
    while (b != 0) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  /// Add minutes to a TimeOfDay, returning a new TimeOfDay. Clamps above 23:59.
  TimeOfDay _addMinutes(TimeOfDay t, int minutes) {
    final total = t.hour * 60 + t.minute + minutes;
    final clamped = total.clamp(0, 23 * 60 + 59) as int;
    final h = clamped ~/ 60;
    final m = clamped % 60;
    return TimeOfDay(hour: h, minute: m);
  }

  /// Compute suggested slot length in minutes using GCD of existing durations.
  /// Fallback to 60 (1 hour) if no slots exist. Minimum step is 15 minutes.
  int _suggestedSlotLengthMinutes({int considerLastN = 50}) {
    if (_timeSlots.isEmpty) return 60;

    // optionally consider only the last N slots (default large)
    final slotsToConsider = _timeSlots.takeLast(min(considerLastN, _timeSlots.length));

    final durations = slotsToConsider.map((s) {
      final startMin = s.start.hour * 60 + s.start.minute;
      final endMin = s.end.hour * 60 + s.end.minute;
      // treat negative as positive wrap; avoid zero
      final raw = endMin - startMin;
      final dur = raw > 0 ? raw : raw.abs();
      return dur == 0 ? 60 : dur; // avoid zero-length; default to 60
    }).toList();

    // gcd of list
    var g = durations.first;
    for (var i = 1; i < durations.length; i++) {
      g = _gcd(g, durations[i]);
    }

    // sensible lower bound (15 minutes).
    if (g < 15) g = 15;

    return g;
  }

  void _addTimeRow() {
    setState(() {
      if (_timeSlots.isEmpty) {
        _timeSlots.add(
          TimeSlot(
            start: const TimeOfDay(hour: 9, minute: 0),
            end: const TimeOfDay(hour: 10, minute: 0),
          ),
        );
        return;
      }

      final last = _timeSlots.last;
      final nextStart = last.end;

      // pick length (gcd heuristic) and set end = start + length
      final slotLengthMinutes = _suggestedSlotLengthMinutes();

      var nextEnd = _addMinutes(nextStart, slotLengthMinutes);

      // Safety: if nextEnd equals nextStart (very rare), fallback to 1 hour
      if (nextEnd.hour == nextStart.hour && nextEnd.minute == nextStart.minute) {
        nextEnd = _addMinutes(nextStart, 60);
      }

      // If nextEnd would equal or go before nextStart (clamp), try smaller granularity
      // (e.g., if last.end is 23:30 and slotLength pushes past midnight)
      final startTotal = nextStart.hour * 60 + nextStart.minute;
      final endTotal = nextEnd.hour * 60 + nextEnd.minute;
      if (endTotal <= startTotal) {
        // clamp to 23:59
        nextEnd = const TimeOfDay(hour: 23, minute: 59);
      }

      _timeSlots.add(TimeSlot(start: nextStart, end: nextEnd));
    });
  }

  void _removeTimeRow(int index) {
    if (index < 0 || index >= _timeSlots.length) return;
    setState(() {
      _timeSlots.removeAt(index);

      final newScheduled = <String, Subject>{};
      _scheduled.forEach((key, subject) {
        final parts = key.split('-');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);

        if (r == index) {
          // removed row
          return;
        }
        final newR = r > index ? r - 1 : r;
        newScheduled['$newR-$c'] = subject;
      });
      _scheduled
        ..clear()
        ..addAll(newScheduled);
    });
  }

  void _addDayColumn() {
    if (_activeDays.length >= _allDays.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All days are already visible.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      final nextDay =
          _allDays.firstWhere((day) => !_activeDays.contains(day));
      _activeDays.add(nextDay);
    });
  }

  void _removeDayColumn(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= _activeDays.length) return;
    final dayName = _activeDays[dayIndex];

    // Safety guard — only allow removing Saturday & Sunday
    if (dayName != 'Saturday' && dayName != 'Sunday') return;

    setState(() {
      _activeDays.removeAt(dayIndex);

      final newScheduled = <String, Subject>{};
      _scheduled.forEach((key, subject) {
        final parts = key.split('-');
        final r = int.parse(parts[0]);
        final c = int.parse(parts[1]);

        if (c == dayIndex) {
          // removed column
          return;
        }
        final newC = c > dayIndex ? c - 1 : c;
        newScheduled['$r-$newC'] = subject;
      });
      _scheduled
        ..clear()
        ..addAll(newScheduled);
    });
  }

  Future<void> _editTimeSlot(int index) async {
    final slot = _timeSlots[index];

    final start = await showTimePicker(
      context: context,
      initialTime: slot.start,
    );
    if (start == null) return;

    final end = await showTimePicker(
      context: context,
      initialTime: slot.end,
    );
    if (end == null) return;

    setState(() {
      _timeSlots[index] = TimeSlot(start: start, end: end);
    });
  }

  String _formatTime(TimeOfDay time) {
    if (_use24HourFormat) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else {
      final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
      final minute = time.minute.toString().padLeft(2, '0');
      final period = time.period == DayPeriod.am ? 'AM' : 'PM';
      return '$hour:$minute $period';
    }
  }

  String _cellKey(int rowIndex, int dayIndex) => '$rowIndex-$dayIndex';

  Future<void> _showAddSubjectDialog() async {
    final nameController = TextEditingController();
    Color selectedColor =
        _subjectColors[Random().nextInt(_subjectColors.length)];

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text('Add subject'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Subject name',
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
                    children: _subjectColors.map((color) {
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
                                    color: Colors.black54, width: 1.6)
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
      setState(() {
        _subjects.add(
          Subject(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: nameController.text.trim(),
            color: selectedColor,
          ),
        );
      });
    }
  }

  Future<void> _confirmDeleteSubject(Subject subject) async {
    final theme = Theme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete subject?',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'This will remove "${subject.name}" from your subjects list '
            'and clear it from the timetable. This action cannot be undone.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      setState(() {
        _subjects.removeWhere((s) => s.id == subject.id);
        _scheduled.removeWhere((key, value) => value.id == subject.id);
      });
    }
  }

  List<Color> get _subjectColors => const [
        // Saturated accents
        Color(0xFF2877E0), // strong blue
        Color(0xFF4B6BFF), // deep indigo
        Color(0xFF3AA8F7), // bright sky blue
        Color(0xFF55D7C7), // teal green
        Color(0xFF7B7CFF), // bluish violet

        // Softer / pastel accents
        Color(0xFF61C2FF), // lighter blue
        Color(0xFF6FE0F4), // lighter cyan
        Color(0xFF7BE6D9), // light aqua
        Color(0xFFB0A8FF), // soft lavender
        Color(0xFFDDF9F3), // very light mint
      ];

  List<Map<String, dynamic>> _buildTimetablePayload() {
    final List<Map<String, dynamic>> result = [];

    // Save ALL rows (even empty ones)
    for (int row = 0; row < _timeSlots.length; row++) {
      final slot = _timeSlots[row];

      result.add({
        "type": "row",
        "rowIndex": row,
        "startTime":
            "${slot.start.hour.toString().padLeft(2, '0')}:${slot.start.minute.toString().padLeft(2, '0')}",
        "endTime":
            "${slot.end.hour.toString().padLeft(2, '0')}:${slot.end.minute.toString().padLeft(2, '0')}",
      });
    }

    // Save scheduled subjects
    _scheduled.forEach((key, subject) {
      final parts = key.split('-');
      final row = int.parse(parts[0]);
      final col = int.parse(parts[1]);

      result.add({
        "type": "cell",
        "rowIndex": row,
        "dayIndex": col,
        "day": _activeDays[col],
        "subjectId": subject.id,
        "subjectName": subject.name,
      });
    });

    return result;
  }

  Future<void> _saveTimetable() async {
    final data = _buildTimetablePayload();

    print("TIMETABLE DATA TO SAVE: $data");

    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Timetable is empty")),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    await _timetableService.saveTimetable(data);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Timetable saved")),
    );
  }

}


// ---------------- MODELS & SMALL WIDGETS ----------------

class TimeSlot {
  final TimeOfDay start;
  final TimeOfDay end;

  TimeSlot({required this.start, required this.end});
}

class Subject {
  final String id;
  final String name;
  final Color color;

  Subject({
    required this.id,
    required this.name,
    required this.color,
  });
}

class DragPayload {
  final Subject subject;
  final int? rowIndex;
  final int? dayIndex;

  DragPayload({
    required this.subject,
    this.rowIndex,
    this.dayIndex,
  });
}

class _TimeFormatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TimeFormatChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3AA8F7) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF4C5D73),
          ),
        ),
      ),
    );
  }
}

class _SubjectPill extends StatelessWidget {
  final Subject subject;
  final bool elevated;
  final VoidCallback? onDelete;

  const _SubjectPill({
    required this.subject,
    this.elevated = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: subject.color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: subject.color,
          width: 1.1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: subject.color.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: subject.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            subject.name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF16222C),
            ),
          ),
          if (onDelete != null && !elevated) ...[
            const SizedBox(width: 4),
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
    );
  }
}

// ---------------- EXTENSIONS ----------------

extension _IterableHelpers<E> on Iterable<E> {
  /// Return the last [n] elements as an iterable. If [n] >= length, returns all elements.
  Iterable<E> takeLast(int n) sync* {
    if (n <= 0) return;
    final buffer = <E>[];
    for (final e in this) {
      buffer.add(e);
      if (buffer.length > n) buffer.removeAt(0);
    }
    for (final e in buffer) yield e;
  }
}