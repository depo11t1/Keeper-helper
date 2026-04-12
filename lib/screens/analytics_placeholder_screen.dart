import 'package:flutter/material.dart';

import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/keeper_panel.dart';
import '../widgets/timeline_chart.dart';

// Вкладка аналитики по всем созданным карточкам.
// Для каждого животного выводим отдельные grouped-блоки с графиками.
class AnalyticsPlaceholderScreen extends StatelessWidget {
  const AnalyticsPlaceholderScreen({
    super.key,
    required this.spiders,
    required this.accent,
  });

  final List<SpiderProfile> spiders;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = spiders.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text(
          'Аналитика',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        ...sorted.map(
          (spider) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _SpiderAnalyticsCard(
              spider: spider,
              accent: accent,
            ),
          ),
        ),
      ],
    );
  }
}

class _SpiderAnalyticsCard extends StatelessWidget {
  const _SpiderAnalyticsCard({
    required this.spider,
    required this.accent,
  });

  final SpiderProfile spider;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    final feedings = spider.feedings.map((entry) => entry.date).toList()..sort();
    final molts = spider.molts.map((entry) => entry.date).toList()..sort();
    final feedingAverage = TimelineChart.averageDays(feedings);
    final moltAverage = TimelineChart.averageDays(molts);

    return KeeperPanel(
      tone: KeeperPanelTone.base,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            spider.name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            spider.latinName,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _AnalyticsGroupCard(
            position: _AnalyticsGroupPosition.top,
            color: palette.accentSurface,
            child: _AnalyticsSummary(
              title: 'Кормление',
              value: feedingAverage == null ? 'Мало данных' : 'каждые $feedingAverage дн.',
            ),
          ),
          const SizedBox(height: 6),
          _AnalyticsGroupCard(
            position: _AnalyticsGroupPosition.bottom,
            color: palette.accentSurface,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: TimelineChart(
              dates: feedings,
              accent: accent,
              emptyLabel: 'Нет кормлений',
              averageLabel: 'Кормление',
            ),
          ),
          const SizedBox(height: 10),
          _AnalyticsGroupCard(
            position: _AnalyticsGroupPosition.top,
            color: palette.accentSurface,
            child: _AnalyticsSummary(
              title: 'Линька',
              value: moltAverage == null ? 'Мало данных' : 'каждые $moltAverage дн.',
            ),
          ),
          const SizedBox(height: 6),
          _AnalyticsGroupCard(
            position: _AnalyticsGroupPosition.bottom,
            color: palette.accentSurface,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: TimelineChart(
              dates: molts,
              accent: accent,
              emptyLabel: 'Нет линек',
              averageLabel: 'Линька',
            ),
          ),
        ],
      ),
    );
  }
}

enum _AnalyticsGroupPosition { top, bottom }

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
      borderRadius: position == _AnalyticsGroupPosition.top
          ? const BorderRadius.only(
              topLeft: Radius.circular(22),
              topRight: Radius.circular(22),
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            )
          : const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
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
  });

  final String title;
  final String value;

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
                ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
