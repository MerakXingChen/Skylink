import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/server_preview_metrics.dart';
import '../services/storage_service.dart';
import '../services/monitoring_service.dart';

// Server Metrics Provider
final serverMetricsProvider = StateNotifierProvider.family<ServerMetricsNotifier, ServerPreviewMetrics?, String>((ref, serverId) {
  return ServerMetricsNotifier(
    serverId,
    ref.read(storageServiceProvider),
    ref.read(monitoringServiceProvider),
  );
});

// All Server Metrics Provider
final allServerMetricsProvider = StateNotifierProvider<AllServerMetricsNotifier, Map<String, ServerPreviewMetrics>>((ref) {
  return AllServerMetricsNotifier(
    ref.read(storageServiceProvider),
    ref.read(monitoringServiceProvider),
  );
});

// Monitoring Status Provider
final monitoringStatusProvider = StateNotifierProvider<MonitoringStatusNotifier, MonitoringStatus>((ref) {
  return MonitoringStatusNotifier(ref.read(monitoringServiceProvider));
});

class ServerMetricsNotifier extends StateNotifier<ServerPreviewMetrics?> {
  final String serverId;
  final StorageService _storageService;
  final MonitoringService _monitoringService;
  static const String _boxName = 'server_metrics';

  ServerMetricsNotifier(
    this.serverId,
    this._storageService,
    this._monitoringService,
  ) : super(null) {
    _loadMetrics();
    _startMonitoring();
  }

  Future<void> _loadMetrics() async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      final metrics = box.get(serverId);
      if (metrics != null) {
        state = metrics;
      }
    } catch (e) {
      print('Failed to load metrics for server $serverId: $e');
    }
  }

  Future<void> _saveMetrics(ServerPreviewMetrics metrics) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      await box.put(serverId, metrics);
    } catch (e) {
      print('Failed to save metrics for server $serverId: $e');
    }
  }

  void _startMonitoring() {
    // Listen to metrics updates from monitoring service
    _monitoringService.getMetricsStream(serverId).listen((metrics) {
      state = metrics;
      _saveMetrics(metrics);
    });
  }

  Future<void> updateMetrics(ServerPreviewMetrics metrics) async {
    state = metrics;
    await _saveMetrics(metrics);
  }

  Future<void> refreshMetrics() async {
    try {
      final metrics = await _monitoringService.fetchMetrics(serverId);
      if (metrics != null) {
        state = metrics;
        await _saveMetrics(metrics);
      }
    } catch (e) {
      print('Failed to refresh metrics for server $serverId: $e');
      // Update with error state
      if (state != null) {
        final errorMetrics = state!.copyWith(
          status: ServerStatus.error,
          errorMessage: e.toString(),
          timestamp: DateTime.now(),
        );
        state = errorMetrics;
        await _saveMetrics(errorMetrics);
      }
    }
  }

  Future<void> clearMetrics() async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      await box.delete(serverId);
      state = null;
    } catch (e) {
      print('Failed to clear metrics for server $serverId: $e');
    }
  }

  @override
  void dispose() {
    _monitoringService.stopMonitoring(serverId);
    super.dispose();
  }
}

class AllServerMetricsNotifier extends StateNotifier<Map<String, ServerPreviewMetrics>> {
  final StorageService _storageService;
  final MonitoringService _monitoringService;
  static const String _boxName = 'server_metrics';

  AllServerMetricsNotifier(
    this._storageService,
    this._monitoringService,
  ) : super({}) {
    _loadAllMetrics();
    _startGlobalMonitoring();
  }

  Future<void> _loadAllMetrics() async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      final allMetrics = <String, ServerPreviewMetrics>{};
      
      for (final key in box.keys) {
        final metrics = box.get(key);
        if (metrics != null && key is String) {
          allMetrics[key] = metrics;
        }
      }
      
