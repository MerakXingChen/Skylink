import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../models/index.dart';
import 'storage_service.dart';

// Sync Service Provider
final syncServiceProvider = Provider<SyncService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SyncService(storageService);
});

class SyncService {
  final StorageService _storageService;
  Timer? _autoSyncTimer;
  bool _isSyncing = false;
  
  SyncService(this._storageService);

  /// Test WebDAV connection
  Future<SyncTestResult> testConnection(SyncConfig config) async {
    try {
      final client = http.Client();
      final uri = Uri.parse('${config.serverUrl}${config.remotePath}');
      
      // Create authorization header
      final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
      final headers = {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/xml',
      };
      
      // Send PROPFIND request to test connection
      final response = await client.send(http.Request('PROPFIND', uri)
        ..headers.addAll(headers)
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getcontentlength/>
    <D:getlastmodified/>
  </D:prop>
</D:propfind>''');
      
      client.close();
      
      if (response.statusCode == 207 || response.statusCode == 200) {
        return SyncTestResult(
          isSuccess: true,
          message: 'Connection successful',
          responseTime: DateTime.now().difference(DateTime.now()).inMilliseconds,
        );
      } else {
        return SyncTestResult(
          isSuccess: false,
          message: 'Connection failed: HTTP ${response.statusCode}',
          error: 'HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return SyncTestResult(
        isSuccess: false,
        message: 'Connection failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Start automatic sync
  Future<void> startAutoSync(SyncConfig config) async {
    if (!config.enabled || !config.autoSync) return;
    
    _autoSyncTimer?.cancel();
    
    final interval = Duration(minutes: config.syncInterval);
    _autoSyncTimer = Timer.periodic(interval, (timer) async {
      await performSync(config, SyncMode.bidirectional);
    });
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
  }

  /// Perform sync operation
  Future<SyncResult> performSync(SyncConfig config, SyncMode mode) async {
    if (_isSyncing) {
      return SyncResult(
        isSuccess: false,
        message: 'Sync already in progress',
        error: 'Sync already in progress',
      );
    }
    
    _isSyncing = true;
    final startTime = DateTime.now();
    
    try {
      switch (mode) {
        case SyncMode.upload:
          return await _uploadData(config);
        case SyncMode.download:
          return await _downloadData(config);
        case SyncMode.bidirectional:
          return await _bidirectionalSync(config);
      }
    } finally {
      _isSyncing = false;
    }
  }

  /// Upload local data to remote
  Future<SyncResult> _uploadData(SyncConfig config) async {
    try {
      final localData = await _exportLocalData(config);
      final uploadResult = await _uploadToWebDAV(config, localData);
      
      if (uploadResult.isSuccess) {
        await _updateSyncConfig(config.copyWith(
          lastSyncTime: DateTime.now(),
          lastSyncError: null,
        ));
        
        return SyncResult(
          isSuccess: true,
          message: 'Upload completed successfully',
          uploadedFiles: uploadResult.uploadedFiles,
          uploadedSize: uploadResult.uploadedSize,
        );
      } else {
        await _updateSyncConfig(config.copyWith(
          lastSyncError: uploadResult.error,
        ));
        
        return uploadResult;
      }
    } catch (e) {
      await _updateSyncConfig(config.copyWith(
        lastSyncError: e.toString(),
      ));
      
      return SyncResult(
        isSuccess: false,
        message: 'Upload failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Download remote data to local
  Future<SyncResult> _downloadData(SyncConfig config) async {
    try {
      final downloadResult = await _downloadFromWebDAV(config);
      
      if (downloadResult.isSuccess && downloadResult.data != null) {
        await _importLocalData(config, downloadResult.data!);
        
        await _updateSyncConfig(config.copyWith(
          lastSyncTime: DateTime.now(),
          lastSyncError: null,
        ));
        
        return SyncResult(
          isSuccess: true,
          message: 'Download completed successfully',
          downloadedFiles: downloadResult.downloadedFiles,
          downloadedSize: downloadResult.downloadedSize,
        );
      } else {
        await _updateSyncConfig(config.copyWith(
          lastSyncError: downloadResult.error,
        ));
        
        return downloadResult;
      }
    } catch (e) {
      await _updateSyncConfig(config.copyWith(
        lastSyncError: e.toString(),
      ));
      
      return SyncResult(
        isSuccess: false,
        message: 'Download failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Bidirectional sync
  Future<SyncResult> _bidirectionalSync(SyncConfig config) async {
    try {
      // Get local and remote timestamps
      final localTimestamp = await _getLocalDataTimestamp();
      final remoteTimestamp = await _getRemoteDataTimestamp(config);
      
      if (localTimestamp == null && remoteTimestamp == null) {
        return SyncResult(
          isSuccess: true,
          message: 'No data to sync',
        );
      }
      
      if (remoteTimestamp == null || 
          (localTimestamp != null && localTimestamp.isAfter(remoteTimestamp))) {
        // Local is newer, upload
        return await _uploadData(config);
      } else if (localTimestamp == null || remoteTimestamp.isAfter(localTimestamp)) {
        // Remote is newer, download
        return await _downloadData(config);
      } else {
        // Same timestamp, no sync needed
        return SyncResult(
          isSuccess: true,
          message: 'Data is already synchronized',
        );
      }
    } catch (e) {
      return SyncResult(
        isSuccess: false,
        message: 'Bidirectional sync failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Export local data
  Future<Map<String, dynamic>> _exportLocalData(SyncConfig config) async {
    final data = <String, dynamic>{};
    
    try {
      // Export servers
      final serversBox = await _storageService.openBox<Server>('servers');
      data['servers'] = serversBox.values.map((s) => s.toJson()).toList();
      
      // Export app settings
      final settingsBox = await _storageService.openBox<AppSettings>('app_settings');
      final settings = settingsBox.get('settings');
      if (settings != null) {
        data['app_settings'] = settings.toJson();
      }
      
      // Export AI config
      final aiBox = await _storageService.openBox<AIConfig>('ai_config');
      final aiConfig = aiBox.get('config');
      if (aiConfig != null) {
        data['ai_config'] = aiConfig.toJson();
      }
      
      // Export widget layouts
      final widgetsBox = await _storageService.openBox<WidgetLayout>('widget_layouts');
      data['widget_layouts'] = widgetsBox.values.map((w) => w.toJson()).toList();
      
      // Export window states (if not excluded)
      if (!config.excludePatterns.contains('window_states')) {
        final windowsBox = await _storageService.openBox<WindowState>('window_states');
        data['window_states'] = windowsBox.values.map((w) => w.toJson()).toList();
      }
      
      // Add metadata
      data['metadata'] = {
        'export_time': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'app': 'Skylink SSH',
      };
      
      return data;
    } catch (e) {
      print('Failed to export local data: $e');
      rethrow;
    }
  }

  /// Import local data
  Future<void> _importLocalData(SyncConfig config, Map<String, dynamic> data) async {
    try {
      // Import servers
      if (data.containsKey('servers')) {
        final serversBox = await _storageService.openBox<Server>('servers');
        await serversBox.clear();
        
        final serversList = data['servers'] as List;
        for (final serverData in serversList) {
          final server = Server.fromJson(serverData);
          await serversBox.put(server.id, server);
        }
      }
      
      // Import app settings
      if (data.containsKey('app_settings')) {
        final settingsBox = await _storageService.openBox<AppSettings>('app_settings');
        final settings = AppSettings.fromJson(data['app_settings']);
        await settingsBox.put('settings', settings);
      }
      
      // Import AI config
      if (data.containsKey('ai_config')) {
        final aiBox = await _storageService.openBox<AIConfig>('ai_config');
        final aiConfig = AIConfig.fromJson(data['ai_config']);
        await aiBox.put('config', aiConfig);
      }
      
      // Import widget layouts
      if (data.containsKey('widget_layouts')) {
        final widgetsBox = await _storageService.openBox<WidgetLayout>('widget_layouts');
        await widgetsBox.clear();
        
        final widgetsList = data['widget_layouts'] as List;
        for (final widgetData in widgetsList) {
          final widget = WidgetLayout.fromJson(widgetData);
          await widgetsBox.put(widget.id, widget);
        }
      }
      
      // Import window states (if not excluded)
      if (data.containsKey('window_states') && !config.excludePatterns.contains('window_states')) {
        final windowsBox = await _storageService.openBox<WindowState>('window_states');
        await windowsBox.clear();
        
        final windowsList = data['window_states'] as List;
        for (final windowData in windowsList) {
          final window = WindowState.fromJson(windowData);
          await windowsBox.put(window.id, window);
        }
      }
    } catch (e) {
      print('Failed to import local data: $e');
      rethrow;
    }
  }

  /// Upload data to WebDAV
  Future<SyncResult> _uploadToWebDAV(SyncConfig config, Map<String, dynamic> data) async {
    try {
      final client = http.Client();
      final jsonData = json.encode(data);
      final fileName = 'skylink_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final uri = Uri.parse('${config.serverUrl}${config.remotePath}/$fileName');
      
      // Create authorization header
      final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
      final headers = {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/json',
        'Content-Length': utf8.encode(jsonData).length.toString(),
      };
      
      // Upload file
      final response = await client.put(
        uri,
        headers: headers,
        body: jsonData,
      );
      
      client.close();
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return SyncResult(
          isSuccess: true,
          message: 'Upload completed successfully',
          uploadedFiles: 1,
          uploadedSize: utf8.encode(jsonData).length,
        );
      } else {
        return SyncResult(
          isSuccess: false,
          message: 'Upload failed: HTTP ${response.statusCode}',
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return SyncResult(
        isSuccess: false,
        message: 'Upload failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Download data from WebDAV
  Future<SyncResult> _downloadFromWebDAV(SyncConfig config) async {
    try {
      // First, list files to find the latest backup
      final latestFile = await _getLatestBackupFile(config);
      if (latestFile == null) {
        return SyncResult(
          isSuccess: false,
          message: 'No backup files found',
          error: 'No backup files found',
        );
      }
      
      final client = http.Client();
      final uri = Uri.parse('${config.serverUrl}${config.remotePath}/$latestFile');
      
      // Create authorization header
      final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
      final headers = {
        'Authorization': 'Basic $credentials',
      };
      
      // Download file
      final response = await client.get(uri, headers: headers);
      client.close();
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        return SyncResult(
          isSuccess: true,
          message: 'Download completed successfully',
          downloadedFiles: 1,
          downloadedSize: response.bodyBytes.length,
          data: data,
        );
      } else {
        return SyncResult(
          isSuccess: false,
          message: 'Download failed: HTTP ${response.statusCode}',
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return SyncResult(
        isSuccess: false,
        message: 'Download failed: $e',
        error: e.toString(),
      );
    }
  }

  /// Get latest backup file from WebDAV
  Future<String?> _getLatestBackupFile(SyncConfig config) async {
    try {
      final client = http.Client();
      final uri = Uri.parse('${config.serverUrl}${config.remotePath}');
      
      // Create authorization header
      final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
      final headers = {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/xml',
        'Depth': '1',
      };
      
      // Send PROPFIND request to list files
      final response = await client.send(http.Request('PROPFIND', uri)
        ..headers.addAll(headers)
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
    <D:getlastmodified/>
  </D:prop>
</D:propfind>''');
      
      final responseBody = await response.stream.bytesToString();
      client.close();
      
      if (response.statusCode == 207) {
        // Parse WebDAV response to find backup files
        final backupFiles = _parseWebDAVResponse(responseBody);
        
        if (backupFiles.isNotEmpty) {
          // Sort by timestamp and return the latest
          backupFiles.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
          return backupFiles.first['name'];
        }
      }
      
      return null;
    } catch (e) {
      print('Failed to get latest backup file: $e');
      return null;
    }
  }

