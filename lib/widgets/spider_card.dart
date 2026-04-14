import 'package:flutter/material.dart';

import '../models/spider.dart';
import '../theme/app_theme.dart';
import 'spider_avatar.dart';

class SpiderCard extends StatelessWidget {
  const SpiderCard({
    super.key,
    required this.spider,
    required this.globalAccent,
    required this.speciesLabel,
    required this.feedingTitle,
    required this.moltTitle,
    required this.sex,
    required this.onTap,
    required this.onLongPress,
    required this.onFeedTap,
    required this.onFeedLongPress,
    required this.relativeLastFeeding,
    required this.lastMoltLabel,
  });

  final SpiderProfile spider;
  final Color globalAccent;
  final String speciesLabel;
  final String feedingTitle;
  final String moltTitle;
  final SpiderSex sex;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onFeedTap;
  final VoidCallback onFeedLongPress;
  final String relativeLastFeeding;
  final String lastMoltLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final scheme = theme.colorScheme;
    final cardColor = scheme.surfaceContainerLow;
    final panelColor = Color.alphaBlend(
      palette.badgeBackground.withValues(alpha: 0.08),
      scheme.surfaceContainerLow,
    );
    final primaryPanel = panelColor;
    final secondaryPanel = panelColor;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpiderAvatar(
                    seed: spider.avatarSeed,
                    accent: globalAccent,
                    label: spider.name,
                    photoPath: spider.photoPath,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spider.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          speciesLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: palette.textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: GestureDetector(
                      onLongPress: onFeedLongPress,
                      child: FilledButton.tonal(
                        onPressed: onFeedTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.badgeBackground,
                          foregroundColor: palette.badgeForeground,
                          minimumSize: const Size(60, 60),
                          maximumSize: const Size(60, 60),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Icon(Icons.restaurant_rounded, size: 21),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    child: _StatusPanel(
                      title: feedingTitle,
                      value: relativeLastFeeding,
                      icon: Icons.restaurant_rounded,
                      color: primaryPanel,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: _StatusPanel(
                      title: moltTitle,
                      value: lastMoltLabel,
                      icon: Icons.autorenew_rounded,
                      color: secondaryPanel,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPanel extends StatelessWidget {
  const _StatusPanel({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: palette.badgeForeground),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: palette.badgeForeground.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: palette.textPrimary.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}
