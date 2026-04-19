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

    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '...';
        return Text(
          strings.aboutVersion(version),
          style: style,
        );
      },
    );
  }
}
