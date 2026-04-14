import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/timeline_chart.dart';

// Вкладка аналитики: показываем короткие списки "кто ест чаще" и "кто линяет чаще".
class AnalyticsPlaceholderScreen extends StatefulWidget {
  const AnalyticsPlaceholderScreen({
    super.key,
    required this.spiders,
    required this.accent,
    required this.language,
  });

  final List<SpiderProfile> spiders;
  final Color accent;
  final AppLanguage language;

  @override
  State<AnalyticsPlaceholderScreen> createState() =>
      _AnalyticsPlaceholderScreenState();
}

class _AnalyticsPlaceholderScreenState extends State<AnalyticsPlaceholderScreen> {
  var _showAllFeeders = false;
  var _showAllMolters = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final scheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(widget.language);

    final sorted = widget.spiders.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final feedingItems = _buildItems(sorted, isMolt: false);
    final moltItems = _buildItems(sorted, isMolt: true);

    final feedingDates = widget.spiders
        .expand((spider) => spider.feedings.map((entry) => entry.date))
        .toList()
      ..sort();
    final moltDates = widget.spiders
        .expand((spider) => spider.molts.map((entry) => entry.date))
        .toList()
      ..sort();
    final feedingAverage = TimelineChart.averageDays(feedingDates);
    final moltAverage = TimelineChart.averageDays(moltDates);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          titleSpacing: 20,
          title: Text(
            strings.analytics,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
        _AnalyticsHero(
          feedAverage: feedingAverage,
          moltAverage: moltAverage,
          feedDates: feedingDates,
          moltDates: moltDates,
          accent: widget.accent,
          strings: strings,
        ),
        const SizedBox(height: 18),
        _AnalyticsListBlock(
          title: strings.feedsFastest,
          items: feedingItems,
          showAll: _showAllFeeders,
          onToggle: () => setState(() => _showAllFeeders = !_showAllFeeders),
          color: scheme.surfaceContainerLow,
          textColor: palette.textPrimary,
          strings: strings,
        ),
        const SizedBox(height: 18),
        _AnalyticsListBlock(
          title: strings.moltsFastest,
          items: moltItems,
          showAll: _showAllMolters,
          onToggle: () => setState(() => _showAllMolters = !_showAllMolters),
          color: scheme.surfaceContainerLow,
          textColor: palette.textPrimary,
          strings: strings,
        ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<_StatItem> _buildItems(List<SpiderProfile> spiders, {required bool isMolt}) {
    final items = <_StatItem>[];
    for (final spider in spiders) {
      final dates = isMolt
          ? spider.molts.map((entry) => entry.date).toList()
          : spider.feedings.map((entry) => entry.date).toList();
      dates.sort();
      final avg = TimelineChart.averageDays(dates);
      if (avg == null) {
        continue;
      }
      items.add(_StatItem(name: spider.name, averageDays: avg));
    }
    items.sort((a, b) => a.averageDays.compareTo(b.averageDays));
    return items;
  }
}

class _AnalyticsListBlock extends StatelessWidget {
  const _AnalyticsListBlock({
    required this.title,
    required this.items,
    required this.showAll,
    required this.onToggle,
    required this.color,
    required this.textColor,
    required this.strings,
  });

  final String title;
  final List<_StatItem> items;
  final bool showAll;
  final VoidCallback onToggle;
  final Color color;
  final Color textColor;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _AnalyticsGroupCard(
        position: _AnalyticsGroupPosition.single,
        color: color,
        child: _AnalyticsSummary(
          title: title,
          value: strings.noData,
          textColor: textColor,
        ),
      );
    }

    final visible = showAll ? items : items.take(2).toList();
    final tiles = <Widget>[
      _AnalyticsGroupCard(
        position: _AnalyticsGroupPosition.top,
        color: color,
        child: _AnalyticsSummary(
          title: title,
          value: '',
          textColor: textColor,
        ),
      ),
      const SizedBox(height: 6),
      ...List.generate(visible.length, (index) {
        final item = visible[index];
        final position = visible.length == 1
            ? _AnalyticsGroupPosition.bottom
            : index == visible.length - 1
                ? _AnalyticsGroupPosition.bottom
                : _AnalyticsGroupPosition.middle;
        return Padding(
          padding: EdgeInsets.only(bottom: index == visible.length - 1 ? 0 : 6),
          child: _AnalyticsGroupCard(
            position: position,
            color: color,
            child: _AnalyticsSummary(
              title: item.name,
              value: strings.everyDays(item.averageDays),
              textColor: textColor,
            ),
          ),
        );
      }),
    ];

    return Column(
      children: [
        ...tiles,
        if (items.length > 2) ...[
          const SizedBox(height: 8),
          Center(
            child: IconButton(
              onPressed: onToggle,
              icon: AnimatedRotation(
                duration: const Duration(milliseconds: 220),
                turns: showAll ? 0.5 : 0.0,
                child: const Icon(Icons.keyboard_arrow_down_rounded, size: 30),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _StatItem {
  const _StatItem({required this.name, required this.averageDays});

  final String name;
  final int averageDays;
}

enum _AnalyticsGroupPosition { single, top, middle, bottom }

class _AnalyticsGroupCard extends StatelessWidget {
  const _AnalyticsGroupCard({
    required this.child,
    required this.color,
    required this.position,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final Color color;
  final _AnalyticsGroupPosition position;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: switch (position) {
        _AnalyticsGroupPosition.single => BorderRadius.circular(22),
        _AnalyticsGroupPosition.top => const BorderRadius.only(
            topLeft: Radius.circular(22),
            topRight: Radius.circular(22),
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
        _AnalyticsGroupPosition.middle => BorderRadius.circular(10),
        _AnalyticsGroupPosition.bottom => const BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
            bottomLeft: Radius.circular(22),
            bottomRight: Radius.circular(22),
          ),
      },
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _AnalyticsSummary extends StatelessWidget {
  const _AnalyticsSummary({
    required this.title,
    required this.value,
    required this.textColor,
  });

  final String title;
  final String value;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
          ),
      ],
    );
  }
}

class _AverageBars extends StatelessWidget {
  const _AverageBars({
    required this.feedAverage,
    required this.moltAverage,
    required this.accent,
    required this.strings,
  });

  final int? feedAverage;
  final int? moltAverage;
  final Color accent;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final maxValue = [
      if (feedAverage != null) feedAverage!,
      if (moltAverage != null) moltAverage!,
      7,
    ].reduce((a, b) => a > b ? a : b);

    Widget buildRow(String label, int? value) {
      final ratio = value == null ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 8,
              color: accent.withValues(alpha: 0.16),
              child: FractionallySizedBox(
                widthFactor: ratio == 0 ? 0.15 : ratio,
                alignment: Alignment.centerLeft,
                child: Container(
                  color: accent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value == null ? strings.littleData : strings.everyDays(value),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildRow(strings.avgEats, feedAverage),
        const SizedBox(height: 14),
        buildRow(strings.avgMolts, moltAverage),
        const SizedBox(height: 10),
        Text(
          strings.isRu
              ? 'Показывает средний интервал между событиями'
              : 'Shows average interval between events',
          style: theme.textTheme.bodySmall?.copyWith(
            color: palette.textMuted,
          ),
        ),
      ],
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  const _AnalyticsHero({
    required this.feedAverage,
    required this.moltAverage,
    required this.feedDates,
    required this.moltDates,
    required this.accent,
    required this.strings,
  });

  final int? feedAverage;
  final int? moltAverage;
  final List<DateTime> feedDates;
  final List<DateTime> moltDates;
  final Color accent;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final base = Theme.of(context).colorScheme.surfaceContainerLow;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: base,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  strings.isRu ? 'Средние интервалы' : 'Average intervals',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.insights_rounded, color: accent),
            ],
          ),
          const SizedBox(height: 12),
          _DualTimelineChart(
            feedDates: feedDates,
            moltDates: moltDates,
            accent: accent,
            labelColor: palette.textMuted,
            feedLabel: strings.eatsShort,
            moltLabel: strings.moltsShort,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStatPill(
                  label: strings.avgEats,
                  value: feedAverage == null
                      ? strings.littleData
                      : strings.everyDays(feedAverage!),
                  accent: accent,
                  background: Color.alphaBlend(
                    accent.withValues(alpha: 0.14),
                    base,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatPill(
                  label: strings.avgMolts,
                  value: moltAverage == null
                      ? strings.littleData
                      : strings.everyDays(moltAverage!),
                  accent: accent,
                  background: Color.alphaBlend(
                    accent.withValues(alpha: 0.14),
                    base,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStatPill extends StatelessWidget {
  const _HeroStatPill({
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: palette.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DualTimelineChart extends StatelessWidget {
  const _DualTimelineChart({
    required this.feedDates,
    required this.moltDates,
    required this.accent,
    required this.labelColor,
    required this.feedLabel,
    required this.moltLabel,
  });

  final List<DateTime> feedDates;
  final List<DateTime> moltDates;
  final Color accent;
  final Color labelColor;
  final String feedLabel;
  final String moltLabel;

  @override
  Widget build(BuildContext context) {
    final sortedFeed = feedDates.toList()..sort();
    final sortedMolt = moltDates.toList()..sort();
    final feed = sortedFeed.length > 5
        ? sortedFeed.sublist(sortedFeed.length - 5)
        : sortedFeed;
    final molt = sortedMolt.length > 5
        ? sortedMolt.sublist(sortedMolt.length - 5)
        : sortedMolt;

    return SizedBox(
      height: 72,
      child: CustomPaint(
        painter: _DualTimelinePainter(
          feedDates: feed,
          moltDates: molt,
          accent: accent,
          labelColor: labelColor,
          feedLabel: feedLabel,
          moltLabel: moltLabel,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DualTimelinePainter extends CustomPainter {
  _DualTimelinePainter({
    required this.feedDates,
    required this.moltDates,
    required this.accent,
    required this.labelColor,
    required this.feedLabel,
    required this.moltLabel,
  });

  final List<DateTime> feedDates;
  final List<DateTime> moltDates;
  final Color accent;
  final Color labelColor;
  final String feedLabel;
  final String moltLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = accent.withValues(alpha: 0.5)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final dotPaintFeed = Paint()..color = accent;
    final dotPaintMolt = Paint()..color = accent.withValues(alpha: 0.5);

    final startX = 56.0;
    final endX = size.width - 10.0;
    final feedY = 20.0;
    final moltY = 50.0;

    canvas.drawLine(Offset(startX, feedY), Offset(endX, feedY), linePaint);
    canvas.drawLine(Offset(startX, moltY), Offset(endX, moltY), linePaint);

    void drawSeries(List<DateTime> dates, double y, Paint dotPaint) {
      if (dates.isEmpty) return;
      final sorted = dates.toList()..sort();
      final min = sorted.first.millisecondsSinceEpoch.toDouble();
      final max = sorted.last.millisecondsSinceEpoch.toDouble();
      final range = (max - min).abs() < 1 ? 1 : max - min;
      for (final date in sorted) {
        final t = (date.millisecondsSinceEpoch - min) / range;
        final x = startX + (endX - startX) * t;
        canvas.drawCircle(Offset(x, y), 4.8, dotPaint);
      }
    }

    drawSeries(feedDates, feedY, dotPaintFeed);
    drawSeries(moltDates, moltY, dotPaintMolt);

    final textStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final feedPainter = TextPainter(
      text: TextSpan(text: feedLabel, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    feedPainter.paint(canvas, Offset(0, feedY - 8));

    final moltPainter = TextPainter(
      text: TextSpan(text: moltLabel, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    moltPainter.paint(canvas, Offset(0, moltY - 8));
  }

  @override
  bool shouldRepaint(covariant _DualTimelinePainter oldDelegate) {
    return oldDelegate.feedDates != feedDates ||
        oldDelegate.moltDates != moltDates ||
        oldDelegate.accent != accent;
  }
}
