import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/sync_config.dart';
import '../services/storage_service.dart';
import '../services/sync_service.dart';

// Sync Config Provider
final syncConfigProvider = StateNotifierProvider<SyncConfigNotifier, SyncConfig>((ref) {
  return SyncConfigNotifier(
    ref.read(storageServiceProvider),
    ref.read(syncServiceProvider),
  );
});

// Sync Status Provider
final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier(ref.read(syncServiceProvider));
});

class SyncConfigNotifier extends StateNotifier<SyncConfig> {
  final StorageService _storageService;
  final SyncService _syncService;
  static const String _boxName = 'sync_config';
  static const String _configKey = 'config';

  SyncConfigNotifier(this._storageService, this._syncService) : super(const SyncConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final box = await _storageService.openBox<SyncConfig>(_boxName);
      final config = box.get(_configKey);
      if (config != null) {
        state = config;
        await _syncService.updateConfig(config);
      }
    } catch (e) {
      print('Failed to load sync config: $e');
      state = const SyncConfig();
    }
  }

  Future<void> _saveConfig() async {
    try {
      final box = await _storageService.openBox<SyncConfig>(_boxName);
      await box.put(_configKey, state);
      await _syncService.updateConfig(state);
    } catch (e) {
      print('Failed to save sync config: $e');
      throw Exception('Failed to save sync configuration');
    }
  }

  // Basic settings
  Future<void> updateEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _saveConfig();
  }

  Future<void> updateProvider(SyncProvider provider) async {
    state = state.copyWith(provider: provider);
    await _saveConfig();
  }

  Future<void> updateServerUrl(String serverUrl) async {
    state = state.copyWith(serverUrl: serverUrl);
    await _saveConfig();
  }

  Future<void> updateCredentials(String username, String password) async {
    state = state.copyWith(
      username: username,
      password: password,
    );
    await _saveConfig();
  }

  Future<void> updateRemotePath(String remotePath) async {
    state = state.copyWith(remotePath: remotePath);
    await _saveConfig();
  }

  // Sync behavior settings
  Future<void> updateSyncMode(SyncMode syncMode) async {
    state = state.copyWith(syncMode: syncMode);
    await _saveConfig();
  }

  Future<void> updateSyncInterval(int interval) async {
    state = state.copyWith(syncInterval: interval);
    await _saveConfig();
  }

  Future<void> updateAutoSync(bool enabled) async {
    state = state.copyWith(autoSync: enabled);
    await _saveConfig();
  }

  Future<void> updateSyncOnStartup(bool enabled) async {
    state = state.copyWith(syncOnStartup: enabled);
    await _saveConfig();
  }

  Future<void> updateSyncOnExit(bool enabled) async {
    state = state.copyWith(syncOnExit: enabled);
    await _saveConfig();
  }

  // Exclude patterns
  Future<void> updateExcludePatterns(List<String> patterns) async {
    state = state.copyWith(excludePatterns: patterns);
    await _saveConfig();
  }

  Future<void> addExcludePattern(String pattern) async {
    final currentPatterns = List<String>.from(state.excludePatterns);
    if (!currentPatterns.contains(pattern)) {
      currentPatterns.add(pattern);
      await updateExcludePatterns(currentPatterns);
    }
  }

  Future<void> removeExcludePattern(String pattern) async {
    final currentPatterns = List<String>.from(state.excludePatterns);
    currentPatterns.remove(pattern);
    await updateExcludePatterns(currentPatterns);
  }

  // Sync status updates
  Future<void> updateLastSyncAt(DateTime timestamp) async {
    state = state.copyWith(lastSyncAt: timestamp);
    await _saveConfig();
  }

  Future<void> updateLastSyncError(String? error) async {
    state = state.copyWith(lastSyncError: error);
    await _saveConfig();
  }

  // Custom settings
  Future<void> updateCustomSettings(Map<String, dynamic> settings) async {
    final currentCustom = state.customSettings ?? {};
    final updatedCustom = {...currentCustom, ...settings};
    state = state.copyWith(customSettings: updatedCustom);
    await _saveConfig();
  }

  Future<void> removeCustomSetting(String key) async {
    final currentCustom = state.customSettings ?? {};
    final updatedCustom = Map<String, dynamic>.from(currentCustom);
    updatedCustom.remove(key);
    state = state.copyWith(customSettings: updatedCustom);
    await _saveConfig();
  }

  // Test connection
  Future<bool> testConnection() async {
    try {
      return await _syncService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Manual sync operations
  Future<void> performSync() async {
    try {
      await _syncService.performSync();
      await updateLastSyncAt(DateTime.now());
      await updateLastSyncError(null);
    } catch (e) {
      await updateLastSyncError(e.toString());
      rethrow;
    }
  }

  Future<void> performUpload() async {
    try {
      await _syncService.performUpload();
      await updateLastSyncAt(DateTime.now());
      await updateLastSyncError(null);
    } catch (e) {
      await updateLastSyncError(e.toString());
      rethrow;
    }
  }

  Future<void> performDownload() async {
    try {
      await _syncService.performDownload();
      await updateLastSyncAt(DateTime.now());
      await updateLastSyncError(null);
    } catch (e) {
      await updateLastSyncError(e.toString());
      rethrow;
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    state = const SyncConfig();
    await _saveConfig();
  }
}

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  final SyncService _syncService;

  SyncStatusNotifier(this._syncService) : super(SyncStatus.idle) {
    _initializeStatus();
  }

  void _initializeStatus() {
    // Listen to sync service status changes
    _syncService.statusStream.listen((status) {
      state = status;
    });
  }

  void updateStatus(SyncStatus status) {
    state = status;
  }
}

enum SyncStatus {
  idle,
  connecting,
  uploading,
  downloading,
  syncing,
  completed,
  error,
  cancelled,
}

// Convenience providers
final syncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(syncConfigProvider).enabled;
});

final syncConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(syncConfigProvider).isConfigured;
});

final syncProviderProvider = Provider<SyncProvider>((ref) {
  return ref.watch(syncConfigProvider).provider;
});

final syncModeProvider = Provider<SyncMode>((ref) {
  return ref.watch(syncConfigProvider).syncMode;
});

final autoSyncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(syncConfigProvider).autoSync;
});

final lastSyncTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(syncConfigProvider).lastSyncAt;
});

final lastSyncErrorProvider = Provider<String?>((ref) {
  return ref.watch(syncConfigProvider).lastSyncError;
});