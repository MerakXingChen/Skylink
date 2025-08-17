import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'window_state.g.dart';

@HiveType(typeId: 17)
@JsonSerializable()
class WindowState {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final WindowType type;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final WindowPosition position;

  @HiveField(4)
  final WindowSize size;

  @HiveField(5)
  final bool isMaximized;

  @HiveField(6)
  final bool isMinimized;

  @HiveField(7)
  final bool isVisible;

  @HiveField(8)
  final String? serverId;

  @HiveField(9)
  final String? sessionId;

  @HiveField(10)
  final Map<String, dynamic>? metadata;

  @HiveField(11)
  final DateTime createdAt;

  @HiveField(12)
  final DateTime lastActiveAt;

  const WindowState({
    required this.id,
    required this.type,
    required this.title,
    required this.position,
    required this.size,
    this.isMaximized = false,
    this.isMinimized = false,
    this.isVisible = true,
    this.serverId,
    this.sessionId,
    this.metadata,
    required this.createdAt,
    required this.lastActiveAt,
  });

  factory WindowState.fromJson(Map<String, dynamic> json) => _$WindowStateFromJson(json);
  Map<String, dynamic> toJson() => _$WindowStateToJson(this);

  WindowState copyWith({
    String? id,
    WindowType? type,
    String? title,
    WindowPosition? position,
    WindowSize? size,
    bool? isMaximized,
    bool? isMinimized,
    bool? isVisible,
    String? serverId,
    String? sessionId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastActiveAt,
  }) {
    return WindowState(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      position: position ?? this.position,
      size: size ?? this.size,
      isMaximized: isMaximized ?? this.isMaximized,
      isMinimized: isMinimized ?? this.isMinimized,
      isVisible: isVisible ?? this.isVisible,
      serverId: serverId ?? this.serverId,
      sessionId: sessionId ?? this.sessionId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowState && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

@HiveType(typeId: 18)
@JsonSerializable()
class WindowPosition {
  @HiveField(0)
  final double x;

  @HiveField(1)
  final double y;

  const WindowPosition({
    required this.x,
    required this.y,
  });

  factory WindowPosition.fromJson(Map<String, dynamic> json) => _$WindowPositionFromJson(json);
  Map<String, dynamic> toJson() => _$WindowPositionToJson(this);

  WindowPosition copyWith({
    double? x,
    double? y,
  }) {
    return WindowPosition(
      x: x ?? this.x,
      y: y ?? this.y,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowPosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);
}

@HiveType(typeId: 19)
@JsonSerializable()
class WindowSize {
  @HiveField(0)
  final double width;

  @HiveField(1)
  final double height;

  const WindowSize({
    required this.width,
    required this.height,
  });

  factory WindowSize.fromJson(Map<String, dynamic> json) => _$WindowSizeFromJson(json);
  Map<String, dynamic> toJson() => _$WindowSizeToJson(this);

  WindowSize copyWith({
    double? width,
    double? height,
  }) {
    return WindowSize(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WindowSize && other.width == width && other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

@HiveType(typeId: 20)
enum WindowType {
  @HiveField(0)
  main,
  @HiveField(1)
  terminal,
  @HiveField(2)
  fileManager,
  @HiveField(3)
  monitoring,
  @HiveField(4)
  settings,
  @HiveField(5)
  aiAssistant,
  @HiveField(6)
  serverDetails,
  @HiveField(7)
  custom,
}