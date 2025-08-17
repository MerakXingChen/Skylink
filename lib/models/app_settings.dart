import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'app_settings.g.dart';

@HiveType(typeId: 2)
@JsonSerializable()
class AppSettings {
  @HiveField(0)
  final String locale;

  @HiveField(1)
  final ThemeMode themeMode;

  @HiveField(2)
  final bool enableAI;

  @HiveField(3)
  final bool enableSync;

  @HiveField(4)
  final bool enableNotifications;

  @HiveField(5)
  final int terminalFontSize;

  @HiveField(6)
  final String terminalFontFamily;

  @HiveField(7)
  final bool enableTerminalBell;

  @HiveField(8)
  final int maxTerminalHistory;

  @HiveField(9)
  final bool autoReconnect;

  @HiveField(10)
  final int connectionTimeout;

  @HiveField(11)
  final bool enableLogging;

  @HiveField(12)
  final LogLevel logLevel;

  @HiveField(13)
  final bool enableMetrics;

  @HiveField(14)
  final int metricsInterval;

  @HiveField(15)
  final Map<String, dynamic>? customSettings;

  const AppSettings({
    this.locale = 'en',
    this.themeMode = ThemeMode.system,
    this.enableAI = true,
    this.enableSync = false,
    this.enableNotifications = true,
    this.terminalFontSize = 14,
    this.terminalFontFamily = 'Consolas',
    this.enableTerminalBell = true,
    this.maxTerminalHistory = 1000,
    this.autoReconnect = true,
    this.connectionTimeout = 30,
    this.enableLogging = true,
    this.logLevel = LogLevel.info,
    this.enableMetrics = true,
    this.metricsInterval = 5,
    this.customSettings,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) => _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);

  AppSettings copyWith({
    String? locale,
    ThemeMode? themeMode,
    bool? enableAI,
    bool? enableSync,
    bool? enableNotifications,
    int? terminalFontSize,
    String? terminalFontFamily,
    bool? enableTerminalBell,
    int? maxTerminalHistory,
    bool? autoReconnect,
    int? connectionTimeout,
    bool? enableLogging,
    LogLevel? logLevel,
    bool? enableMetrics,
    int? metricsInterval,
    Map<String, dynamic>? customSettings,
  }) {
    return AppSettings(
      locale: locale ?? this.locale,
      themeMode: themeMode ?? this.themeMode,
      enableAI: enableAI ?? this.enableAI,
      enableSync: enableSync ?? this.enableSync,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      terminalFontSize: terminalFontSize ?? this.terminalFontSize,
      terminalFontFamily: terminalFontFamily ?? this.terminalFontFamily,
      enableTerminalBell: enableTerminalBell ?? this.enableTerminalBell,
      maxTerminalHistory: maxTerminalHistory ?? this.maxTerminalHistory,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      enableLogging: enableLogging ?? this.enableLogging,
      logLevel: logLevel ?? this.logLevel,
      enableMetrics: enableMetrics ?? this.enableMetrics,
      metricsInterval: metricsInterval ?? this.metricsInterval,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppSettings &&
        other.locale == locale &&
        other.themeMode == themeMode &&
        other.enableAI == enableAI &&
        other.enableSync == enableSync;
  }

  @override
  int get hashCode {
    return Object.hash(locale, themeMode, enableAI, enableSync);
  }
}

@HiveType(typeId: 3)
enum ThemeMode {
  @HiveField(0)
  light,
  @HiveField(1)
  dark,
  @HiveField(2)
  system,
}

@HiveType(typeId: 4)
enum LogLevel {
  @HiveField(0)
  debug,
  @HiveField(1)
  info,
  @HiveField(2)
  warning,
  @HiveField(3)
  error,
}