import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../models/spider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_version_text.dart';
import '../widgets/keeper_layout.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.currentAccent,
    required this.currentLanguage,
    required this.experimentalTintedBackground,
    required this.analyticsSpiders,
    required this.analyticsSelectedIds,
    required this.onAccentChanged,
    required this.onLanguageChanged,
    required this.onExperimentalTintedBackgroundChanged,
    required this.onAnalyticsSelectionChanged,
    required this.onOpenArchive,
    required this.onOpenAnalytics,
    required this.onBackup,
    required this.onRestoreBackup,
  });

  final Color currentAccent;
  final AppLanguage currentLanguage;
  final bool experimentalTintedBackground;
  final List<SpiderProfile> analyticsSpiders;
  final Set<String> analyticsSelectedIds;
  final ValueChanged<Color> onAccentChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onExperimentalTintedBackgroundChanged;
  final ValueChanged<Set<String>> onAnalyticsSelectionChanged;
  final VoidCallback onOpenArchive;
  final VoidCallback onOpenAnalytics;
  final VoidCallback onBackup;
  final VoidCallback onRestoreBackup;

  static const accentOptions = [
    Color(0xFFA78BFA),
    Color(0xFF7DD3FC),
    Color(0xFF93C5FD),
    Color(0xFFF9A8D4),
    Color(0xFFFDBA74),
    Color(0xFF86EFAC),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = keeperPalette(context);
    final scheme = theme.colorScheme;
    final strings = AppStrings.of(currentLanguage);

    if (MediaQuery.sizeOf(context).shortestSide >= 600) {
      return _SettingsTabletView(
        currentAccent: currentAccent,
        currentLanguage: currentLanguage,
        experimentalTintedBackground: experimentalTintedBackground,
        analyticsSpiders: analyticsSpiders,
        analyticsSelectedIds: analyticsSelectedIds,
        onAccentChanged: onAccentChanged,
        onLanguageChanged: onLanguageChanged,
        onExperimentalTintedBackgroundChanged:
            onExperimentalTintedBackgroundChanged,
        onAnalyticsSelectionChanged: onAnalyticsSelectionChanged,
        onOpenArchive: onOpenArchive,
        onBackup: onBackup,
        onRestoreBackup: onRestoreBackup,
      );
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: palette.background,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 68,
          titleSpacing: 20,
          title: Text(
            strings.settings,
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
                _SettingsBlockCard(
                  position: _SettingsBlockPosition.top,
                  color: scheme.surfaceContainerLow,
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: accentOptions.map((color) {
                      final selected =
                          color.toARGB32() == currentAccent.toARGB32();
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onAccentChanged(color),
                        child: SizedBox(
                          width: 38,
                          height: 38,
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOutCubic,
                              scale: selected ? 1.12 : 0.94,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: selected ? 30 : 28,
                                height: selected ? 30 : 28,
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(
                                    selected ? 10 : 9,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                _SettingsActionTile(
                  position: _SettingsBlockPosition.bottom,
                  icon: Icons.brightness_6_rounded,
                  title: strings.tintedBackgroundMode,
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  verticalPadding: 13,
                  trailing: _SettingsAccentToggle(
                    value: experimentalTintedBackground,
                    accent: palette.badgeForeground,
                    activeTrack: Color.alphaBlend(
                      palette.badgeForeground.withValues(alpha: 0.34),
                      scheme.surfaceContainerHighest.withValues(alpha: 0.96),
                    ),
                    inactiveTrack: Color.alphaBlend(
                      palette.badgeForeground.withValues(alpha: 0.16),
                      scheme.surfaceContainerHighest.withValues(alpha: 0.96),
                    ),
                    activeThumb: palette.badgeForeground,
                    inactiveThumb: Color.alphaBlend(
                      palette.badgeForeground.withValues(alpha: 0.08),
                      scheme.surfaceContainerHighest.withValues(alpha: 0.98),
                    ),
                  ),
                  onTap: () => onExperimentalTintedBackgroundChanged(
                    !experimentalTintedBackground,
                  ),
                ),
                const SizedBox(height: 18),
                _SettingsActionTile(
                  position: _SettingsBlockPosition.top,
                  icon: Icons.language_rounded,
                  title:
                      '${strings.languageLabel}: ${strings.languageName(currentLanguage)}',
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  onTap: () => _showLanguageSheet(context, strings),
                ),
                const SizedBox(height: 8),
                _SettingsActionTile(
                  position: _SettingsBlockPosition.middle,
                  icon: Icons.archive_outlined,
                  title: strings.archive,
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  onTap: onOpenArchive,
                ),
                const SizedBox(height: 8),
                _SettingsActionTile(
                  position: _SettingsBlockPosition.bottom,
                  icon: Icons.insights_rounded,
                  title: strings.analytics,
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  onTap: onOpenAnalytics,
                ),
                const SizedBox(height: 18),
                _SettingsActionTile(
                  position: _SettingsBlockPosition.top,
                  icon: Icons.cloud_outlined,
                  title: strings.backup,
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  onTap: onBackup,
                ),
                const SizedBox(height: 8),
                _SettingsActionTile(
                  position: _SettingsBlockPosition.bottom,
                  icon: Icons.info_outline_rounded,
                  title: strings.aboutApp,
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AboutScreen(language: currentLanguage),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showStub(BuildContext context, String title, String text) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.of(currentLanguage).ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showLanguageSheet(BuildContext context, AppStrings strings) {
    final palette = keeperPalette(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: palette.background,
      builder: (context) {
        final entries = [
          (strings.dutch, true, AppLanguage.nl),
          (strings.english, true, AppLanguage.en),
          (strings.french, true, AppLanguage.fr),
          (strings.german, true, AppLanguage.de),
          (strings.hindi, true, AppLanguage.hi),
          (strings.japanese, true, AppLanguage.ja),
          (strings.portuguese, true, AppLanguage.pt),
          (strings.russian, true, AppLanguage.ru),
          (strings.spanish, true, AppLanguage.es),
          (strings.swedish, true, AppLanguage.sv),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: ListView(
              children: [
                ...entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isFirst = index == 0;
                  final isLast = index == entries.length - 1;
                  final position = entries.length == 1
                      ? _SettingsBlockPosition.single
                      : isFirst
                          ? _SettingsBlockPosition.top
                          : isLast
                              ? _SettingsBlockPosition.bottom
                              : _SettingsBlockPosition.middle;
                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                    child: _SettingsActionTile(
                      icon: null,
                      title: item.$1,
                      position: position,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      iconColor: keeperPalette(context).badgeForeground,
                      trailing: item.$2 && item.$3 == currentLanguage
                          ? Icon(
                              Icons.check_rounded,
                              color: keeperPalette(context).badgeForeground,
                            )
                          : null,
                      onTap: () {
                        if (item.$2 && item.$3 != null) {
                          onLanguageChanged(item.$3!);
                          Navigator.of(context).pop();
                        } else {
                          _showStub(
                            context,
                            strings.languageLabel,
                            strings.placeholderMessage,
                          );
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

enum _SettingsTabletSection {
  appearance,
  language,
  analytics,
  backup,
  about,
}

class _SettingsTabletView extends StatefulWidget {
  const _SettingsTabletView({
    required this.currentAccent,
    required this.currentLanguage,
    required this.experimentalTintedBackground,
    required this.analyticsSpiders,
    required this.analyticsSelectedIds,
    required this.onAccentChanged,
    required this.onLanguageChanged,
    required this.onExperimentalTintedBackgroundChanged,
    required this.onAnalyticsSelectionChanged,
    required this.onOpenArchive,
    required this.onBackup,
    required this.onRestoreBackup,
  });

  final Color currentAccent;
  final AppLanguage currentLanguage;
  final bool experimentalTintedBackground;
  final List<SpiderProfile> analyticsSpiders;
  final Set<String> analyticsSelectedIds;
  final ValueChanged<Color> onAccentChanged;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<bool> onExperimentalTintedBackgroundChanged;
  final ValueChanged<Set<String>> onAnalyticsSelectionChanged;
  final VoidCallback onOpenArchive;
  final VoidCallback onBackup;
  final VoidCallback onRestoreBackup;

  @override
  State<_SettingsTabletView> createState() => _SettingsTabletViewState();
}

class _SettingsTabletViewState extends State<_SettingsTabletView> {
  _SettingsTabletSection _section = _SettingsTabletSection.appearance;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.currentLanguage);
    final scheme = Theme.of(context).colorScheme;
    final palette = keeperPalette(context);

    return Row(
      children: [
        Container(
          width: 296,
          padding: const EdgeInsets.fromLTRB(20, 20, 16, 24),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLowest.withValues(alpha: 0.35),
            border: Border(
              right: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.18),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                child: Text(
                  strings.settings,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              _SettingsTabletNavTile(
                label: strings.experimentalColors,
                icon: Icons.palette_outlined,
                selected: _section == _SettingsTabletSection.appearance,
                position: _SettingsBlockPosition.top,
                onTap: () => setState(
                  () => _section = _SettingsTabletSection.appearance,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsTabletNavTile(
                label: strings.languageLabel,
                icon: Icons.language_rounded,
                selected: _section == _SettingsTabletSection.language,
                position: _SettingsBlockPosition.middle,
                onTap: () => setState(
                  () => _section = _SettingsTabletSection.language,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsTabletNavTile(
                label: strings.analytics,
                icon: Icons.insights_rounded,
                selected: _section == _SettingsTabletSection.analytics,
                position: _SettingsBlockPosition.middle,
                onTap: () => setState(
                  () => _section = _SettingsTabletSection.analytics,
                ),
              ),
              const SizedBox(height: 8),
              _SettingsTabletNavTile(
                label: strings.archive,
                icon: Icons.archive_outlined,
                position: _SettingsBlockPosition.bottom,
                selected: false,
                onTap: widget.onOpenArchive,
              ),
              const SizedBox(height: 18),
              _SettingsTabletNavTile(
                label: strings.backup,
                icon: Icons.cloud_outlined,
                selected: _section == _SettingsTabletSection.backup,
                position: _SettingsBlockPosition.top,
                onTap: () =>
                    setState(() => _section = _SettingsTabletSection.backup),
              ),
              const SizedBox(height: 8),
              _SettingsTabletNavTile(
                label: strings.aboutApp,
                icon: Icons.info_outline_rounded,
                selected: _section == _SettingsTabletSection.about,
                position: _SettingsBlockPosition.bottom,
                onTap: () =>
                    setState(() => _section = _SettingsTabletSection.about),
              ),
            ],
          ),
        ),
        Expanded(
          child: KeeperCenteredBody(
            maxWidth: 820,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 120),
                  child: _buildSection(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context) {
    final strings = AppStrings.of(widget.currentLanguage);
    final scheme = Theme.of(context).colorScheme;
    final palette = keeperPalette(context);

    switch (_section) {
      case _SettingsTabletSection.appearance:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabletSectionHeader(
              title: strings.experimentalColors,
              subtitle: strings.tintedBackgroundMode,
            ),
            const SizedBox(height: 18),
            _SettingsBlockCard(
              position: _SettingsBlockPosition.top,
              color: scheme.surfaceContainerLow,
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 10.0;
                  final itemWidth =
                      ((constraints.maxWidth - gap * 5) / 6).clamp(42.0, 72.0);

                  return Row(
                    children: List.generate(
                      SettingsScreen.accentOptions.length,
                      (index) {
                        final color = SettingsScreen.accentOptions[index];
                        final selected =
                            color.toARGB32() == widget.currentAccent.toARGB32();
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: index == SettingsScreen.accentOptions.length - 1
                                  ? 0
                                  : gap,
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(
                                selected ? 18 : 14,
                              ),
                              onTap: () => widget.onAccentChanged(color),
                              child: SizedBox(
                                height: 42,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeOutCubic,
                                    width: selected ? itemWidth : itemWidth - 4,
                                    height: selected ? 32 : 30,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(
                                        selected ? 16 : 12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _SettingsActionTile(
              position: _SettingsBlockPosition.bottom,
              icon: Icons.brightness_6_rounded,
              title: strings.tintedBackgroundMode,
              backgroundColor: scheme.surfaceContainerLow,
              iconColor: palette.badgeForeground,
              verticalPadding: 13,
              trailing: _SettingsAccentToggle(
                value: widget.experimentalTintedBackground,
                accent: palette.badgeForeground,
                activeTrack: Color.alphaBlend(
                  palette.badgeForeground.withValues(alpha: 0.34),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.96),
                ),
                inactiveTrack: Color.alphaBlend(
                  palette.badgeForeground.withValues(alpha: 0.16),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.96),
                ),
                activeThumb: palette.badgeForeground,
                inactiveThumb: Color.alphaBlend(
                  palette.badgeForeground.withValues(alpha: 0.08),
                  scheme.surfaceContainerHighest.withValues(alpha: 0.98),
                ),
              ),
              onTap: () => widget.onExperimentalTintedBackgroundChanged(
                !widget.experimentalTintedBackground,
              ),
            ),
          ],
        );
      case _SettingsTabletSection.language:
        final entries = [
          (strings.dutch, AppLanguage.nl),
          (strings.english, AppLanguage.en),
          (strings.french, AppLanguage.fr),
          (strings.german, AppLanguage.de),
          (strings.hindi, AppLanguage.hi),
          (strings.japanese, AppLanguage.ja),
          (strings.portuguese, AppLanguage.pt),
          (strings.russian, AppLanguage.ru),
          (strings.spanish, AppLanguage.es),
          (strings.swedish, AppLanguage.sv),
        ]..sort((a, b) => a.$1.compareTo(b.$1));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabletSectionHeader(
              title: strings.languageLabel,
              subtitle: strings.languageName(widget.currentLanguage),
            ),
            const SizedBox(height: 18),
            ...entries.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isFirst = index == 0;
              final isLast = index == entries.length - 1;
              final position = entries.length == 1
                  ? _SettingsBlockPosition.single
                  : isFirst
                      ? _SettingsBlockPosition.top
                      : isLast
                          ? _SettingsBlockPosition.bottom
                          : _SettingsBlockPosition.middle;
              return Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                child: _SettingsActionTile(
                  icon: null,
                  title: item.$1,
                  position: position,
                  backgroundColor: scheme.surfaceContainerLow,
                  iconColor: palette.badgeForeground,
                  trailing: item.$2 == widget.currentLanguage
                      ? Icon(
                          Icons.check_rounded,
                          color: palette.badgeForeground,
                        )
                      : null,
                  onTap: () => widget.onLanguageChanged(item.$2),
                ),
              );
            }),
          ],
        );
      case _SettingsTabletSection.analytics:
        final sortedSpiders = widget.analyticsSpiders.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        final selected = widget.analyticsSelectedIds.isEmpty
            ? sortedSpiders.map((spider) => spider.id).toSet()
            : widget.analyticsSelectedIds.toSet();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabletSectionHeader(
              title: strings.analytics,
              subtitle: strings.analyticsChoose,
            ),
            const SizedBox(height: 18),
            if (sortedSpiders.isEmpty)
              _SettingsBlockCard(
                child: Text(strings.noActiveCards),
              )
            else
              ...sortedSpiders.asMap().entries.map((entry) {
                final index = entry.key;
                final spider = entry.value;
                final checked = selected.contains(spider.id);
                final isFirst = index == 0;
                final isLast = index == sortedSpiders.length - 1;
                final position = sortedSpiders.length == 1
                    ? _SettingsBlockPosition.single
                    : isFirst
                        ? _SettingsBlockPosition.top
                        : isLast
                            ? _SettingsBlockPosition.bottom
                            : _SettingsBlockPosition.middle;
                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                  child: _SettingsActionTile(
                    icon: null,
                    title: spider.name,
                    position: position,
                    backgroundColor: scheme.surfaceContainerLow,
                    iconColor: palette.badgeForeground,
                    trailing: _RoundSelectionIndicator(
                      checked: checked,
                      accent: palette.badgeForeground,
                    ),
                    onTap: () {
                      final next = selected.toSet();
                      if (checked) {
                        next.remove(spider.id);
                      } else {
                        next.add(spider.id);
                      }
                      widget.onAnalyticsSelectionChanged(next);
                    },
                  ),
                );
              }),
          ],
        );
      case _SettingsTabletSection.backup:
        final usesDesktopFiles = !(Platform.isAndroid || Platform.isIOS);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabletSectionHeader(
              title: strings.backup,
              subtitle: strings.exportLocation,
            ),
            const SizedBox(height: 18),
            _SettingsBlockCard(
              position: _SettingsBlockPosition.top,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.exportData,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.exportLocation,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.onBackup,
                    child: Text(strings.backup),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _SettingsBlockCard(
              position: _SettingsBlockPosition.bottom,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    strings.restore,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    usesDesktopFiles
                        ? strings.pickBackupFileDesktop
                        : strings.pickBackupFile,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: palette.textMuted,
                        ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: widget.onRestoreBackup,
                    child: Text(
                      usesDesktopFiles
                          ? strings.chooseFileFromComputer
                          : strings.chooseFile,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      case _SettingsTabletSection.about:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TabletSectionHeader(
              title: strings.aboutApp,
              subtitle: '',
            ),
            const SizedBox(height: 18),
            Container(
              height: 150,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFA78BFA),
                    Color(0xFF7DD3FC),
                    Color(0xFF93C5FD),
                    Color(0xFFF9A8D4),
                    Color(0xFFFDBA74),
                    Color(0xFF86EFAC),
                  ],
                  stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  'Keeper',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontSize: 62,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SettingsBlockCard(
              position: _SettingsBlockPosition.top,
              child: Text(
                strings.aboutStub,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: palette.textPrimary,
                    ),
              ),
            ),
            const SizedBox(height: 8),
            _SettingsActionTile(
              position: _SettingsBlockPosition.middle,
              icon: Icons.open_in_new_rounded,
              title: strings.aboutSource,
              backgroundColor: scheme.surfaceContainerLow,
              iconColor: palette.badgeForeground,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => AboutScreen(language: widget.currentLanguage),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _SettingsBlockCard(
              position: _SettingsBlockPosition.bottom,
              child: AppVersionText(
                language: widget.currentLanguage,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      color: palette.textPrimary,
                    ),
              ),
            ),
          ],
        );
    }
  }
}

class _TabletSectionHeader extends StatelessWidget {
  const _TabletSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
          ),
        ],
      ],
    );
  }
}

class _SettingsTabletNavTile extends StatelessWidget {
  const _SettingsTabletNavTile({
    required this.label,
    required this.icon,
    required this.selected,
    this.position = _SettingsBlockPosition.single,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final _SettingsBlockPosition position;
  final VoidCallback onTap;

  BorderRadius _radius() {
    switch (position) {
      case _SettingsBlockPosition.single:
        return BorderRadius.circular(22);
      case _SettingsBlockPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _SettingsBlockPosition.middle:
        return BorderRadius.circular(10);
      case _SettingsBlockPosition.bottom:
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = keeperPalette(context);
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? Color.alphaBlend(
              palette.badgeForeground.withValues(alpha: 0.10),
              scheme.surfaceContainerLow,
            )
          : scheme.surfaceContainerLow.withValues(alpha: 0.38),
      borderRadius: _radius(),
      child: InkWell(
        borderRadius: _radius(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected ? palette.badgeForeground : palette.textMuted,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        color: selected
                            ? palette.textPrimary
                            : palette.textMuted,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _SettingsBlockPosition { single, top, middle, bottom }

class _SettingsBlockCard extends StatelessWidget {
  const _SettingsBlockCard({
    required this.child,
    this.position = _SettingsBlockPosition.single,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  final Widget child;
  final _SettingsBlockPosition position;
  final EdgeInsetsGeometry padding;
  final Color? color;

  BorderRadius _radius() {
    switch (position) {
      case _SettingsBlockPosition.single:
        return BorderRadius.circular(22);
      case _SettingsBlockPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _SettingsBlockPosition.middle:
        return BorderRadius.circular(10);
      case _SettingsBlockPosition.bottom:
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: color ?? scheme.surfaceContainerLow,
        borderRadius: _radius(),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    this.icon,
    required this.title,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    this.trailing,
    this.position = _SettingsBlockPosition.single,
    this.verticalPadding = 18,
  });

  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final Widget? trailing;
  final _SettingsBlockPosition position;
  final double verticalPadding;

  BorderRadius _radius() {
    switch (position) {
      case _SettingsBlockPosition.single:
        return BorderRadius.circular(22);
      case _SettingsBlockPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _SettingsBlockPosition.middle:
        return BorderRadius.circular(10);
      case _SettingsBlockPosition.bottom:
        return const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(22),
          bottomRight: Radius.circular(22),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SettingsBlockCard(
      position: position,
      padding: EdgeInsets.zero,
      child: Material(
        color: backgroundColor,
        borderRadius: _radius(),
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: iconColor),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsAccentToggle extends StatelessWidget {
  const _SettingsAccentToggle({
    required this.value,
    required this.accent,
    required this.activeTrack,
    required this.inactiveTrack,
    required this.activeThumb,
    required this.inactiveThumb,
  });

  final bool value;
  final Color accent;
  final Color activeTrack;
  final Color inactiveTrack;
  final Color activeThumb;
  final Color inactiveThumb;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value ? 1 : 0),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        builder: (context, progress, _) {
          final trackColor = Color.lerp(inactiveTrack, activeTrack, progress)!;
          final thumbColor = Color.lerp(inactiveThumb, activeThumb, progress)!;
          final shadowColor = Color.lerp(
            accent.withValues(alpha: 0.10),
            accent.withValues(alpha: 0.26),
            progress,
          )!;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            width: 50,
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: trackColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                width: value ? 22 : 20,
                height: value ? 22 : 20,
                decoration: BoxDecoration(
                  color: thumbColor,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: shadowColor,
                      blurRadius: value ? 14 : 9,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoundSelectionIndicator extends StatelessWidget {
  const _RoundSelectionIndicator({
    required this.checked,
    required this.accent,
  });

  final bool checked;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked
            ? accent
            : Color.alphaBlend(
                accent.withValues(alpha: 0.10),
                scheme.surfaceContainerHighest,
              ),
      ),
      child: checked
          ? Icon(
              Icons.check_rounded,
              size: 14,
              color: scheme.onPrimary,
            )
          : null,
    );
  }
}
