import 'package:flutter/material.dart';

enum AppLanguage {
  en,
  ru,
}

enum SortField {
  name,
  feedingDate,
  createdDate,
}

class AppSettings {
  AppSettings({
    required this.accentColor,
    required this.language,
    this.sortField = SortField.name,
    this.sortDescending = false,
    Set<String>? analyticsIncludeIds,
  }) : analyticsIncludeIds = analyticsIncludeIds ?? <String>{};

  Color accentColor;
  AppLanguage language;
  SortField sortField;
  bool sortDescending;
  Set<String> analyticsIncludeIds;

  Map<String, dynamic> toJson() => {
        'accentColor': accentColor.toARGB32(),
        'language': language.name,
        'sortField': sortField.name,
        'sortDescending': sortDescending,
        'analyticsIncludeIds': analyticsIncludeIds.toList(),
      };

  static AppSettings fromJson(Map<String, dynamic> json) {
    return AppSettings(
      accentColor: Color(json['accentColor'] as int? ?? 0xFF86EFAC),
      language: AppLanguage.values.byName(json['language'] as String? ?? 'ru'),
      sortField: SortField.values.byName(json['sortField'] as String? ?? 'name'),
      sortDescending: json['sortDescending'] as bool? ?? false,
      analyticsIncludeIds: (json['analyticsIncludeIds'] as List<dynamic>? ?? [])
          .map((id) => id as String)
          .toSet(),
    );
  }
}
