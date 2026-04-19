import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_strings.dart';
import '../models/app_settings.dart';

class AppVersionText extends StatelessWidget {
  const AppVersionText({
    super.key,
    required this.language,
    this.style,
  });

  final AppLanguage language;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(language);
    const buildName = String.fromEnvironment('FLUTTER_BUILD_NAME');
    final compiledVersion = buildName.isEmpty ? null : buildName;

    if (compiledVersion != null) {
      return Text(
        strings.aboutVersion(compiledVersion),
        style: style,
      );
    }

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        final version = info?.version ?? '...';
        return Text(
          strings.aboutVersion(version),
          style: style,
        );
      },
    );
  }
}
