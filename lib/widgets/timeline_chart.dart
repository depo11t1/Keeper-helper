import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class TimelineChart extends StatelessWidget {
  const TimelineChart({
    super.key,
    required this.dates,
    required this.accent,
    required this.emptyLabel,
    required this.averageLabel,
  });

  final List<DateTime> dates;
  final Color accent;
  final String emptyLabel;
  final String averageLabel;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    if (dates.isEmpty) {
      return SizedBox(
        height: 72,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            emptyLabel,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
          ),
        ),
      );
    }

    final sorted = dates.toList()..sort();
    final visible = sorted.length > 5 ? sorted.sublist(sorted.length - 5) : sorted;

    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _TimelinePainter(
          dates: visible,
          accent: accent,
          lineColor: accent,
          textColor: Colors.white,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  static int? averageDays(List<DateTime> sorted) {
    if (sorted.length < 2) {
      return null;
    }

    var total = 0;
    for (var i = 1; i < sorted.length; i++) {
      total += sorted[i].difference(sorted[i - 1]).inDays;
    }
    return (total / (sorted.length - 1)).round();
  }
}

class _TimelinePainter extends CustomPainter {
  _TimelinePainter({
    required this.dates,
    required this.accent,
    required this.lineColor,
    required this.textColor,
  });

  final List<DateTime> dates;
  final Color accent;
  final Color lineColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = accent;

    final startX = 8.0;
    final endX = size.width - 8.0;
    final centerY = 20.0;
    canvas.drawLine(Offset(startX, centerY), Offset(endX, centerY), linePaint);

    final min = dates.first.millisecondsSinceEpoch.toDouble();
    final max = dates.last.millisecondsSinceEpoch.toDouble();
    final range = (max - min).abs() < 1 ? 1 : max - min;

    for (final date in dates) {
      final t = (date.millisecondsSinceEpoch - min) / range;
      final x = startX + (endX - startX) * t;
      canvas.drawCircle(Offset(x, centerY), 7.8, dotPaint);

      final textPainter = TextPainter(
        text: TextSpan(
          text: DateFormat('dd.MM').format(date),
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(
          (x - textPainter.width / 2).clamp(0, size.width - textPainter.width),
          48,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TimelinePainter oldDelegate) {
    return oldDelegate.dates != dates ||
        oldDelegate.accent != accent ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.textColor != textColor;
  }
}
