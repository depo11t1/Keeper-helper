import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/keeper_layout.dart';
import '../widgets/timeline_chart.dart';

int? _averageAcrossSpiders(
  Iterable<SpiderProfile> spiders,
  List<DateTime> Function(SpiderProfile spider) pickDates,
) {
  var totalDays = 0;
  var intervals = 0;

  for (final spider in spiders) {
    final dates = pickDates(spider).toList()..sort();
    if (dates.length < 2) {
      continue;
    }
    for (var i = 1; i < dates.length; i++) {
      totalDays += dates[i].difference(dates[i - 1]).inDays;
      intervals++;
    }
  }

  if (intervals == 0) {
    return null;
  }

  return (totalDays / intervals).round();
}

// Экран аналитики: верхняя сводка по выбранному периоду и списки по частоте событий.
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
  _AnalyticsPeriod _period = _AnalyticsPeriod.allTime;
  DateTime? _customStart;
  DateTime? _customEnd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final scheme = Theme.of(context).colorScheme;
    final strings = AppStrings.of(widget.language);
    final range = _resolveRange();

    final sorted = widget.spiders.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final feedingItems = _buildItems(
      sorted,
      isMolt: false,
      rangeStart: range.$1,
      rangeEnd: range.$2,
    );
    final moltItems = _buildItems(
      sorted,
      isMolt: true,
      rangeStart: range.$1,
      rangeEnd: range.$2,
    );

    final feedingAverage = _averageAcrossSpiders(
      widget.spiders,
      (spider) => spider.feedings
          .map((entry) => entry.date)
          .where((date) => _isWithinRange(date, range.$1, range.$2))
          .toList(),
    );
    final moltAverage = _averageAcrossSpiders(
      widget.spiders,
      (spider) => spider.molts
          .map((entry) => entry.date)
          .where((date) => _isWithinRange(date, range.$1, range.$2))
          .toList(),
    );
    final totalFeedings = _countEvents(
      widget.spiders,
      range.$1,
      range.$2,
      (spider) => spider.feedings.map((entry) => entry.date),
    );
    final totalMolts = _countEvents(
      widget.spiders,
      range.$1,
      range.$2,
      (spider) => spider.molts.map((entry) => entry.date),
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 68,
          titleSpacing: 20,
          title: Text(
            strings.analytics,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SliverPadding(
          padding: keeperPagePadding(
            context,
            top: 16,
            bottom: 28,
            maxWidth: 760,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate(
              [
        _AnalyticsHero(
          period: _period,
          customStart: _customStart,
          customEnd: _customEnd,
          totalFeedings: totalFeedings,
          totalMolts: totalMolts,
          feedAverage: feedingAverage,
          moltAverage: moltAverage,
          accent: widget.accent,
          strings: strings,
          onPeriodSelected: (period) {
            setState(() {
              _period = period;
            });
          },
          onPickCustomRange: _pickCustomRange,
          onClearCustomRange: () {
            setState(() {
              _customStart = null;
              _customEnd = null;
              _period = _AnalyticsPeriod.allTime;
            });
          },
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

  List<_StatItem> _buildItems(
    List<SpiderProfile> spiders, {
    required bool isMolt,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
  }) {
    final items = <_StatItem>[];
    for (final spider in spiders) {
      final dates = isMolt
          ? spider.molts.map((entry) => entry.date).toList()
          : spider.feedings.map((entry) => entry.date).toList();
      final filtered = dates
          .where((date) => _isWithinRange(date, rangeStart, rangeEnd))
          .toList()
        ..sort();
      final avg = TimelineChart.averageDays(filtered);
      if (avg == null) {
        continue;
      }
      items.add(_StatItem(name: spider.name, averageDays: avg));
    }
    items.sort((a, b) => a.averageDays.compareTo(b.averageDays));
    return items;
  }

  (DateTime?, DateTime?) _resolveRange() {
    final now = DateTime.now();
    switch (_period) {
      case _AnalyticsPeriod.month:
        return (DateTime(now.year, now.month - 1, now.day), null);
      case _AnalyticsPeriod.year:
        return (DateTime(now.year - 1, now.month, now.day), null);
      case _AnalyticsPeriod.allTime:
        return (null, null);
      case _AnalyticsPeriod.custom:
        return (_customStart, _customEnd);
    }
  }

  bool _isWithinRange(DateTime date, DateTime? start, DateTime? end) {
    if (start != null && date.isBefore(start)) {
      return false;
    }
    if (end != null && date.isAfter(end)) {
      return false;
    }
    return true;
  }

  int _countEvents(
    List<SpiderProfile> spiders,
    DateTime? start,
    DateTime? end,
    Iterable<DateTime> Function(SpiderProfile spider) pickDates,
  ) {
    var total = 0;
    for (final spider in spiders) {
      for (final date in pickDates(spider)) {
        if (_isWithinRange(date, start, end)) {
          total++;
        }
      }
    }
    return total;
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final first = DateTime(2020);
    final start = await showDatePicker(
      context: context,
      initialDate: _customStart ?? now,
      firstDate: first,
      lastDate: _customEnd ?? now,
      locale: Locale(AppStrings.of(widget.language).localeCode),
    );
    if (start == null || !mounted) {
      return;
    }
    final end = await showDatePicker(
      context: context,
      initialDate: _customEnd ?? now,
      firstDate: start,
      lastDate: now,
      locale: Locale(AppStrings.of(widget.language).localeCode),
    );
    if (end == null) {
      return;
    }
    setState(() {
      _customStart = DateTime(start.year, start.month, start.day);
      _customEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);
      _period = _AnalyticsPeriod.custom;
    });
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
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
        _AnalyticsGroupPosition.middle => BorderRadius.circular(12),
        _AnalyticsGroupPosition.bottom => const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
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
              fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w600,
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
    required this.period,
    required this.customStart,
    required this.customEnd,
    required this.totalFeedings,
    required this.totalMolts,
    required this.feedAverage,
    required this.moltAverage,
    required this.accent,
    required this.strings,
    required this.onPeriodSelected,
    required this.onPickCustomRange,
    required this.onClearCustomRange,
  });

  final _AnalyticsPeriod period;
  final DateTime? customStart;
  final DateTime? customEnd;
  final int totalFeedings;
  final int totalMolts;
  final int? feedAverage;
  final int? moltAverage;
  final Color accent;
  final AppStrings strings;
  final ValueChanged<_AnalyticsPeriod> onPeriodSelected;
  final VoidCallback onPickCustomRange;
  final VoidCallback onClearCustomRange;

  @override
  State<_AnalyticsHero> createState() => _AnalyticsHeroState();
}

class _AnalyticsHeroState extends State<_AnalyticsHero> {
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerLow;
    final showCustomRange = widget.period == _AnalyticsPeriod.custom &&
        widget.customStart != null &&
        widget.customEnd != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _AnalyticsPeriodChip(
                label: _periodLabel(_AnalyticsPeriod.month),
                selected: widget.period == _AnalyticsPeriod.month,
                accent: widget.accent,
                background: base,
                onTap: () => widget.onPeriodSelected(_AnalyticsPeriod.month),
              ),
              const SizedBox(width: 8),
              _AnalyticsPeriodChip(
                label: _periodLabel(_AnalyticsPeriod.year),
                selected: widget.period == _AnalyticsPeriod.year,
                accent: widget.accent,
                background: base,
                onTap: () => widget.onPeriodSelected(_AnalyticsPeriod.year),
              ),
              const SizedBox(width: 8),
              _AnalyticsPeriodChip(
                label: _periodLabel(_AnalyticsPeriod.allTime),
                selected: widget.period == _AnalyticsPeriod.allTime,
                accent: widget.accent,
                background: base,
                onTap: () => widget.onPeriodSelected(_AnalyticsPeriod.allTime),
              ),
              const SizedBox(width: 8),
              _AnalyticsPlusChip(
                selected: widget.period == _AnalyticsPeriod.custom,
                accent: widget.accent,
                background: base,
                onTap: widget.onPickCustomRange,
              ),
            ],
          ),
        ),
        if (showCustomRange) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: _MetricGroup(
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(22),
              ),
              child: _CustomRangeLabel(
                start: widget.customStart!,
                end: widget.customEnd!,
                strings: widget.strings,
                onClear: widget.onClearCustomRange,
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MetricGroup(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(22),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: _HeroMetricCard(
                  icon: Icons.restaurant_rounded,
                  title: widget.strings.feeding,
                  label: widget.strings.totalShort,
                  value: '${widget.totalFeedings}',
                  accent: widget.accent,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _MetricGroup(
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(22),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: _HeroMetricCard(
                  icon: Icons.autorenew_rounded,
                  title: widget.strings.molts,
                  label: widget.strings.totalShort,
                  value: '${widget.totalMolts}',
                  accent: widget.accent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _MetricGroup(
          decoration: BoxDecoration(
            color: base,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: _HeroWideMetricRow(
            icon: Icons.restaurant_rounded,
            label: widget.strings.averageEveryShort,
            value: widget.feedAverage == null
                ? widget.strings.littleData
                : '${widget.feedAverage} ${widget.strings.daysShort}',
            accent: widget.accent,
          ),
        ),
        const SizedBox(height: 6),
        _MetricGroup(
          decoration: BoxDecoration(
            color: base,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: _HeroWideMetricRow(
            icon: Icons.autorenew_rounded,
            label: widget.strings.averageEveryShort,
            value: widget.moltAverage == null
                ? widget.strings.littleData
                : '${widget.moltAverage} ${widget.strings.daysShort}',
            accent: widget.accent,
          ),
        ),
      ],
    );
  }

  String _periodLabel(_AnalyticsPeriod period) {
    return switch (period) {
      _AnalyticsPeriod.month => widget.strings.analyticsMonth,
      _AnalyticsPeriod.year => widget.strings.analyticsYear,
      _AnalyticsPeriod.allTime => widget.strings.analyticsAllTime,
      _AnalyticsPeriod.custom => '+',
    };
  }
}

enum _AnalyticsPeriod { month, year, allTime, custom }

class _AnalyticsPeriodChip extends StatelessWidget {
  const _AnalyticsPeriodChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    final radius = BorderRadius.circular(selected ? 999 : 16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.11) : background,
            borderRadius: radius,
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              color: selected
                  ? accent
                  : palette.textPrimary.withValues(alpha: 0.86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnalyticsPlusChip extends StatelessWidget {
  const _AnalyticsPlusChip({
    required this.selected,
    required this.accent,
    required this.background,
    required this.onTap,
  });

  final bool selected;
  final Color accent;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 42,
            minHeight: 40,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.11) : background,
            borderRadius: radius,
          ),
          child: Icon(
            Icons.add_rounded,
            size: 22,
            color: selected
                ? accent
                : keeperPalette(context).textPrimary.withValues(alpha: 0.86),
          ),
        ),
      ),
    );
  }
}

class _MetricGroup extends StatelessWidget {
  const _MetricGroup({
    required this.decoration,
    required this.child,
  });

  final BoxDecoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.all(14),
      child: child,
    );
  }
}

