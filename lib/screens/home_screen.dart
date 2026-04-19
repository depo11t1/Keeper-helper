import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/keeper_layout.dart';
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
    required this.onOpenSort,
  });

  final List<SpiderProfile> spiders;
  final Color accent;
  final AppLanguage language;
  final ValueChanged<SpiderProfile> onSpiderTap;
  final ValueChanged<SpiderProfile> onSpiderLongPress;
  final ValueChanged<SpiderProfile> onFeedTap;
  final ValueChanged<SpiderProfile> onFeedLongPress;
  final VoidCallback onCreateSpider;
  final VoidCallback onOpenSort;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final strings = AppStrings.of(language);

    final sortedSpiders = spiders;

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              backgroundColor: palette.background,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 68,
              titleSpacing: 20,
              title: Text(
                strings.appTitle,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontSize: 24,
                  color: palette.textPrimary.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: onOpenSort,
                  icon: const Icon(Icons.sort_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: keeperPagePadding(
                context,
                top: 16,
                bottom: 110,
                maxWidth: 1420,
              ),
              sliver: sortedSpiders.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Text(
                          strings.emptyShort,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: palette.textMuted.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                  : SliverLayoutBuilder(
                builder: (context, constraints) {
                  const gap = 14.0;
                  const minCardWidth = 330.0;
                  final availableWidth = constraints.crossAxisExtent;
                  final columns =
                      ((availableWidth + gap) / (minCardWidth + gap)).floor()
                          .clamp(1, 3);

                  Widget buildCard(int index) {
                    final spider = sortedSpiders[index];
                    return SpiderCard(
                      spider: spider,
                      globalAccent: accent,
                      speciesLabel: spider.latinName.trim().isEmpty
                          ? strings.speciesPlaceholder
                          : spider.latinName,
                      feedingTitle: strings.feeding,
                      moltTitle: strings.moltLabel,
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
                    );
                  }

                  if (columns <= 1) {
                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: buildCard(index),
                        ),
                        childCount: sortedSpiders.length,
                      ),
                    );
                  }

                  return SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => buildCard(index),
                      childCount: sortedSpiders.length,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                      mainAxisExtent: 176,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: keeperPagePadding(
            context,
            horizontal: 20,
            maxWidth: 1420,
          ).right,
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
