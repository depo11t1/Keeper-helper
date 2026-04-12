import 'package:flutter/material.dart';

import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/spider_card.dart';

// Главная вкладка приложения.
// Здесь показываем список всех животных и кнопку создания новой карточки.
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.spiders,
    required this.accent,
    required this.onSpiderTap,
    required this.onFeedTap,
    required this.onFeedLongPress,
    required this.onCreateSpider,
  });

  final List<SpiderProfile> spiders;
  final Color accent;
  final ValueChanged<SpiderProfile> onSpiderTap;
  final ValueChanged<SpiderProfile> onFeedTap;
  final ValueChanged<SpiderProfile> onFeedLongPress;
  final VoidCallback onCreateSpider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);

    // Кто дольше не ел, тот выше в списке.
    final sortedSpiders = spiders.toList()
      ..sort((a, b) {
        final aDate = a.lastFeeding?.date;
        final bDate = b.lastFeeding?.date;
        if (aDate == null && bDate == null) {
          return 0;
        }
        if (aDate == null) {
          return -1;
        }
        if (bDate == null) {
          return 1;
        }
        return aDate.compareTo(bDate);
      });

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Text(
              'Keeper',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            ...sortedSpiders.map(
              (spider) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SpiderCard(
                  spider: spider,
                  globalAccent: accent,
                  onTap: () => onSpiderTap(spider),
                  onFeedTap: () => onFeedTap(spider),
                  onFeedLongPress: () => onFeedLongPress(spider),
                  relativeLastFeeding: _relativeLabel(spider.lastFeeding?.date),
                  lastMoltLabel: _lastMoltLabel(spider),
                ),
              ),
            ),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 22,
          child: FloatingActionButton(
            onPressed: onCreateSpider,
            backgroundColor: palette.accent,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ],
    );
  }

  String _relativeLabel(DateTime? date) {
    if (date == null) {
      return 'еще не отмечено';
    }

    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) {
      return 'сегодня';
    }
    return '$days дн. назад';
  }

  String _lastMoltLabel(SpiderProfile spider) {
    if (spider.molts.isEmpty) {
      return 'Нет данных';
    }

    final sorted = spider.molts.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.stage;
  }
}
