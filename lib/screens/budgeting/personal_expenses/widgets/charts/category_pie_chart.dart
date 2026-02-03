import 'dart:math';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double> data;

  const CategoryPieChart({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty || data.values.every((v) => v <= 0)) {
      return const Center(
        child: Text(
          'No category data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          width: double.infinity, // ✅ FIX
          child: CustomPaint(
            painter: _PieChartPainter(data),
          ),
        ),
        const SizedBox(height: 12),
        _Legend(data: data),
      ],
    );
  }
}

/* ---------------- PIE PAINTER ---------------- */

class _PieChartPainter extends CustomPainter {
  final Map<String, double> data;

  _PieChartPainter(this.data);

  final List<Color> colors = const [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.4;

    double startAngle = -pi / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    int colorIndex = 0;

    for (final entry in data.entries) {
      final value = entry.value;
      if (value <= 0) continue;

      final sweepAngle = (value / total) * 2 * pi;
      paint.color = colors[colorIndex % colors.length];

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
      colorIndex++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/* ---------------- LEGEND ---------------- */

class _Legend extends StatelessWidget {
  final Map<String, double> data;

  const _Legend({required this.data});

  @override
  Widget build(BuildContext context) {
    final colors = const [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    int index = 0;

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: data.entries.where((e) => e.value > 0).map((entry) {
        final color = colors[index % colors.length];
        index++;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${entry.key} (₹${entry.value.toStringAsFixed(0)})',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }
}