      state = allMetrics;
    } catch (e) {
      print('Failed to load all server metrics: $e');
    }
  }

  void _startGlobalMonitoring() {
    // Listen to all metrics updates
    _monitoringService.getAllMetricsStream().listen((allMetrics) {
      state = allMetrics;
      _saveAllMetrics(allMetrics);
    });
  }

  Future<void> _saveAllMetrics(Map<String, ServerPreviewMetrics> allMetrics) async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      
      // Clear existing data
      await box.clear();
      
      // Save new data
      for (final entry in allMetrics.entries) {
        await box.put(entry.key, entry.value);
      }
    } catch (e) {
      print('Failed to save all server metrics: $e');
    }
  }

  Future<void> refreshAllMetrics() async {
    try {
      final allMetrics = await _monitoringService.fetchAllMetrics();
      state = allMetrics;
      await _saveAllMetrics(allMetrics);
    } catch (e) {
      print('Failed to refresh all server metrics: $e');
    }
  }

  Future<void> addServerMetrics(String serverId, ServerPreviewMetrics metrics) async {
    final currentState = Map<String, ServerPreviewMetrics>.from(state);
    currentState[serverId] = metrics;
    state = currentState;
    
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      await box.put(serverId, metrics);
    } catch (e) {
      print('Failed to add metrics for server $serverId: $e');
    }
  }

  Future<void> removeServerMetrics(String serverId) async {
    final currentState = Map<String, ServerPreviewMetrics>.from(state);
    currentState.remove(serverId);
    state = currentState;
    
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      await box.delete(serverId);
    } catch (e) {
      print('Failed to remove metrics for server $serverId: $e');
    }
  }

  Future<void> clearAllMetrics() async {
    try {
      final box = await _storageService.openBox<ServerPreviewMetrics>(_boxName);
      await box.clear();
      state = {};
    } catch (e) {
      print('Failed to clear all server metrics: $e');
    }
  }

  @override
  void dispose() {
    _monitoringService.stopAllMonitoring();
    super.dispose();
  }
}

class MonitoringStatusNotifier extends StateNotifier<MonitoringStatus> {
  final MonitoringService _monitoringService;

  MonitoringStatusNotifier(this._monitoringService) : super(MonitoringStatus.stopped) {
    _initializeStatus();
  }

  void _initializeStatus() {
    // Listen to monitoring service status changes
    _monitoringService.statusStream.listen((status) {
      state = status;
    });
  }

  Future<void> startMonitoring() async {
    await _monitoringService.startGlobalMonitoring();
  }

  Future<void> stopMonitoring() async {
    await _monitoringService.stopAllMonitoring();
  }

  Future<void> pauseMonitoring() async {
    await _monitoringService.pauseMonitoring();
  }

  Future<void> resumeMonitoring() async {
    await _monitoringService.resumeMonitoring();
  }
}

enum MonitoringStatus {
  stopped,
  starting,
  running,
  paused,
  stopping,
  error,
}

// Convenience providers
final serverOnlineCountProvider = Provider<int>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  return allMetrics.values
      .where((metrics) => metrics.status == ServerStatus.online)
      .length;
});

final serverOfflineCountProvider = Provider<int>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  return allMetrics.values
      .where((metrics) => metrics.status == ServerStatus.offline)
      .length;
});

final serverErrorCountProvider = Provider<int>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  return allMetrics.values
      .where((metrics) => metrics.status == ServerStatus.error)
      .length;
});

final averageCpuUsageProvider = Provider<double>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  final onlineMetrics = allMetrics.values
      .where((metrics) => metrics.status == ServerStatus.online)
      .toList();
  
  if (onlineMetrics.isEmpty) return 0.0;
  
  final totalCpu = onlineMetrics
      .map((metrics) => metrics.cpuUsage)
      .reduce((a, b) => a + b);
  
  return totalCpu / onlineMetrics.length;
});

final averageMemoryUsageProvider = Provider<double>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  final onlineMetrics = allMetrics.values
      .where((metrics) => metrics.status == ServerStatus.online)
      .toList();
  
  if (onlineMetrics.isEmpty) return 0.0;
  
  final totalMemory = onlineMetrics
      .map((metrics) => metrics.memoryUsage)
      .reduce((a, b) => a + b);
  
  return totalMemory / onlineMetrics.length;
});

final highCpuServersProvider = Provider<List<String>>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  return allMetrics.entries
      .where((entry) => entry.value.cpuUsage > 80.0)
      .map((entry) => entry.key)
      .toList();
});

final highMemoryServersProvider = Provider<List<String>>((ref) {
  final allMetrics = ref.watch(allServerMetricsProvider);
  return allMetrics.entries
      .where((entry) => entry.value.memoryUsage > 80.0)
      .map((entry) => entry.key)
      .toList();
});