import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'sync_config.g.dart';

@HiveType(typeId: 7)
@JsonSerializable()
class SyncConfig {
  @HiveField(0)
  final bool enabled;

  @HiveField(1)
  final SyncProvider provider;

  @HiveField(2)
  final String? serverUrl;

  @HiveField(3)
  final String? username;

  @HiveField(4)
  final String? password;

  @HiveField(5)
  final String remotePath;

  @HiveField(6)
  final SyncMode syncMode;

  @HiveField(7)
  final int syncInterval;

  @HiveField(8)
  final bool autoSync;

  @HiveField(9)
  final bool syncOnStartup;

  @HiveField(10)
  final bool syncOnExit;

  @HiveField(11)
  final List<String> excludePatterns;

  @HiveField(12)
  final DateTime? lastSyncAt;

  @HiveField(13)
  final String? lastSyncError;

  @HiveField(14)
  final Map<String, dynamic>? customSettings;

  const SyncConfig({
    this.enabled = false,
    this.provider = SyncProvider.webdav,
    this.serverUrl,
    this.username,
    this.password,
    this.remotePath = '/skylink',
    this.syncMode = SyncMode.bidirectional,
    this.syncInterval = 300, // 5 minutes
    this.autoSync = false,
    this.syncOnStartup = false,
    this.syncOnExit = false,
    this.excludePatterns = const [],
    this.lastSyncAt,
    this.lastSyncError,
    this.customSettings,
  });

  factory SyncConfig.fromJson(Map<String, dynamic> json) => _$SyncConfigFromJson(json);
  Map<String, dynamic> toJson() => _$SyncConfigToJson(this);

  SyncConfig copyWith({
    bool? enabled,
    SyncProvider? provider,
    String? serverUrl,
    String? username,
    String? password,
    String? remotePath,
    SyncMode? syncMode,
    int? syncInterval,
    bool? autoSync,
    bool? syncOnStartup,
    bool? syncOnExit,
    List<String>? excludePatterns,
    DateTime? lastSyncAt,
    String? lastSyncError,
    Map<String, dynamic>? customSettings,
  }) {
    return SyncConfig(
      enabled: enabled ?? this.enabled,
      provider: provider ?? this.provider,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      syncMode: syncMode ?? this.syncMode,
      syncInterval: syncInterval ?? this.syncInterval,
      autoSync: autoSync ?? this.autoSync,
      syncOnStartup: syncOnStartup ?? this.syncOnStartup,
      syncOnExit: syncOnExit ?? this.syncOnExit,
      excludePatterns: excludePatterns ?? this.excludePatterns,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      lastSyncError: lastSyncError ?? this.lastSyncError,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  bool get isConfigured {
    return serverUrl != null &&
        serverUrl!.isNotEmpty &&
        username != null &&
        username!.isNotEmpty &&
        password != null &&
        password!.isNotEmpty;
  }

  String get displayName {
    switch (provider) {
      case SyncProvider.webdav:
        return 'WebDAV';
      case SyncProvider.nextcloud:
        return 'Nextcloud';
      case SyncProvider.owncloud:
        return 'ownCloud';
      case SyncProvider.custom:
        return 'Custom';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SyncConfig &&
        other.enabled == enabled &&
        other.provider == provider &&
        other.serverUrl == serverUrl;
  }

  @override
  int get hashCode {
    return Object.hash(enabled, provider, serverUrl);
  }
}

@HiveType(typeId: 8)
enum SyncProvider {
  @HiveField(0)
  webdav,
  @HiveField(1)
  nextcloud,
  @HiveField(2)
  owncloud,
  @HiveField(3)
  custom,
}

@HiveType(typeId: 9)
enum SyncMode {
  @HiveField(0)
  upload, // Local to remote only
  @HiveField(1)
  download, // Remote to local only
  @HiveField(2)
  bidirectional, // Both directions
}