  /// Parse WebDAV PROPFIND response
  List<Map<String, dynamic>> _parseWebDAVResponse(String responseBody) {
    final files = <Map<String, dynamic>>[];
    
    try {
      // Simple regex-based parsing for backup files
      final filePattern = RegExp(r'skylink_backup_(\d+)\.json');
      final matches = filePattern.allMatches(responseBody);
      
      for (final match in matches) {
        final fileName = match.group(0)!;
        final timestamp = int.parse(match.group(1)!);
        
        files.add({
          'name': fileName,
          'timestamp': timestamp,
        });
      }
    } catch (e) {
      print('Failed to parse WebDAV response: $e');
    }
    
    return files;
  }

  /// Get local data timestamp
  Future<DateTime?> _getLocalDataTimestamp() async {
    try {
      final settingsBox = await _storageService.openBox<AppSettings>('app_settings');
      final settings = settingsBox.get('settings');
      return settings?.updatedAt;
    } catch (e) {
      print('Failed to get local data timestamp: $e');
      return null;
    }
  }

  /// Get remote data timestamp
  Future<DateTime?> _getRemoteDataTimestamp(SyncConfig config) async {
    try {
      final latestFile = await _getLatestBackupFile(config);
      if (latestFile != null) {
        final timestampMatch = RegExp(r'skylink_backup_(\d+)\.json').firstMatch(latestFile);
        if (timestampMatch != null) {
          final timestamp = int.parse(timestampMatch.group(1)!);
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
      return null;
    } catch (e) {
      print('Failed to get remote data timestamp: $e');
      return null;
    }
  }

  /// Update sync config
  Future<void> _updateSyncConfig(SyncConfig config) async {
    try {
      final box = await _storageService.openBox<SyncConfig>('sync_config');
      await box.put('config', config);
    } catch (e) {
      print('Failed to update sync config: $e');
    }
  }

  /// Get sync statistics
  Future<SyncStats> getSyncStats() async {
    try {
      final box = await _storageService.openBox<SyncConfig>('sync_config');
      final config = box.get('config');
      
      return SyncStats(
        isEnabled: config?.enabled ?? false,
        lastSyncTime: config?.lastSyncTime,
        lastSyncError: config?.lastSyncError,
        autoSyncEnabled: config?.autoSync ?? false,
        syncInterval: config?.syncInterval ?? 60,
        isSyncing: _isSyncing,
      );
    } catch (e) {
      print('Failed to get sync stats: $e');
      return const SyncStats(
        isEnabled: false,
        autoSyncEnabled: false,
        syncInterval: 60,
        isSyncing: false,
      );
    }
  }

  /// Clean up old backup files
  Future<void> cleanupOldBackups(SyncConfig config, {int maxBackups = 10}) async {
    try {
      final client = http.Client();
      final uri = Uri.parse('${config.serverUrl}${config.remotePath}');
      
      // Get list of backup files
      final credentials = base64Encode(utf8.encode('${config.username}:${config.password}'));
      final headers = {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/xml',
        'Depth': '1',
      };
      
      final response = await client.send(http.Request('PROPFIND', uri)
        ..headers.addAll(headers)
        ..body = '''<?xml version="1.0" encoding="utf-8" ?>
<D:propfind xmlns:D="DAV:">
  <D:prop>
    <D:displayname/>
  </D:prop>
</D:propfind>''');
      
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 207) {
        final backupFiles = _parseWebDAVResponse(responseBody);
        
        if (backupFiles.length > maxBackups) {
          // Sort by timestamp (oldest first)
          backupFiles.sort((a, b) => a['timestamp'].compareTo(b['timestamp']));
          
          // Delete old files
          final filesToDelete = backupFiles.length - maxBackups;
          for (int i = 0; i < filesToDelete; i++) {
            final fileName = backupFiles[i]['name'];
            final deleteUri = Uri.parse('${config.serverUrl}${config.remotePath}/$fileName');
            
            await client.delete(deleteUri, headers: {
              'Authorization': 'Basic $credentials',
            });
          }
        }
      }
      
      client.close();
    } catch (e) {
      print('Failed to cleanup old backups: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    stopAutoSync();
  }
}

class SyncTestResult {
  final bool isSuccess;
  final String message;
  final String? error;
  final int? responseTime;

  const SyncTestResult({
    required this.isSuccess,
    required this.message,
    this.error,
    this.responseTime,
  });
}

class SyncResult {
  final bool isSuccess;
  final String message;
  final String? error;
  final int? uploadedFiles;
  final int? downloadedFiles;
  final int? uploadedSize;
  final int? downloadedSize;
  final Map<String, dynamic>? data;

  const SyncResult({
    required this.isSuccess,
    required this.message,
    this.error,
    this.uploadedFiles,
    this.downloadedFiles,
    this.uploadedSize,
    this.downloadedSize,
    this.data,
  });
}

class SyncStats {
  final bool isEnabled;
  final DateTime? lastSyncTime;
  final String? lastSyncError;
  final bool autoSyncEnabled;
  final int syncInterval;
  final bool isSyncing;

  const SyncStats({
    required this.isEnabled,
    this.lastSyncTime,
    this.lastSyncError,
    required this.autoSyncEnabled,
    required this.syncInterval,
    required this.isSyncing,
  });
}