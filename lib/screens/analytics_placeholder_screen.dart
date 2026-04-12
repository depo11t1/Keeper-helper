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

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          strings.analytics,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
          title: strings.molts == 'Линьки' ? 'Кто линяет чаще' : 'Molts most often',
          items: moltItems,
          showAll: _showAllMolters,
          onToggle: () => setState(() => _showAllMolters = !_showAllMolters),
          color: scheme.surfaceContainerLow,
          textColor: palette.textPrimary,
          strings: strings,
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
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
          ),
        ),
        if (value.isNotEmpty)
          Text(
            value,
            style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
          ),
      ],
    );
  }
}
