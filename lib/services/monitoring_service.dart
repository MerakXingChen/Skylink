import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import '../models/index.dart';
import 'storage_service.dart';
import 'ssh_service.dart';

// Monitoring Service Provider
final monitoringServiceProvider = Provider<MonitoringService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  final sshService = ref.watch(sshServiceProvider);
  return MonitoringService(storageService, sshService);
});

class MonitoringService {
  final StorageService _storageService;
  final SSHService _sshService;
  final Map<String, Timer> _monitoringTimers = {};
  final Map<String, StreamController<ServerPreviewMetrics>> _metricsControllers = {};
  
  bool _isMonitoring = false;
  Timer? _globalTimer;

  MonitoringService(this._storageService, this._sshService);

  /// Start monitoring all servers
  Future<void> startMonitoring({Duration interval = const Duration(seconds: 30)}) async {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    
    // Start global monitoring timer
    _globalTimer = Timer.periodic(interval, (timer) async {
      await _collectAllMetrics();
    });
    
    // Collect initial metrics
    await _collectAllMetrics();
  }

  /// Stop monitoring all servers
  Future<void> stopMonitoring() async {
    _isMonitoring = false;
    
    // Cancel global timer
    _globalTimer?.cancel();
    _globalTimer = null;
    
    // Cancel individual timers
    for (final timer in _monitoringTimers.values) {
      timer.cancel();
    }
    _monitoringTimers.clear();
  }

  /// Start monitoring a specific server
  Future<void> startServerMonitoring(
    String serverId, {
    Duration interval = const Duration(seconds: 30),
  }) async {
    // Cancel existing timer if any
    _monitoringTimers[serverId]?.cancel();
    
    // Start new timer
    _monitoringTimers[serverId] = Timer.periodic(interval, (timer) async {
      await _collectServerMetrics(serverId);
    });
    
    // Collect initial metrics
    await _collectServerMetrics(serverId);
  }

  /// Stop monitoring a specific server
  Future<void> stopServerMonitoring(String serverId) async {
    _monitoringTimers[serverId]?.cancel();
    _monitoringTimers.remove(serverId);
  }

  /// Get metrics stream for a server
  Stream<ServerPreviewMetrics> getMetricsStream(String serverId) {
    _metricsControllers[serverId] ??= StreamController<ServerPreviewMetrics>.broadcast();
    return _metricsControllers[serverId]!.stream;
  }

