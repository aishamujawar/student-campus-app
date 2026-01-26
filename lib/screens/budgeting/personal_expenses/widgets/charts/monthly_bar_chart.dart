import 'dart:math';
import 'package:flutter/material.dart';

class MonthlyBarChart extends StatelessWidget {
  final Map<String, double> monthlyTotals;

  const MonthlyBarChart({
    Key? key,
    required this.monthlyTotals,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (monthlyTotals.isEmpty) {
      return _EmptyState();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      height: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly Spend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _BarChartPainter(monthlyTotals),
              size: Size.infinite,
            ),
          ),
        ],
      ),
    );
  }
}

/* ─────────────────────────────────────────────── */
/* 🎨 PAINTER */
/* ─────────────────────────────────────────────── */

class _BarChartPainter extends CustomPainter {
  final Map<String, double> data;

  _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = 22.0;
    final spacing = 18.0;
    final bottomPadding = 28.0;
    final maxBarHeight = size.height - bottomPadding;

    final maxValue = data.values.reduce((a, b) => max(a, b));

    final paint = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    double x = 0;

    for (final entry in data.entries) {
      // ✅ FIX: barHeight defined BEFORE usage
      final barHeight = (entry.value / maxValue) * maxBarHeight;

      final rect = Rect.fromLTWH(
        x,
        size.height - barHeight - bottomPadding,
        barWidth,
        barHeight,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(6),
        ),
        paint,
      );

      // 💰 Amount label
      textPainter.text = TextSpan(
        text: '₹${entry.value.toInt()}',
        style: const TextStyle(
          fontSize: 10,
          color: Colors.black87,
        ),
      );
      textPainter.layout(maxWidth: barWidth + 10);
      textPainter.paint(
        canvas,
        Offset(
          x - 4,
          rect.top - 14,
        ),
      );

      // 📅 Month label
      final monthLabel = entry.key.substring(5); // MM
      textPainter.text = TextSpan(
        text: monthLabel,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.grey,
        ),
      );
      textPainter.layout(maxWidth: barWidth + 10);
      textPainter.paint(
        canvas,
        Offset(
          x - 2,
          size.height - 20,
        ),
      );

      x += barWidth + spacing;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/* ─────────────────────────────────────────────── */
/* 🫙 EMPTY STATE */
/* ─────────────────────────────────────────────── */

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'No monthly data yet',
        style: TextStyle(
          color: Colors.grey,
          fontSize: 14,
        ),
      ),
    );
  }
}
