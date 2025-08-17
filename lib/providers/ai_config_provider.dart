import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/ai_config.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

// AI Config Provider
final aiConfigProvider = StateNotifierProvider<AIConfigNotifier, AIConfig>((ref) {
  return AIConfigNotifier(
    ref.read(storageServiceProvider),
    ref.read(aiServiceProvider),
  );
});

// AI Service Status Provider
final aiServiceStatusProvider = StateNotifierProvider<AIServiceStatusNotifier, AIServiceStatus>((ref) {
  return AIServiceStatusNotifier(ref.read(aiServiceProvider));
});

class AIConfigNotifier extends StateNotifier<AIConfig> {
  final StorageService _storageService;
  final AIService _aiService;
  static const String _boxName = 'ai_config';
  static const String _configKey = 'config';

  AIConfigNotifier(this._storageService, this._aiService) : super(const AIConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final box = await _storageService.openBox<AIConfig>(_boxName);
      final config = box.get(_configKey);
      if (config != null) {
        state = config;
        await _aiService.updateConfig(config);
      }
    } catch (e) {
      print('Failed to load AI config: $e');
      state = const AIConfig();
    }
  }

  Future<void> _saveConfig() async {
    try {
      final box = await _storageService.openBox<AIConfig>(_boxName);
      await box.put(_configKey, state);
      await _aiService.updateConfig(state);
    } catch (e) {
      print('Failed to save AI config: $e');
      throw Exception('Failed to save AI configuration');
    }
  }

  // Provider settings
  Future<void> updateProvider(AIProvider provider) async {
    state = state.copyWith(provider: provider);
    await _saveConfig();
  }

  Future<void> updateApiKey(String apiKey) async {
    state = state.copyWith(apiKey: apiKey);
    await _saveConfig();
  }

  Future<void> updateApiUrl(String? apiUrl) async {
    state = state.copyWith(apiUrl: apiUrl);
    await _saveConfig();
  }

  Future<void> updateModel(String model) async {
    state = state.copyWith(model: model);
    await _saveConfig();
  }

  // Generation settings
  Future<void> updateTemperature(double temperature) async {
    state = state.copyWith(temperature: temperature);
    await _saveConfig();
  }

  Future<void> updateMaxTokens(int maxTokens) async {
    state = state.copyWith(maxTokens: maxTokens);
    await _saveConfig();
  }

  // Feature settings
  Future<void> updateContextMemory(bool enabled) async {
    state = state.copyWith(enableContextMemory: enabled);
    await _saveConfig();
  }

  Future<void> updateContextWindowSize(int size) async {
    state = state.copyWith(contextWindowSize: size);
    await _saveConfig();
  }

  Future<void> updateCodeAnalysis(bool enabled) async {
    state = state.copyWith(enableCodeAnalysis: enabled);
    await _saveConfig();
  }

  Future<void> updateSystemCommands(bool enabled) async {
    state = state.copyWith(enableSystemCommands: enabled);
    await _saveConfig();
  }

  Future<void> updateAllowedCommands(List<String> commands) async {
    state = state.copyWith(allowedCommands: commands);
    await _saveConfig();
  }

  Future<void> addAllowedCommand(String command) async {
    final currentCommands = List<String>.from(state.allowedCommands);
    if (!currentCommands.contains(command)) {
      currentCommands.add(command);
      await updateAllowedCommands(currentCommands);
    }
  }

  Future<void> removeAllowedCommand(String command) async {
    final currentCommands = List<String>.from(state.allowedCommands);
    currentCommands.remove(command);
    await updateAllowedCommands(currentCommands);
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

  // Test configuration
  Future<bool> testConfiguration() async {
    try {
      return await _aiService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Reset to defaults
  Future<void> resetToDefaults() async {
    state = const AIConfig();
    await _saveConfig();
  }

  // Get available models for current provider
  Future<List<String>> getAvailableModels() async {
    try {
      return await _aiService.getAvailableModels(state.provider);
    } catch (e) {
      return [];
    }
  }
}

class AIServiceStatusNotifier extends StateNotifier<AIServiceStatus> {
  final AIService _aiService;

  AIServiceStatusNotifier(this._aiService) : super(AIServiceStatus.idle) {
    _initializeStatus();
  }

  void _initializeStatus() {
    // Listen to AI service status changes
    _aiService.statusStream.listen((status) {
      state = status;
    });
  }

  void updateStatus(AIServiceStatus status) {
    state = status;
  }
}

enum AIServiceStatus {
  idle,
  connecting,
  connected,
  processing,
  error,
  disconnected,
}

// Convenience providers
final aiConfiguredProvider = Provider<bool>((ref) {
  return ref.watch(aiConfigProvider).isConfigured;
});

final aiProviderProvider = Provider<AIProvider>((ref) {
  return ref.watch(aiConfigProvider).provider;
});

final aiModelProvider = Provider<String>((ref) {
  return ref.watch(aiConfigProvider).model;
});

final aiContextMemoryEnabledProvider = Provider<bool>((ref) {
  return ref.watch(aiConfigProvider).enableContextMemory;
});

final aiCodeAnalysisEnabledProvider = Provider<bool>((ref) {
  return ref.watch(aiConfigProvider).enableCodeAnalysis;
});

final aiSystemCommandsEnabledProvider = Provider<bool>((ref) {
  return ref.watch(aiConfigProvider).enableSystemCommands;
});