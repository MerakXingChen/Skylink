import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'widget_layout.g.dart';

@HiveType(typeId: 13)
@JsonSerializable()
class WidgetLayout {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final WidgetType type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final WidgetPosition position;

  @HiveField(4)
  final WidgetSize size;

  @HiveField(5)
  final bool visible;

  @HiveField(6)
  final String? serverId;

  @HiveField(7)
  final Map<String, dynamic>? config;

  @HiveField(8)
  final DateTime createdAt;

  @HiveField(9)
  final DateTime updatedAt;

  const WidgetLayout({
    required this.id,
    required this.type,
    required this.title,
    required this.position,
    required this.size,
    this.visible = true,
    this.serverId,
    this.config,
    required this.createdAt,
    required this.updatedAt,
  });

  factory WidgetLayout.fromJson(Map<String, dynamic> json) => _$WidgetLayoutFromJson(json);
  Map<String, dynamic> toJson() => _$WidgetLayoutToJson(this);

  WidgetLayout copyWith({
    String? id,
    WidgetType? type,
    String? title,
    WidgetPosition? position,
    WidgetSize? size,
    bool? visible,
    String? serverId,
    Map<String, dynamic>? config,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WidgetLayout(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      position: position ?? this.position,
      size: size ?? this.size,
      visible: visible ?? this.visible,
      serverId: serverId ?? this.serverId,
      config: config ?? this.config,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetLayout && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 14)
@JsonSerializable()
class WidgetPosition {
  @HiveField(0)
  final int x;

  @HiveField(1)
  final int y;

  const WidgetPosition({
    required this.x,
    required this.y,
  });

  factory WidgetPosition.fromJson(Map<String, dynamic> json) => _$WidgetPositionFromJson(json);
  Map<String, dynamic> toJson() => _$WidgetPositionToJson(this);

  WidgetPosition copyWith({
    int? x,
    int? y,
  }) {
    return WidgetPosition(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetPosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

@HiveType(typeId: 15)
@JsonSerializable()
class WidgetSize {
  @HiveField(0)
  final int width;

  @HiveField(1)
  final int height;

  const WidgetSize({
    required this.width,
    required this.height,
  });

  factory WidgetSize.fromJson(Map<String, dynamic> json) => _$WidgetSizeFromJson(json);
  Map<String, dynamic> toJson() => _$WidgetSizeToJson(this);

  WidgetSize copyWith({
    int? width,
    int? height,
  }) {
    return WidgetSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WidgetSize && other.width == width && other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

@HiveType(typeId: 16)
enum WidgetType {
  @HiveField(0)
  serverPreview,
  @HiveField(1)
  cpuChart,
  @HiveField(2)
  memoryChart,
  @HiveField(3)
  diskChart,
  @HiveField(4)
  networkChart,
  @HiveField(5)
  quickActions,
  @HiveField(6)
  terminalShortcut,
  @HiveField(7)
  fileManagerShortcut,
  @HiveField(8)
  aiAssistant,
  @HiveField(9)
  systemInfo,
  @HiveField(10)
  custom,
}