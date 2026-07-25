import 'dart:convert';
import 'dart:typed_data';

/// 衣物条目（含可选本地照片字节；落盘时照片走独立文件）。
class ClothingItem {
  ClothingItem({
    required this.id,
    required this.name,
    required this.category,
    required this.season,
    this.note,
    this.photoFileName,
    this.photo,
  });

  final String id;
  final String name;
  final String category;
  final String season; // 四季 / 春秋 / 夏 / 冬
  final String? note;
  final String? photoFileName;
  final Uint8List? photo;

  ClothingItem copyWith({
    String? id,
    String? name,
    String? category,
    String? season,
    String? note,
    String? photoFileName,
    Uint8List? photo,
    bool clearPhoto = false,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      season: season ?? this.season,
      note: note ?? this.note,
      photoFileName: clearPhoto ? null : (photoFileName ?? this.photoFileName),
      photo: clearPhoto ? null : (photo ?? this.photo),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'category': category,
        'season': season,
        'note': note,
        'photoFileName': photoFileName,
      };

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      season: json['season'] as String,
      note: json['note'] as String?,
      photoFileName: json['photoFileName'] as String?,
    );
  }
}

enum CareType { feeding, diaper, sleep }

extension CareTypeInfo on CareType {
  String get label {
    switch (this) {
      case CareType.feeding:
        return '喂奶';
      case CareType.diaper:
        return '换尿布';
      case CareType.sleep:
        return '睡觉';
    }
  }

  String get storageName => name;

  static CareType fromStorage(String raw) {
    return CareType.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => CareType.feeding,
    );
  }
}

class CareEvent {
  const CareEvent({required this.id, required this.type, required this.time});

  final String id;
  final CareType type;
  final DateTime time;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'type': type.storageName,
        'time': time.toIso8601String(),
      };

  factory CareEvent.fromJson(Map<String, dynamic> json) {
    return CareEvent(
      id: json['id'] as String,
      type: CareTypeInfo.fromStorage(json['type'] as String),
      time: DateTime.parse(json['time'] as String),
    );
  }
}

class Milestone {
  const Milestone({
    required this.id,
    required this.title,
    required this.category,
    required this.date,
    this.note,
  });

  final String id;
  final String title;
  final String category;
  final DateTime date;
  final String? note;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'category': category,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory Milestone.fromJson(Map<String, dynamic> json) {
    return Milestone(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

class GrowthEntry {
  const GrowthEntry({
    required this.id,
    required this.date,
    this.heightCm,
    this.weightKg,
    this.headCm,
  });

  final String id;
  final DateTime date;
  final double? heightCm;
  final double? weightKg;
  final double? headCm;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'date': date.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'headCm': headCm,
      };

  factory GrowthEntry.fromJson(Map<String, dynamic> json) {
    return GrowthEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      headCm: (json['headCm'] as num?)?.toDouble(),
    );
  }
}

/// 应用完整本地快照。
class AppSnapshot {
  AppSnapshot({
    this.version = 1,
    DateTime? updatedAt,
    this.wardrobeCity = '北京',
    List<ClothingItem>? wardrobeItems,
    List<CareEvent>? careEvents,
    List<Milestone>? milestones,
    List<GrowthEntry>? growthEntries,
    this.pendingSync = false,
    this.lastSyncedAt,
    this.cloudEndpoint,
  })  : updatedAt = updatedAt ?? DateTime.now(),
        wardrobeItems = wardrobeItems ?? <ClothingItem>[],
        careEvents = careEvents ?? <CareEvent>[],
        milestones = milestones ?? <Milestone>[],
        growthEntries = growthEntries ?? <GrowthEntry>[];

  final int version;
  final DateTime updatedAt;
  final String wardrobeCity;
  final List<ClothingItem> wardrobeItems;
  final List<CareEvent> careEvents;
  final List<Milestone> milestones;
  final List<GrowthEntry> growthEntries;
  final bool pendingSync;
  final DateTime? lastSyncedAt;
  final String? cloudEndpoint;

  AppSnapshot copyWith({
    int? version,
    DateTime? updatedAt,
    String? wardrobeCity,
    List<ClothingItem>? wardrobeItems,
    List<CareEvent>? careEvents,
    List<Milestone>? milestones,
    List<GrowthEntry>? growthEntries,
    bool? pendingSync,
    DateTime? lastSyncedAt,
    String? cloudEndpoint,
    bool clearLastSyncedAt = false,
    bool clearCloudEndpoint = false,
  }) {
    return AppSnapshot(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      wardrobeCity: wardrobeCity ?? this.wardrobeCity,
      wardrobeItems: wardrobeItems ?? this.wardrobeItems,
      careEvents: careEvents ?? this.careEvents,
      milestones: milestones ?? this.milestones,
      growthEntries: growthEntries ?? this.growthEntries,
      pendingSync: pendingSync ?? this.pendingSync,
      lastSyncedAt:
          clearLastSyncedAt ? null : (lastSyncedAt ?? this.lastSyncedAt),
      cloudEndpoint:
          clearCloudEndpoint ? null : (cloudEndpoint ?? this.cloudEndpoint),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'version': version,
        'updatedAt': updatedAt.toIso8601String(),
        'wardrobe': <String, dynamic>{
          'city': wardrobeCity,
          'items': wardrobeItems.map((e) => e.toJson()).toList(),
        },
        'baby': <String, dynamic>{
          'careEvents': careEvents.map((e) => e.toJson()).toList(),
          'milestones': milestones.map((e) => e.toJson()).toList(),
          'growth': growthEntries.map((e) => e.toJson()).toList(),
        },
        'sync': <String, dynamic>{
          'pending': pendingSync,
          'lastSyncedAt': lastSyncedAt?.toIso8601String(),
          'cloudEndpoint': cloudEndpoint,
        },
      };

  factory AppSnapshot.fromJson(Map<String, dynamic> json) {
    final wardrobe = (json['wardrobe'] as Map<String, dynamic>?) ??
        const <String, dynamic>{};
    final baby =
        (json['baby'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
    final sync =
        (json['sync'] as Map<String, dynamic>?) ?? const <String, dynamic>{};

    List<Map<String, dynamic>> asMaps(dynamic raw) {
      if (raw is! List) return const <Map<String, dynamic>>[];
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return AppSnapshot(
      version: (json['version'] as num?)?.toInt() ?? 1,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      wardrobeCity: (wardrobe['city'] as String?) ?? '北京',
      wardrobeItems: asMaps(wardrobe['items']).map(ClothingItem.fromJson).toList(),
      careEvents: asMaps(baby['careEvents']).map(CareEvent.fromJson).toList(),
      milestones: asMaps(baby['milestones']).map(Milestone.fromJson).toList(),
      growthEntries: asMaps(baby['growth']).map(GrowthEntry.fromJson).toList(),
      pendingSync: sync['pending'] as bool? ?? false,
      lastSyncedAt: DateTime.tryParse(sync['lastSyncedAt'] as String? ?? ''),
      cloudEndpoint: sync['cloudEndpoint'] as String?,
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());

  static AppSnapshot decode(String raw) =>
      AppSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}
