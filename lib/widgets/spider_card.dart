import 'package:flutter/material.dart';

import '../models/spider.dart';
import '../theme/app_theme.dart';
import 'spider_avatar.dart';

class SpiderCard extends StatelessWidget {
  const SpiderCard({
    super.key,
    required this.spider,
    required this.globalAccent,
    required this.onTap,
    required this.onFeedTap,
    required this.onFeedLongPress,
    required this.relativeLastFeeding,
    required this.lastMoltLabel,
  });

  final SpiderProfile spider;
  final Color globalAccent;
  final VoidCallback onTap;
  final VoidCallback onFeedTap;
  final VoidCallback onFeedLongPress;
  final String relativeLastFeeding;
  final String lastMoltLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final cardColor = palette.accentSurface;
    final primaryPanel = Color.alphaBlend(
      globalAccent.withValues(alpha: 0.08),
      palette.surfaceHigh,
    );
    final secondaryPanel = Color.alphaBlend(
      globalAccent.withValues(alpha: 0.08),
      palette.surfaceHigh,
    );

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SpiderAvatar(
                    seed: spider.avatarSeed,
                    accent: globalAccent,
                    label: spider.name,
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
                          spider.latinName,
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
                    padding: const EdgeInsets.only(top: 0),
                    child: GestureDetector(
                      onLongPress: onFeedLongPress,
                      child: FilledButton.tonal(
                        onPressed: onFeedTap,
                        style: FilledButton.styleFrom(
                          backgroundColor: globalAccent.withValues(alpha: 0.16),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(56, 56),
                          maximumSize: const Size(56, 56),
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
                  Expanded(
                    child: _StatusPanel(
                      title: 'Кормление',
                      value: relativeLastFeeding,
                      icon: Icons.restaurant_rounded,
                      color: primaryPanel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatusPanel(
                      title: 'Линька',
                      value: lastMoltLabel,
                      icon: Icons.science_rounded,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.86)),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
