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
          spiders: widget.spiders,
          feedAverage: feedingAverage,
          moltAverage: moltAverage,
          accent: widget.accent,
          strings: strings,
        ),
        const SizedBox(height: 18),
        _AnalyticsListBlock(
          title: strings.feedsFastest,
          icon: Icons.restaurant_rounded,
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
          icon: Icons.autorenew_rounded,
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

  @override
  void didUpdateWidget(covariant AnalyticsPlaceholderScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spiders != widget.spiders) {
      setState(() {
        _showAllFeeders = false;
        _showAllMolters = false;
      });
    }
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
    required this.icon,
    required this.items,
    required this.showAll,
    required this.onToggle,
    required this.color,
    required this.textColor,
    required this.strings,
  });

  final String title;
  final IconData icon;
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
          icon: icon,
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
          icon: icon,
          value: '',
          textColor: textColor,
        ),
      ),
      const SizedBox(height: 6),
      AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Column(
          children: List.generate(visible.length, (index) {
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
        ),
      ),
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
    this.icon,
  });

  final String title;
  final String value;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: keeperPalette(context).accent),
          const SizedBox(width: 8),
        ],
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
              fontSize: 12,
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
        buildRow(strings.avgEatsPlural, feedAverage),
        const SizedBox(height: 14),
        buildRow(strings.avgMoltsPlural, moltAverage),
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

class _AnalyticsHero extends StatefulWidget {
  const _AnalyticsHero({
    required this.spiders,
    required this.feedAverage,
    required this.moltAverage,
    required this.accent,
    required this.strings,
  });

  final List<SpiderProfile> spiders;
  final int? feedAverage;
  final int? moltAverage;
  final Color accent;
  final AppStrings strings;

  @override
  State<_AnalyticsHero> createState() => _AnalyticsHeroState();
}

