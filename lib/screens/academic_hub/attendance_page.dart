import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// =====================================================
// ATTENDANCE PAGE
// =====================================================

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {

  // ---------------- MODE ----------------
  bool _trackingMode = true;

  // ---------------- FIREBASE ----------------
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ---------------- DATE ----------------
  DateTime _selectedDate = DateTime.now();

  // ---------------- DAILY TRACKING ----------------
  bool _timetableMissing = false;
  bool _noClassesToday = false;
  final List<_TodayClass> _todayClasses = [];
  final Map<String, String> _attendance = {};

  // ---------------- CALCULATOR ----------------
  final _subjectController = TextEditingController();
  final _attendedController = TextEditingController();
  final _heldController = TextEditingController();

  final List<String> _days = const [
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
  ];

  final Map<String, int> _weeklySchedule = {};
  DateTime? _lastTeachingDay;

  int? _futureClasses;
  int? _mustAttend;
  int? _canBunk;

  int _baseHeld = 0;
  int _baseAttended = 0;

  int _simHeld = 0;
  int _simAttended = 0;

  // ---------------- ANIMATION ----------------
  late AnimationController _animController;
  late Animation<double> _percentAnim;
  double _oldPercent = 0;

  double get _simPercent =>
      _simHeld == 0 ? 0 : _simAttended / _simHeld;

  Color get _percentColor {
    if (_simPercent < 0.60) return const Color(0xFFEF5350);
    if (_simPercent < 0.75) return const Color(0xFFFFA726);
    return const Color(0xFF57E4C9);
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _percentAnim = const AlwaysStoppedAnimation(0);
    _loadDay();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // =====================================================
  // LOAD DAILY SCHEDULE (FIXED SUNDAY BEHAVIOR)
  // =====================================================

  Future<void> _loadDay() async {
    _todayClasses.clear();
    _attendance.clear();
    _timetableMissing = false;
    _noClassesToday = false;

    final uid = _auth.currentUser!.uid;
    final weekdayIndex = _selectedDate.weekday - 1;

    final rowsSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('timetable')
        .where('type', isEqualTo: 'row')
        .get();

    final cellsSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('timetable')
        .where('type', isEqualTo: 'cell')
        .where('dayIndex', isEqualTo: weekdayIndex)
        .get();

    // ---- timetable missing ONLY if no rows at all
    if (rowsSnap.docs.isEmpty) {
      setState(() => _timetableMissing = true);
      return;
    }

    // ---- no classes today (Sunday etc.)
    if (cellsSnap.docs.isEmpty) {
      setState(() => _noClassesToday = true);
      return;
    }

    for (final cell in cellsSnap.docs) {
      final row = rowsSnap.docs.firstWhere(
        (r) => r['rowIndex'] == cell['rowIndex'],
      );

      final classId =
          '${cell['subjectId']}_${cell['rowIndex']}_${cell['dayIndex']}';

      _todayClasses.add(
        _TodayClass(
          classId: classId,
          subjectName: cell['subjectName'],
          startTime: row['startTime'],
          endTime: row['endTime'],
        ),
      );
    }

    _todayClasses.sort((a, b) => a.startTime.compareTo(b.startTime));

    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final attSnap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(dateKey)
        .collection('records')
        .get();

    for (final d in attSnap.docs) {
      _attendance[d.id] = d['status'];
    }

    setState(() {});
  }

  // =====================================================
  // MARK ATTENDANCE
  // =====================================================

  Future<void> _mark(String classId, String status) async {
    final uid = _auth.currentUser!.uid;
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);

    setState(() => _attendance[classId] = status);

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('attendance')
        .doc(dateKey)
        .collection('records')
        .doc(classId)
        .set({'status': status});
  }

  // =====================================================
  // CALCULATOR LOGIC
  // =====================================================

  void _calculate() {
    _baseHeld = int.tryParse(_heldController.text) ?? 0;
    _baseAttended = int.tryParse(_attendedController.text) ?? 0;
    if (_lastTeachingDay == null || _baseHeld == 0) return;

    int future = 0;
    for (DateTime d = DateTime.now();
        !d.isAfter(_lastTeachingDay!);
        d = d.add(const Duration(days: 1))) {
      future += _weeklySchedule[_days[d.weekday - 1]] ?? 0;
    }

    final totalFinal = _baseHeld + future;
    final mustAttend =
        max(0, (0.75 * totalFinal).ceil() - _baseAttended);

    setState(() {
      _futureClasses = future;
      _mustAttend = mustAttend;
      _canBunk = max(0, future - mustAttend);
      _simHeld = _baseHeld;
      _simAttended = _baseAttended;
      _oldPercent = _simPercent;
    });

    _animatePercent();
  }

  void _animatePercent() {
    _percentAnim = Tween<double>(
      begin: _oldPercent,
      end: _simPercent,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _oldPercent = _simPercent;
    _animController.forward(from: 0);
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
        const SizedBox(height: 12),
        _modeToggle(),
        const SizedBox(height: 18),
        _trackingMode ? _trackingUI() : _calculatorUI(),
      ],
    ),
  );

  // =====================================================
  // DAILY TRACKING UI
  // =====================================================

  Widget _trackingUI() {
    if (_timetableMissing) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Please save timetable to enable attendance tracking.',
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_noClassesToday) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _datePickerHeader(),
          const SizedBox(height: 24),
          const Center(
            child: Text(
              'No classes scheduled for this day',
              style: TextStyle(
                color: Color(0xFF7A8A9C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _datePickerHeader(),
        const SizedBox(height: 14),
        ..._todayClasses.map(_classTile),
      ],
    );
  }

  Widget _datePickerHeader() => GestureDetector(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: _selectedDate,
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (d != null) {
        _selectedDate = d;
        await _loadDay();
      }
    },
    child: Text(
      DateFormat('dd MMM yyyy').format(_selectedDate),
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _classTile(_TodayClass c) {
    final status = _attendance[c.classId];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${c.subjectName} • ${c.startTime}–${c.endTime}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _statusBtn(c.classId, 'present', Colors.green, status),
              _statusBtn(c.classId, 'absent', Colors.red, status),
              _statusBtn(c.classId, 'cancelled', Colors.grey, status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBtn(
      String classId, String label, Color col, String? current) {
    final active = current == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => _mark(classId, label),
        child: Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? col.withOpacity(0.18) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? col : const Color(0xFFE0E6F0),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: active ? col : const Color(0xFF4C5D73),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // CALCULATOR UI
  // =====================================================

  Widget _calculatorUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _field(_subjectController, 'Subject name'),
        const SizedBox(height: 14),
        _weeklySelector(),
        const SizedBox(height: 6),
        const Text(
          'Tap to add a class, long-press to remove.',
          style: TextStyle(fontSize: 12, color: Color(0xFF9AA6B5)),
        ),
        const SizedBox(height: 14),
        _field(_heldController, 'Classes held till now', numeric: true),
        const SizedBox(height: 14),
        _field(_attendedController, 'Classes attended till now', numeric: true),
        const SizedBox(height: 14),
        _datePicker(),
        const SizedBox(height: 20),
        _calculateButton(),
        if (_mustAttend != null) ...[
          const SizedBox(height: 16),
          _resultBox(),
          const SizedBox(height: 12),
          _openSimulationButton(),
        ],
      ],
    );
  }

  // =====================================================
  // SIMULATION POPUP (FIXED VERSION)
  // =====================================================

  void _openSimulationDialog() {
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final screenWidth = MediaQuery.of(context).size.width;
            final chartSize = min(screenWidth * 0.4, 150.0);
            final strokeWidth = chartSize * 0.07;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Attendance Simulation',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'See how attending or skipping upcoming classes affects attendance.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7A8A9C),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AnimatedBuilder(
                      animation: _percentAnim,
                      builder: (_, __) {
                        return CustomPaint(
                          size: Size(chartSize, chartSize),
                          painter: _CirclePainter(
                            _percentAnim.value,
                            _percentColor,
                            strokeWidth,
                          ),
                          child: SizedBox(
                            width: chartSize,
                            height: chartSize,
                            child: Center(
                              child: Text(
                                '${(_percentAnim.value * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            if (_simHeld <
                                _baseHeld + (_futureClasses ?? 0)) {
                              _simHeld++;
                              _simAttended++;
                              setStateDialog(() {});
                              _animatePercent();
                            }
                          },
                          child: const Text('+ Attended'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_simHeld <
                                _baseHeld + (_futureClasses ?? 0)) {
                              _simHeld++;
                              setStateDialog(() {});
                              _animatePercent();
                            }
                          },
                          child: const Text('+ Skipped'),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        _simHeld = _baseHeld;
                        _simAttended = _baseAttended;
                        setStateDialog(() {});
                        _animatePercent();
                      },
                      child: const Text('Reset simulation'),
                    ),
                    const SizedBox(height: 10),
                    _legend(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _legend() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Legend',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text('Held: $_simHeld'),
          Text('Attended: $_simAttended'),
          Text('Skipped: ${_simHeld - _simAttended}'),
        ],
      ),
    );
  }

  // =====================================================
  // SMALL WIDGETS
  // =====================================================

  Widget _resultBox() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFE7F2FF),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Text('Result', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Future classes: $_futureClasses\n'
          'Must attend: $_mustAttend\n'
          'Can bunk: $_canBunk',
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );

  Widget _openSimulationButton() => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: _openSimulationDialog,
      child: const Text('Open attendance simulation'),
    ),
  );

  Widget _calculateButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _calculate,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3AA8F7),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      child: const Text('Calculate attendance'),
    ),
  );

  Widget _datePicker() => InkWell(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        initialDate: DateTime.now(),
      );
      if (d != null) setState(() => _lastTeachingDay = d);
    },
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded, size: 18),
          const SizedBox(width: 8),
          Text(_lastTeachingDay == null
              ? 'Last day of teaching'
              : '${_lastTeachingDay!.day}/${_lastTeachingDay!.month}/${_lastTeachingDay!.year}'),
        ],
      ),
    ),
  );

  Widget _field(TextEditingController c, String label,
      {bool numeric = false}) {
    return TextField(
      controller: c,
      keyboardType: numeric ? TextInputType.number : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF4F7FB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _weeklySelector() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: _days.map((day) {
      final count = _weeklySchedule[day] ?? 0;
      return GestureDetector(
        onTap: () => setState(() => _weeklySchedule[day] = count + 1),
        onLongPress: () => setState(() {
          count <= 1
              ? _weeklySchedule.remove(day)
              : _weeklySchedule[day] = count - 1;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: count > 0
                ? const Color(0xFF3AA8F7).withOpacity(0.18)
                : const Color(0xFFF4F7FB),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: count > 0
                  ? const Color(0xFF3AA8F7)
                  : const Color(0xFFE0E6F0),
            ),
          ),
          child: Text(
            count == 0 ? day.substring(0, 3) : '${day.substring(0, 3)} × $count',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      );
    }).toList(),
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
          Icons.percent_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
      const SizedBox(width: 8),
      const Text(
        'Attendance',
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
  );

  // =====================================================
  // MODE TOGGLE
  // =====================================================

  Widget _modeToggle() => Row(
    children: [
      _modeChip('Daily tracking', true),
      _modeChip('Calculator', false),
    ],
  );

  Widget _modeChip(String label, bool tracking) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _trackingMode = tracking),
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: _trackingMode == tracking
              ? const Color(0xFF3AA8F7)
              : const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: _trackingMode == tracking
                ? Colors.white
                : const Color(0xFF4C5D73),
          ),
        ),
      ),
    ),
  );
}

// =====================================================
// MODELS & PAINTER
// =====================================================

class _TodayClass {
  final String classId;
  final String subjectName;
  final String startTime;
  final String endTime;

  _TodayClass({
    required this.classId,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
  });
}

class _CirclePainter extends CustomPainter {
  final double percent;
  final Color color;
  final double strokeWidth;

  _CirclePainter(this.percent, this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - strokeWidth;

    final bgPaint = Paint()
      ..color = const Color(0xFFE0E6F0)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * percent.clamp(0.0, 1.0),
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CirclePainter old) =>
      old.percent != percent ||
      old.color != color ||
      old.strokeWidth != strokeWidth;
}