class _HeroMetricRow extends StatelessWidget {
  const _HeroMetricRow({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final compactValue = value.length > 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          height: 24,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: compactValue ? 15 : 18,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroMetricCard extends StatelessWidget {
  const _HeroMetricCard({
    required this.icon,
    required this.title,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: accent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text(
              label,
              style: theme.textTheme.titleLarge?.copyWith(
                color: palette.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroWideMetricRow extends StatelessWidget {
  const _HeroWideMetricRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final isDataValue = RegExp(r'^\d+').hasMatch(value);

    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: accent,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: palette.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: isDataValue
              ? theme.textTheme.titleLarge?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                )
              : theme.textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  color: palette.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
        ),
      ],
    );
  }
}

class _CustomRangeLabel extends StatelessWidget {
  const _CustomRangeLabel({
    required this.start,
    required this.end,
    required this.strings,
    required this.onClear,
  });

  final DateTime start;
  final DateTime end;
  final AppStrings strings;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    final text =
        '${start.day.toString().padLeft(2, '0')}.${start.month.toString().padLeft(2, '0')}.${start.year}'
        ' - '
        '${end.day.toString().padLeft(2, '0')}.${end.month.toString().padLeft(2, '0')}.${end.year}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: palette.textPrimary.withValues(alpha: 0.96),
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onClear,
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: palette.textPrimary.withValues(alpha: 0.76),
            ),
          ),
        ),
      ],
    );
  }
}
