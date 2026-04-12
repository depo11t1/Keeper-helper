import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
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
    required this.language,
    required this.onSpiderTap,
    required this.onSpiderLongPress,
    required this.onFeedTap,
    required this.onFeedLongPress,
    required this.onCreateSpider,
  });

  final List<SpiderProfile> spiders;
  final Color accent;
  final AppLanguage language;
  final ValueChanged<SpiderProfile> onSpiderTap;
  final ValueChanged<SpiderProfile> onSpiderLongPress;
  final ValueChanged<SpiderProfile> onFeedTap;
  final ValueChanged<SpiderProfile> onFeedLongPress;
  final VoidCallback onCreateSpider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final strings = AppStrings.of(language);

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
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: palette.background,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 64,
              titleSpacing: 20,
              title: Text(
                strings.appTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.textPrimary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final spider = sortedSpiders[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SpiderCard(
                        spider: spider,
                        globalAccent: accent,
                        speciesLabel: spider.latinName.trim().isEmpty
                            ? strings.speciesPlaceholder
                            : spider.latinName,
                        sex: spider.sex,
                        onTap: () => onSpiderTap(spider),
                        onLongPress: () => onSpiderLongPress(spider),
                        onFeedTap: () => onFeedTap(spider),
                        onFeedLongPress: () => onFeedLongPress(spider),
                        relativeLastFeeding: _relativeLabel(
                          spider.lastFeeding?.date,
                          strings,
                        ),
                        lastMoltLabel: _lastMoltLabel(spider, strings),
                      ),
                    );
                  },
                  childCount: sortedSpiders.length,
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

  String _relativeLabel(DateTime? date, AppStrings strings) {
    if (date == null) {
      return strings.missingValue;
    }

    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) {
      return strings.today;
    }
    return strings.daysAgo(days);
  }

  String _lastMoltLabel(SpiderProfile spider, AppStrings strings) {
    if (spider.molts.isEmpty) {
      return strings.missingValue;
    }

    final sorted = spider.molts.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.stage;
  }
}
