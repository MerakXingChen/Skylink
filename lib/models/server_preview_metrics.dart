import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server_preview_metrics.g.dart';

@HiveType(typeId: 10)
@JsonSerializable()
class ServerPreviewMetrics {
  @HiveField(0)
  final String serverId;

  @HiveField(1)
  final double cpuUsage;

  @HiveField(2)
  final double memoryUsage;

  @HiveField(3)
  final double diskUsage;

  @HiveField(4)
  final double loadAverage;

  @HiveField(5)
  final NetworkMetrics? networkMetrics;

  @HiveField(6)
  final ServerStatus status;

  @HiveField(7)
  final DateTime timestamp;

  @HiveField(8)
  final String? errorMessage;

  @HiveField(9)
  final Map<String, dynamic>? additionalMetrics;

  const ServerPreviewMetrics({
    required this.serverId,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.loadAverage,
    this.networkMetrics,
    required this.status,
    required this.timestamp,
    this.errorMessage,
    this.additionalMetrics,
  });

  factory ServerPreviewMetrics.fromJson(Map<String, dynamic> json) => _$ServerPreviewMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$ServerPreviewMetricsToJson(this);

  ServerPreviewMetrics copyWith({
    String? serverId,
    double? cpuUsage,
    double? memoryUsage,
    double? diskUsage,
    double? loadAverage,
    NetworkMetrics? networkMetrics,
    ServerStatus? status,
    DateTime? timestamp,
    String? errorMessage,
    Map<String, dynamic>? additionalMetrics,
  }) {
    return ServerPreviewMetrics(
      serverId: serverId ?? this.serverId,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      memoryUsage: memoryUsage ?? this.memoryUsage,
      diskUsage: diskUsage ?? this.diskUsage,
      loadAverage: loadAverage ?? this.loadAverage,
      networkMetrics: networkMetrics ?? this.networkMetrics,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
    );
  }

  bool get isHealthy {
    return status == ServerStatus.online &&
        cpuUsage < 90.0 &&
        memoryUsage < 90.0 &&
        diskUsage < 90.0;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerPreviewMetrics &&
        other.serverId == serverId &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(serverId, timestamp);
  }
}

@HiveType(typeId: 11)
@JsonSerializable()
class NetworkMetrics {
  @HiveField(0)
  final double uploadSpeed; // bytes per second

  @HiveField(1)
  final double downloadSpeed; // bytes per second

  @HiveField(2)
  final String interfaceName;

  @HiveField(3)
  final int packetsIn;

  @HiveField(4)
  final int packetsOut;

  @HiveField(5)
  final int errorsIn;

  @HiveField(6)
  final int errorsOut;

  const NetworkMetrics({
    required this.uploadSpeed,
    required this.downloadSpeed,
    required this.interfaceName,
    required this.packetsIn,
    required this.packetsOut,
    this.errorsIn = 0,
    this.errorsOut = 0,
  });

  factory NetworkMetrics.fromJson(Map<String, dynamic> json) => _$NetworkMetricsFromJson(json);
  Map<String, dynamic> toJson() => _$NetworkMetricsToJson(this);

  String get formattedUploadSpeed => _formatBytes(uploadSpeed);
  String get formattedDownloadSpeed => _formatBytes(downloadSpeed);

  static String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(1)} B/s';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB/s';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }
}

@HiveType(typeId: 12)
enum ServerStatus {
  @HiveField(0)
  online,
  @HiveField(1)
  offline,
  @HiveField(2)
  connecting,
  @HiveField(3)
  error,
  @HiveField(4)
  unknown,
}