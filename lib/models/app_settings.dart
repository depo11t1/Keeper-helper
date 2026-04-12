import 'package:flutter/material.dart';

enum AppLanguage {
  en,
  ru,
}

class AppSettings {
  AppSettings({
    required this.accentColor,
    required this.language,
    Set<String>? analyticsIncludeIds,
  }) : analyticsIncludeIds = analyticsIncludeIds ?? <String>{};

  Color accentColor;
  AppLanguage language;
  Set<String> analyticsIncludeIds;

  Map<String, dynamic> toJson() => {
        'accentColor': accentColor.toARGB32(),
        'language': language.name,
        'analyticsIncludeIds': analyticsIncludeIds.toList(),
      };

  static AppSettings fromJson(Map<String, dynamic> json) {
    return AppSettings(
      accentColor: Color(json['accentColor'] as int? ?? 0xFF86EFAC),
      language: AppLanguage.values.byName(json['language'] as String? ?? 'ru'),
      analyticsIncludeIds: (json['analyticsIncludeIds'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toSet(),
    );
  }
}
