import 'package:flutter/material.dart';

// Пол паука. Unknown нужен, когда пользователь пока не знает пол.
enum SpiderSex {
  female,
  male,
  unknown,
}

class FeedingEntry {
  FeedingEntry({
    required this.date,
    this.note,
  });

  DateTime date;
  String? note;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'note': note,
      };

  static FeedingEntry fromJson(Map<String, dynamic> json) {
    return FeedingEntry(
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

// Одна запись о линьке с датой и возрастной стадией L1-L15.
class MoltEntry {
  MoltEntry({
    required this.date,
    required this.stage,
  });

  DateTime date;
  String stage;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'stage': stage,
      };

  static MoltEntry fromJson(Map<String, dynamic> json) {
    return MoltEntry(
      date: DateTime.parse(json['date'] as String),
      stage: json['stage'] as String,
    );
  }
}

// Основная модель карточки животного.
// Пока в проекте это паук, но структура уже довольно универсальна.
class SpiderProfile {
  SpiderProfile({
    required this.id,
    required this.name,
    required this.latinName,
    required this.sex,
    required this.humidity,
    required this.avatarSeed,
    required this.accent,
    required this.feedings,
    required this.molts,
    this.archived = false,
    this.archivedAt,
    this.photoPath,
  });

  final String id;
  String name;
  String latinName;
  SpiderSex sex;
  int humidity;
  int avatarSeed;
  Color accent;
  bool archived;
  DateTime? archivedAt;
  String? photoPath;
  final List<FeedingEntry> feedings;
  final List<MoltEntry> molts;

  FeedingEntry? get lastFeeding =>
      feedings.isEmpty ? null : (feedings.toList()..sort(_sortDesc)).first;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latinName': latinName,
        'sex': sex.name,
        'humidity': humidity,
        'avatarSeed': avatarSeed,
        'accent': accent.toARGB32(),
        'archived': archived,
        'archivedAt': archivedAt?.toIso8601String(),
        'photoPath': photoPath,
        'feedings': feedings.map((entry) => entry.toJson()).toList(),
        'molts': molts.map((entry) => entry.toJson()).toList(),
      };

  static SpiderProfile fromJson(Map<String, dynamic> json) {
    return SpiderProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      latinName: json['latinName'] as String? ?? '',
      sex: SpiderSex.values.byName(json['sex'] as String? ?? 'unknown'),
      humidity: json['humidity'] as int? ?? 70,
      avatarSeed: json['avatarSeed'] as int? ?? -1,
      accent: Color(json['accent'] as int? ?? 0xFF86EFAC),
      archived: json['archived'] as bool? ?? false,
      archivedAt: json['archivedAt'] == null
          ? null
          : DateTime.parse(json['archivedAt'] as String),
      photoPath: json['photoPath'] as String?,
      feedings: (json['feedings'] as List<dynamic>? ?? [])
          .map((entry) => FeedingEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
      molts: (json['molts'] as List<dynamic>? ?? [])
          .map((entry) => MoltEntry.fromJson(entry as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _sortDesc(dynamic a, dynamic b) =>
      (b.date as DateTime).compareTo(a.date as DateTime);
}