  /// Get latest metrics for a server
  Future<ServerPreviewMetrics?> getLatestMetrics(String serverId) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics');
      return box.get(serverId);
    } catch (e) {
      print('Failed to get latest metrics for server $serverId: $e');
      return null;
    }
  }

  /// Get historical metrics for a server
  Future<List<ServerPreviewMetrics>> getHistoricalMetrics(
    String serverId, {
    DateTime? startTime,
    DateTime? endTime,
    int? limit,
  }) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics_history');
      final allMetrics = box.values.where((metrics) => metrics.serverId == serverId).toList();
      
      // Filter by time range
      var filteredMetrics = allMetrics;
      if (startTime != null) {
        filteredMetrics = filteredMetrics.where((m) => m.timestamp.isAfter(startTime)).toList();
      }
      if (endTime != null) {
        filteredMetrics = filteredMetrics.where((m) => m.timestamp.isBefore(endTime)).toList();
      }
      
      // Sort by timestamp
      filteredMetrics.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Apply limit
      if (limit != null && filteredMetrics.length > limit) {
        filteredMetrics = filteredMetrics.sublist(filteredMetrics.length - limit);
      }
      
      return filteredMetrics;
    } catch (e) {
      print('Failed to get historical metrics for server $serverId: $e');
      return [];
    }
  }

  /// Collect metrics for all connected servers
  Future<void> _collectAllMetrics() async {
    final activeSessions = _sshService.activeSessions;
    
    await Future.wait(
      activeSessions.keys.map((serverId) => _collectServerMetrics(serverId)),
    );
  }

  /// Collect metrics for a specific server
  Future<void> _collectServerMetrics(String serverId) async {
    try {
      final session = _sshService.getSession(serverId);
      if (session == null || !session.isConnected) {
        await _updateServerStatus(serverId, ServerStatus.offline);
        return;
      }

      // Collect system metrics
      final metrics = await _gatherSystemMetrics(serverId);
      
      if (metrics != null) {
        // Store latest metrics
        await _storeLatestMetrics(metrics);
        
        // Store historical metrics
        await _storeHistoricalMetrics(metrics);
        
        // Emit metrics to stream
        _emitMetrics(serverId, metrics);
        
        // Update server status
        await _updateServerStatus(serverId, ServerStatus.online);
      } else {
        await _updateServerStatus(serverId, ServerStatus.error, 'Failed to collect metrics');
      }
    } catch (e) {
      print('Error collecting metrics for server $serverId: $e');
      await _updateServerStatus(serverId, ServerStatus.error, e.toString());
    }
  }

  /// Gather system metrics from server
  Future<ServerPreviewMetrics?> _gatherSystemMetrics(String serverId) async {
    try {
      // Collect CPU usage
      final cpuUsage = await _getCpuUsage(serverId);
      
      // Collect memory usage
      final memoryUsage = await _getMemoryUsage(serverId);
      
      // Collect disk usage
      final diskUsage = await _getDiskUsage(serverId);
      
      // Collect load average
      final loadAverage = await _getLoadAverage(serverId);
      
      // Collect network metrics
      final networkMetrics = await _getNetworkMetrics(serverId);
      
      // Collect additional metrics
      final additionalMetrics = await _getAdditionalMetrics(serverId);

      return ServerPreviewMetrics(
        serverId: serverId,
        cpuUsage: cpuUsage,
        memoryUsage: memoryUsage,
        diskUsage: diskUsage,
        loadAverage: loadAverage,
        networkMetrics: networkMetrics,
        serverStatus: ServerStatus.online,
        timestamp: DateTime.now(),
        additionalMetrics: additionalMetrics,
      );
    } catch (e) {
      print('Failed to gather system metrics for server $serverId: $e');
      return null;
    }
  }

  /// Get CPU usage percentage
  Future<double> _getCpuUsage(String serverId) async {
    try {
      final result = await _sshService.executeCommand(
        serverId,
        "top -bn1 | grep 'Cpu(s)' | awk '{print \$2}' | awk -F'%' '{print \$1}'",
        timeout: const Duration(seconds: 10),
      );
      
      if (result.isSuccess && result.stdout?.isNotEmpty == true) {
        final cpuStr = result.stdout!.trim();
        return double.tryParse(cpuStr) ?? 0.0;
      }
      
      // Fallback method
      final fallbackResult = await _sshService.executeCommand(
        serverId,
        "grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$3+\$4+\$5)} END {print usage}'",
        timeout: const Duration(seconds: 10),
      );
      
      if (fallbackResult.isSuccess && fallbackResult.stdout?.isNotEmpty == true) {
        return double.tryParse(fallbackResult.stdout!.trim()) ?? 0.0;
      }
      
      return 0.0;
    } catch (e) {
      print('Failed to get CPU usage for server $serverId: $e');
      return 0.0;
    }
  }

  /// Get memory usage percentage
  Future<double> _getMemoryUsage(String serverId) async {
    try {
      final result = await _sshService.executeCommand(
        serverId,
        "free | grep Mem | awk '{printf \"%.2f\", \$3/\$2 * 100.0}'",
        timeout: const Duration(seconds: 10),
      );
      
      if (result.isSuccess && result.stdout?.isNotEmpty == true) {
        return double.tryParse(result.stdout!.trim()) ?? 0.0;
      }
      
      return 0.0;
    } catch (e) {
      print('Failed to get memory usage for server $serverId: $e');
      return 0.0;
    }
  }

  /// Get disk usage percentage
  Future<double> _getDiskUsage(String serverId) async {
    try {
      final result = await _sshService.executeCommand(
        serverId,
        "df -h / | awk 'NR==2{printf \"%s\", \$5}' | sed 's/%//'",
        timeout: const Duration(seconds: 10),
      );
      
      if (result.isSuccess && result.stdout?.isNotEmpty == true) {
        return double.tryParse(result.stdout!.trim()) ?? 0.0;
      }
      
      return 0.0;
    } catch (e) {
      print('Failed to get disk usage for server $serverId: $e');
      return 0.0;
    }
  }

  /// Get load average
  Future<double> _getLoadAverage(String serverId) async {
    try {
      final result = await _sshService.executeCommand(
        serverId,
        "uptime | awk -F'load average:' '{print \$2}' | awk -F',' '{print \$1}' | xargs",
        timeout: const Duration(seconds: 10),
      );
      
      if (result.isSuccess && result.stdout?.isNotEmpty == true) {
        return double.tryParse(result.stdout!.trim()) ?? 0.0;
      }
      
      return 0.0;
    } catch (e) {
      print('Failed to get load average for server $serverId: $e');
      return 0.0;
    }
  }

  /// Get network metrics
  Future<NetworkMetrics?> _getNetworkMetrics(String serverId) async {
    try {
      // Get network interface statistics
      final result = await _sshService.executeCommand(
        serverId,
        "cat /proc/net/dev | grep -E '(eth0|ens|enp|wlan)' | head -1 | awk '{print \$2,\$10}'",
        timeout: const Duration(seconds: 10),
      );
      
      if (result.isSuccess && result.stdout?.isNotEmpty == true) {
        final parts = result.stdout!.trim().split(' ');
        if (parts.length >= 2) {
          final bytesReceived = int.tryParse(parts[0]) ?? 0;
          final bytesTransmitted = int.tryParse(parts[1]) ?? 0;
          
          return NetworkMetrics(
            uploadSpeed: bytesTransmitted.toDouble(),
            downloadSpeed: bytesReceived.toDouble(),
            totalUploaded: bytesTransmitted,
            totalDownloaded: bytesReceived,
          );
        }
      }
      
      return null;
    } catch (e) {
      print('Failed to get network metrics for server $serverId: $e');
      return null;
    }
  }

  /// Get additional system metrics
  Future<Map<String, dynamic>> _getAdditionalMetrics(String serverId) async {
    final metrics = <String, dynamic>{};
    
    try {
      // Get uptime
      final uptimeResult = await _sshService.executeCommand(
        serverId,
        "uptime -p",
        timeout: const Duration(seconds: 5),
      );
      if (uptimeResult.isSuccess) {
        metrics['uptime'] = uptimeResult.stdout?.trim();
      }
      
      // Get process count
      final processResult = await _sshService.executeCommand(
        serverId,
        "ps aux | wc -l",
        timeout: const Duration(seconds: 5),
      );
      if (processResult.isSuccess) {
        metrics['process_count'] = int.tryParse(processResult.stdout?.trim() ?? '0');
      }
      
      // Get logged in users
      final usersResult = await _sshService.executeCommand(
        serverId,
        "who | wc -l",
        timeout: const Duration(seconds: 5),
      );
      if (usersResult.isSuccess) {
        metrics['logged_users'] = int.tryParse(usersResult.stdout?.trim() ?? '0');
      }
      
      // Get system temperature (if available)
      final tempResult = await _sshService.executeCommand(
        serverId,
        "sensors | grep 'Core 0' | awk '{print \$3}' | sed 's/+//;s/°C//'",
        timeout: const Duration(seconds: 5),
      );
      if (tempResult.isSuccess && tempResult.stdout?.isNotEmpty == true) {
        metrics['temperature'] = double.tryParse(tempResult.stdout!.trim());
      }
      
    } catch (e) {
      print('Failed to get additional metrics for server $serverId: $e');
    }
    
    return metrics;
  }

  /// Store latest metrics
  Future<void> _storeLatestMetrics(ServerPreviewMetrics metrics) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics');
      await box.put(metrics.serverId, metrics);
    } catch (e) {
      print('Failed to store latest metrics: $e');
    }
  }

  /// Store historical metrics
  Future<void> _storeHistoricalMetrics(ServerPreviewMetrics metrics) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics_history');
      final key = '${metrics.serverId}_${metrics.timestamp.millisecondsSinceEpoch}';
      await box.put(key, metrics);
      
      // Clean up old metrics (keep last 1000 entries per server)
      await _cleanupHistoricalMetrics(metrics.serverId);
    } catch (e) {
      print('Failed to store historical metrics: $e');
    }
  }

  /// Clean up old historical metrics
  Future<void> _cleanupHistoricalMetrics(String serverId, {int maxEntries = 1000}) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics_history');
      final serverMetrics = box.values
          .where((metrics) => metrics.serverId == serverId)
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      if (serverMetrics.length > maxEntries) {
        final toRemove = serverMetrics.length - maxEntries;
        for (int i = 0; i < toRemove; i++) {
          final key = '${serverMetrics[i].serverId}_${serverMetrics[i].timestamp.millisecondsSinceEpoch}';
          await box.delete(key);
        }
      }
    } catch (e) {
      print('Failed to cleanup historical metrics: $e');
    }
  }

  /// Update server status
  Future<void> _updateServerStatus(String serverId, ServerStatus status, [String? error]) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics');
      final existingMetrics = box.get(serverId);
      
      if (existingMetrics != null) {
        final updatedMetrics = ServerPreviewMetrics(
          serverId: serverId,
          cpuUsage: existingMetrics.cpuUsage,
          memoryUsage: existingMetrics.memoryUsage,
          diskUsage: existingMetrics.diskUsage,
          loadAverage: existingMetrics.loadAverage,
          networkMetrics: existingMetrics.networkMetrics,
          serverStatus: status,
          timestamp: DateTime.now(),
          errorMessage: error,
          additionalMetrics: existingMetrics.additionalMetrics,
        );
        
        await box.put(serverId, updatedMetrics);
        _emitMetrics(serverId, updatedMetrics);
      } else {
        // Create minimal metrics entry for status update
        final metrics = ServerPreviewMetrics(
          serverId: serverId,
          cpuUsage: 0.0,
          memoryUsage: 0.0,
          diskUsage: 0.0,
          loadAverage: 0.0,
          networkMetrics: null,
          serverStatus: status,
          timestamp: DateTime.now(),
          errorMessage: error,
          additionalMetrics: const {},
        );
        
        await box.put(serverId, metrics);
        _emitMetrics(serverId, metrics);
      }
    } catch (e) {
      print('Failed to update server status: $e');
    }
  }

  /// Emit metrics to stream
  void _emitMetrics(String serverId, ServerPreviewMetrics metrics) {
    final controller = _metricsControllers[serverId];
    if (controller != null && !controller.isClosed) {
      controller.add(metrics);
    }
  }

  /// Get monitoring statistics
  MonitoringStats getMonitoringStats() {
    return MonitoringStats(
      isMonitoring: _isMonitoring,
      monitoredServers: _monitoringTimers.length,
      activeStreams: _metricsControllers.length,
    );
  }

  /// Export metrics data
  Future<String> exportMetrics({
    String? serverId,
    DateTime? startTime,
    DateTime? endTime,
    String format = 'json',
  }) async {
    try {
      List<ServerPreviewMetrics> metrics;
      
      if (serverId != null) {
        metrics = await getHistoricalMetrics(
          serverId,
          startTime: startTime,
          endTime: endTime,
        );
      } else {
        // Get metrics for all servers
        final box = await _storageService.openBox<ServerPreviewMetrics>('server_metrics_history');
        metrics = box.values.toList();
        
        // Filter by time range
        if (startTime != null) {
          metrics = metrics.where((m) => m.timestamp.isAfter(startTime)).toList();
        }
        if (endTime != null) {
          metrics = metrics.where((m) => m.timestamp.isBefore(endTime)).toList();
        }
      }
      
      switch (format.toLowerCase()) {
        case 'json':
          return json.encode(metrics.map((m) => m.toJson()).toList());
        case 'csv':
          return _exportToCsv(metrics);
        default:
          throw Exception('Unsupported export format: $format');
      }
    } catch (e) {
      print('Failed to export metrics: $e');
      rethrow;
    }
  }

  /// Export metrics to CSV format
  String _exportToCsv(List<ServerPreviewMetrics> metrics) {
    final buffer = StringBuffer();
    
    // CSV header
    buffer.writeln('ServerId,Timestamp,CPUUsage,MemoryUsage,DiskUsage,LoadAverage,Status,Error');
    
    // CSV data
    for (final metric in metrics) {
      buffer.writeln([
        metric.serverId,
        metric.timestamp.toIso8601String(),
        metric.cpuUsage,
        metric.memoryUsage,
        metric.diskUsage,
        metric.loadAverage,
        metric.serverStatus.name,
        metric.errorMessage ?? '',
      ].join(','));
    }
    
    return buffer.toString();
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
    
    for (final controller in _metricsControllers.values) {
      controller.close();
    }
    _metricsControllers.clear();
  }
}

class MonitoringStats {
  final bool isMonitoring;
  final int monitoredServers;
  final int activeStreams;

  const MonitoringStats({
    required this.isMonitoring,
    required this.monitoredServers,
    required this.activeStreams,
  });
}