class _AnalyticsHeroState extends State<_AnalyticsHero> {
  String? _selectedSpiderId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final base = Theme.of(context).colorScheme.surfaceContainerLow;
    final points = _buildPoints(widget.spiders);
    _AnalyticsHeroPoint? selectedPoint;
    for (final point in points) {
      if (point.id == _selectedSpiderId) {
        selectedPoint = point;
        break;
      }
    }
    selectedPoint ??= points.isEmpty ? null : points.first;

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
                  widget.strings.averageIntervals,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.insights_rounded, color: widget.accent),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroStatPill(
                  label: widget.strings.avgEatsPlural,
                  value: widget.feedAverage == null
                      ? widget.strings.littleData
                      : widget.strings.everyDays(widget.feedAverage!),
                  accent: widget.accent,
                  background: Color.alphaBlend(
                    widget.accent.withValues(alpha: 0.14),
                    base,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroStatPill(
                  label: widget.strings.avgMoltsPlural,
                  value: widget.moltAverage == null
                      ? widget.strings.littleData
                      : widget.strings.everyDays(widget.moltAverage!),
                  accent: widget.accent,
                  background: Color.alphaBlend(
                    widget.accent.withValues(alpha: 0.14),
                    base,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 188,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: widget.accent.withValues(alpha: 0.16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.accent.withValues(alpha: 0.11),
                  widget.accent.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: points.isEmpty
                ? Center(
                    child: Text(
                      widget.strings.noData,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: palette.textMuted,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const leftInset = 18.0;
                      const rightInset = 18.0;
                      const topInset = 58.0;
                      const bottomInset = 30.0;
                      final width =
                          constraints.maxWidth - leftInset - rightInset;
                      final height =
                          constraints.maxHeight - topInset - bottomInset;
                      final maxFeed = points
                          .map((point) => point.feedAverage)
                          .fold<int>(7, (a, b) => a > b ? a : b);
                      final maxMolt = points
                          .map((point) => point.moltAverage)
                          .fold<int>(7, (a, b) => a > b ? a : b);

                      Offset pointOffset(_AnalyticsHeroPoint point) {
                        final x = leftInset +
                            width * (point.feedAverage / maxFeed).clamp(0.0, 1.0);
                        final y = topInset +
                            height *
                                (1 - (point.moltAverage / maxMolt).clamp(0.0, 1.0));
                        return Offset(x, y);
                      }

                      return Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _AnalyticsPlanePainter(
                                accent: widget.accent,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 12,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: selectedPoint == null
                                  ? Text(
                                      widget.strings.noData,
                                      key: const ValueKey('hero-empty'),
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: palette.textMuted,
                                      ),
                                    )
                                  : Container(
                                      key: ValueKey(selectedPoint.id),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color.alphaBlend(
                                          widget.accent.withValues(alpha: 0.10),
                                          base,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            selectedPoint.name,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${widget.strings.feeding}: ${widget.strings.everyDays(selectedPoint.feedAverage)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: palette.textMuted,
                                            ),
                                          ),
                                          Text(
                                            '${widget.strings.molts}: ${widget.strings.everyDays(selectedPoint.moltAverage)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: palette.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                            ),
                          ),
                          for (final point in points)
                            Builder(
                              builder: (context) {
                                final offset = pointOffset(point);
                                final selected = point.id == selectedPoint?.id;
                                return Positioned(
                                  left: offset.dx - (selected ? 9 : 7),
                                  top: offset.dy - (selected ? 9 : 7),
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSpiderId = point.id;
                                      });
                                    },
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      width: selected ? 18 : 14,
                                      height: selected ? 18 : 14,
                                      decoration: BoxDecoration(
                                        color: widget.accent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: selected ? 0.95 : 0.75,
                                          ),
                                          width: selected ? 2.4 : 1.6,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: widget.accent.withValues(
                                              alpha: selected ? 0.36 : 0.18,
                                            ),
                                            blurRadius: selected ? 16 : 10,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          Positioned(
                            left: 14,
                            bottom: 10,
                            child: Text(
                              widget.strings.molts,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            bottom: 10,
                            child: Text(
                              widget.strings.feeding,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: palette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<_AnalyticsHeroPoint> _buildPoints(List<SpiderProfile> spiders) {
    final points = <_AnalyticsHeroPoint>[];
    for (final spider in spiders) {
      final feedDates = spider.feedings.map((entry) => entry.date).toList()..sort();
      final moltDates = spider.molts.map((entry) => entry.date).toList()..sort();
      final feedAverage = TimelineChart.averageDays(feedDates);
      final moltAverage = TimelineChart.averageDays(moltDates);
      if (feedAverage == null || moltAverage == null) {
        continue;
      }
      points.add(
        _AnalyticsHeroPoint(
          id: spider.id,
          name: spider.name,
          feedAverage: feedAverage,
          moltAverage: moltAverage,
        ),
      );
    }
    points.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return points;
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
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 12,
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsHeroPoint {
  const _AnalyticsHeroPoint({
    required this.id,
    required this.name,
    required this.feedAverage,
    required this.moltAverage,
  });

  final String id;
  final String name;
  final int feedAverage;
  final int moltAverage;
}

class _AnalyticsPlanePainter extends CustomPainter {
  const _AnalyticsPlanePainter({
    required this.accent,
  });

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = accent.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final strongPaint = Paint()
      ..color = accent.withValues(alpha: 0.16)
      ..strokeWidth = 1.2;

    const leftInset = 18.0;
    const rightInset = 18.0;
    const topInset = 58.0;
    const bottomInset = 30.0;
    final chartWidth = size.width - leftInset - rightInset;
    final chartHeight = size.height - topInset - bottomInset;

    for (var i = 0; i <= 4; i++) {
      final dx = leftInset + chartWidth * (i / 4);
      final dy = topInset + chartHeight * (i / 4);
      canvas.drawLine(
        Offset(dx, topInset),
        Offset(dx, size.height - bottomInset),
        i == 4 ? strongPaint : gridPaint,
      );
      canvas.drawLine(
        Offset(leftInset, dy),
        Offset(size.width - rightInset, dy),
        i == 0 ? strongPaint : gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AnalyticsPlanePainter oldDelegate) {
    return oldDelegate.accent != accent;
  }
}
