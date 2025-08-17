import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/index.dart';

// Storage Service Provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

class StorageService {
  static const String _encryptionKeyName = 'hive_encryption_key';
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  bool _isInitialized = false;
  List<int>? _encryptionKey;

  /// Initialize Hive with encryption and register adapters
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Get or generate encryption key
      _encryptionKey = await _getOrCreateEncryptionKey();

      // Register all type adapters
      await _registerAdapters();

      _isInitialized = true;
      print('Storage service initialized successfully');
    } catch (e) {
      print('Failed to initialize storage service: $e');
      rethrow;
    }
  }

  /// Get or create encryption key for Hive boxes
  Future<List<int>> _getOrCreateEncryptionKey() async {
    try {
      // Try to get existing key
      final existingKey = await _secureStorage.read(key: _encryptionKeyName);
      
      if (existingKey != null) {
        return existingKey.split(',').map(int.parse).toList();
      }

      // Generate new key
      final key = Hive.generateSecureKey();
      await _secureStorage.write(
        key: _encryptionKeyName,
        value: key.join(','),
      );
      
      return key;
    } catch (e) {
      print('Failed to get/create encryption key: $e');
      // Fallback to unencrypted storage
      return [];
    }
  }

  /// Register all Hive type adapters
  Future<void> _registerAdapters() async {
    // Register model adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ServerAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AIConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SyncConfigAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) {
      Hive.registerAdapter(ServerPreviewMetricsAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(WidgetLayoutAdapter());
    }
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(WindowStateAdapter());
    }

    // Register enum adapters
    if (!Hive.isAdapterRegistered(10)) {
      Hive.registerAdapter(AuthTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(11)) {
      Hive.registerAdapter(ThemeModeAdapter());
    }
    if (!Hive.isAdapterRegistered(12)) {
      Hive.registerAdapter(LogLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(13)) {
      Hive.registerAdapter(AIProviderAdapter());
    }
    if (!Hive.isAdapterRegistered(14)) {
      Hive.registerAdapter(SyncProviderAdapter());
    }
    if (!Hive.isAdapterRegistered(15)) {
      Hive.registerAdapter(SyncModeAdapter());
    }
    if (!Hive.isAdapterRegistered(16)) {
      Hive.registerAdapter(ServerStatusAdapter());
    }
    if (!Hive.isAdapterRegistered(17)) {
      Hive.registerAdapter(WidgetTypeAdapter());
    }
    if (!Hive.isAdapterRegistered(18)) {
      Hive.registerAdapter(WindowTypeAdapter());
    }

    // Register nested model adapters
    if (!Hive.isAdapterRegistered(20)) {
      Hive.registerAdapter(NetworkMetricsAdapter());
    }
    if (!Hive.isAdapterRegistered(21)) {
      Hive.registerAdapter(WidgetPositionAdapter());
    }
    if (!Hive.isAdapterRegistered(22)) {
      Hive.registerAdapter(WidgetSizeAdapter());
    }
    if (!Hive.isAdapterRegistered(23)) {
      Hive.registerAdapter(WindowPositionAdapter());
    }
    if (!Hive.isAdapterRegistered(24)) {
      Hive.registerAdapter(WindowSizeAdapter());
    }
  }

  /// Open a Hive box with encryption
  Future<Box<T>> openBox<T>(String boxName) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (Hive.isBoxOpen(boxName)) {
        return Hive.box<T>(boxName);
      }

      final box = await Hive.openBox<T>(
        boxName,
        encryptionCipher: _encryptionKey?.isNotEmpty == true
            ? HiveAesCipher(_encryptionKey!)
            : null,
      );

      return box;
    } catch (e) {
      print('Failed to open box $boxName: $e');
      rethrow;
    }
  }

  /// Close a specific box
  Future<void> closeBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
    } catch (e) {
      print('Failed to close box $boxName: $e');
    }
  }

  /// Close all boxes
  Future<void> closeAllBoxes() async {
    try {
      await Hive.close();
    } catch (e) {
      print('Failed to close all boxes: $e');
    }
  }

  /// Delete a box and all its data
  Future<void> deleteBox(String boxName) async {
    try {
      if (Hive.isBoxOpen(boxName)) {
        await Hive.box(boxName).close();
      }
      await Hive.deleteBoxFromDisk(boxName);
    } catch (e) {
      print('Failed to delete box $boxName: $e');
    }
  }

  /// Clear all data from a box
  Future<void> clearBox(String boxName) async {
    try {
      final box = await openBox(boxName);
      await box.clear();
    } catch (e) {
      print('Failed to clear box $boxName: $e');
    }
  }

  /// Get storage statistics
  Future<StorageStats> getStorageStats() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final hiveDir = Directory('${appDir.path}/hive');
      
      if (!await hiveDir.exists()) {
        return const StorageStats();
      }

      int totalSize = 0;
      int fileCount = 0;
      final boxSizes = <String, int>{};

      await for (final entity in hiveDir.list(recursive: true)) {
        if (entity is File) {
          final size = await entity.length();
          totalSize += size;
          fileCount++;
          
          final fileName = entity.path.split('/').last;
          if (fileName.endsWith('.hive')) {
            final boxName = fileName.replaceAll('.hive', '');
            boxSizes[boxName] = size;
          }
        }
      }

      return StorageStats(
        totalSize: totalSize,
        fileCount: fileCount,
        boxSizes: boxSizes,
      );
    } catch (e) {
      print('Failed to get storage stats: $e');
      return const StorageStats();
    }
  }

  /// Compact all boxes to reduce storage size
  Future<void> compactStorage() async {
    try {
      final openBoxes = Hive.openedBoxes.keys.toList();
      
      for (final boxName in openBoxes) {
        try {
          final box = Hive.box(boxName);
          await box.compact();
        } catch (e) {
          print('Failed to compact box $boxName: $e');
        }
      }
    } catch (e) {
      print('Failed to compact storage: $e');
    }
  }

  /// Backup data to a file
  Future<String> backupData() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDir.path}/backups');
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${backupDir.path}/skylink_backup_$timestamp.json';
      
      // TODO: Implement backup logic
      // This would involve exporting all box data to JSON format
      
      return backupPath;
    } catch (e) {
      print('Failed to backup data: $e');
      rethrow;
    }
  }

  /// Restore data from a backup file
  Future<void> restoreData(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        throw Exception('Backup file not found');
      }

      // TODO: Implement restore logic
      // This would involve importing JSON data back to Hive boxes
      
    } catch (e) {
      print('Failed to restore data: $e');
      rethrow;
    }
  }

  /// Store sensitive data in secure storage
  Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      print('Failed to store secure data for key $key: $e');
      rethrow;
    }
  }

  /// Retrieve sensitive data from secure storage
  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      print('Failed to get secure data for key $key: $e');
      return null;
    }
  }

  /// Delete sensitive data from secure storage
  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      print('Failed to delete secure data for key $key: $e');
    }
  }

  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      print('Failed to clear secure storage: $e');
    }
  }

  /// Check if storage is healthy
  Future<bool> isStorageHealthy() async {
    try {
      // Test basic operations
      final testBox = await openBox<String>('health_check');
      await testBox.put('test', 'value');
      final value = testBox.get('test');
      await testBox.delete('test');
      await testBox.close();
      
      return value == 'value';
    } catch (e) {
      print('Storage health check failed: $e');
      return false;
    }
  }
}

class StorageStats {
  final int totalSize;
  final int fileCount;
  final Map<String, int> boxSizes;

  const StorageStats({
    this.totalSize = 0,
    this.fileCount = 0,
    this.boxSizes = const {},
  });

  String get formattedTotalSize {
    if (totalSize < 1024) return '${totalSize}B';
    if (totalSize < 1024 * 1024) return '${(totalSize / 1024).toStringAsFixed(1)}KB';
    if (totalSize < 1024 * 1024 * 1024) return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(totalSize / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}