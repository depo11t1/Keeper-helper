import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/keeper_layout.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({
    super.key,
    required this.language,
    required this.accent,
    required this.onExport,
    required this.onRestore,
  });

  final AppLanguage language;
  final Color accent;
  final Future<void> Function() onExport;
  final Future<void> Function() onRestore;

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _showCheck = false;
  bool _exporting = false;

  Future<void> _handleExport() async {
    if (_exporting) {
      return;
    }
    setState(() {
      _exporting = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 32));
    await widget.onExport();
    setState(() {
      _showCheck = true;
      _exporting = false;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }
    setState(() {
      _showCheck = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(widget.language);
    final palette = keeperPalette(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.backup),
      ),
      body: KeeperCenteredBody(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            _SectionGroup(
              position: _GroupPosition.top,
              title: strings.exportData,
              description: strings.exportLocation,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: _handleExport,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: _showCheck
                        ? Icon(
                            Icons.check_rounded,
                            size: 24,
                            key: const ValueKey('check'),
                          )
                        : _exporting
                            ? SizedBox(
                                key: const ValueKey('progress'),
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    scheme.onPrimary,
                                  ),
                                ),
                              )
                            : ClipRRect(
                                key: const ValueKey('play'),
                                borderRadius: BorderRadius.circular(6),
                                child: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 26,
                                ),
                              ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SectionGroup(
              position: _GroupPosition.bottom,
              title: strings.restore,
              description: strings.pickBackupFile,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: widget.onRestore,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.accent,
                    foregroundColor: scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  child: Text(strings.chooseFile),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _GroupPosition { single, top, bottom }

class _SectionGroup extends StatelessWidget {
  const _SectionGroup({
    required this.title,
    required this.description,
    required this.child,
    required this.position,
  });

  final String title;
  final String description;
  final Widget child;
  final _GroupPosition position;

  BorderRadius _radius() {
    switch (position) {
      case _GroupPosition.single:
        return BorderRadius.circular(22);
      case _GroupPosition.top:
        return const BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(10),
        );
      case _GroupPosition.bottom:
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: _radius(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: palette.textMuted,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
