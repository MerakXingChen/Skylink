import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

// App Settings Provider
final appSettingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref.read(storageServiceProvider));
});

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final StorageService _storageService;
  static const String _boxName = 'app_settings';
  static const String _settingsKey = 'settings';

  AppSettingsNotifier(this._storageService) : super(const AppSettings()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final box = await _storageService.openBox<AppSettings>(_boxName);
      final settings = box.get(_settingsKey);
      if (settings != null) {
        state = settings;
      }
    } catch (e) {
      // Use default settings if loading fails
      state = const AppSettings();
    }
  }

  Future<void> _saveSettings() async {
    try {
      final box = await _storageService.openBox<AppSettings>(_boxName);
      await box.put(_settingsKey, state);
    } catch (e) {
      // Handle save error
      print('Failed to save app settings: $e');
    }
  }

  // Language settings
  Future<void> updateLanguage(String languageCode) async {
    state = state.copyWith(languageCode: languageCode);
    await _saveSettings();
  }

  // Theme settings
  Future<void> updateThemeMode(ThemeMode themeMode) async {
    state = state.copyWith(themeMode: themeMode);
    await _saveSettings();
  }

  // AI settings
  Future<void> updateAIEnabled(bool enabled) async {
    state = state.copyWith(aiEnabled: enabled);
    await _saveSettings();
  }

  // Sync settings
  Future<void> updateSyncEnabled(bool enabled) async {
    state = state.copyWith(syncEnabled: enabled);
    await _saveSettings();
  }

  // Notification settings
  Future<void> updateNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _saveSettings();
  }

  // Terminal settings
  Future<void> updateTerminalFontSize(double fontSize) async {
    state = state.copyWith(terminalFontSize: fontSize);
    await _saveSettings();
  }

  Future<void> updateTerminalFontFamily(String fontFamily) async {
    state = state.copyWith(terminalFontFamily: fontFamily);
    await _saveSettings();
  }

  Future<void> updateTerminalBell(bool enabled) async {
    state = state.copyWith(terminalBell: enabled);
    await _saveSettings();
  }

  Future<void> updateTerminalHistoryLimit(int limit) async {
    state = state.copyWith(terminalHistoryLimit: limit);
    await _saveSettings();
  }

  // Connection settings
  Future<void> updateAutoReconnect(bool enabled) async {
    state = state.copyWith(autoReconnect: enabled);
    await _saveSettings();
  }

  Future<void> updateConnectionTimeout(int timeout) async {
    state = state.copyWith(connectionTimeout: timeout);
    await _saveSettings();
  }

  // Logging settings
  Future<void> updateLoggingEnabled(bool enabled) async {
    state = state.copyWith(loggingEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateLogLevel(LogLevel level) async {
    state = state.copyWith(logLevel: level);
    await _saveSettings();
  }

  // Metrics settings
  Future<void> updateMetricsEnabled(bool enabled) async {
    state = state.copyWith(metricsEnabled: enabled);
    await _saveSettings();
  }

  Future<void> updateMetricsInterval(int interval) async {
    state = state.copyWith(metricsInterval: interval);
    await _saveSettings();
  }

  // Custom settings
  Future<void> updateCustomSettings(Map<String, dynamic> settings) async {
    final currentCustom = state.customSettings ?? {};
    final updatedCustom = {...currentCustom, ...settings};
    state = state.copyWith(customSettings: updatedCustom);
    await _saveSettings();
  }

  Future<void> removeCustomSetting(String key) async {
    final currentCustom = state.customSettings ?? {};
    final updatedCustom = Map<String, dynamic>.from(currentCustom);
    updatedCustom.remove(key);
    state = state.copyWith(customSettings: updatedCustom);
    await _saveSettings();
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    state = const AppSettings();
    await _saveSettings();
  }
}

// Convenience providers for specific settings
final languageProvider = Provider<String>((ref) {
  return ref.watch(appSettingsProvider).languageCode;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(appSettingsProvider).themeMode;
});

final aiEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).aiEnabled;
});

final syncEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).syncEnabled;
});

final notificationsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(appSettingsProvider).notificationsEnabled;
});