import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ai_config.g.dart';

@HiveType(typeId: 5)
@JsonSerializable()
class AIConfig {
  @HiveField(0)
  final AIProvider provider;

  @HiveField(1)
  final String? apiKey;

  @HiveField(2)
  final String? apiUrl;

  @HiveField(3)
  final String model;

  @HiveField(4)
  final double temperature;

  @HiveField(5)
  final int maxTokens;

  @HiveField(6)
  final bool enableContextMemory;

  @HiveField(7)
  final int contextWindowSize;

  @HiveField(8)
  final bool enableCodeAnalysis;

  @HiveField(9)
  final bool enableSystemCommands;

  @HiveField(10)
  final List<String> allowedCommands;

  @HiveField(11)
  final Map<String, dynamic>? customSettings;

  const AIConfig({
    this.provider = AIProvider.openai,
    this.apiKey,
    this.apiUrl,
    this.model = 'gpt-3.5-turbo',
    this.temperature = 0.7,
    this.maxTokens = 2048,
    this.enableContextMemory = true,
    this.contextWindowSize = 10,
    this.enableCodeAnalysis = true,
    this.enableSystemCommands = false,
    this.allowedCommands = const [],
    this.customSettings,
  });

  factory AIConfig.fromJson(Map<String, dynamic> json) => _$AIConfigFromJson(json);
  Map<String, dynamic> toJson() => _$AIConfigToJson(this);

  AIConfig copyWith({
    AIProvider? provider,
    String? apiKey,
    String? apiUrl,
    String? model,
    double? temperature,
    int? maxTokens,
    bool? enableContextMemory,
    int? contextWindowSize,
    bool? enableCodeAnalysis,
    bool? enableSystemCommands,
    List<String>? allowedCommands,
    Map<String, dynamic>? customSettings,
  }) {
    return AIConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      apiUrl: apiUrl ?? this.apiUrl,
      model: model ?? this.model,
      temperature: temperature ?? this.temperature,
      maxTokens: maxTokens ?? this.maxTokens,
      enableContextMemory: enableContextMemory ?? this.enableContextMemory,
      contextWindowSize: contextWindowSize ?? this.contextWindowSize,
      enableCodeAnalysis: enableCodeAnalysis ?? this.enableCodeAnalysis,
      enableSystemCommands: enableSystemCommands ?? this.enableSystemCommands,
      allowedCommands: allowedCommands ?? this.allowedCommands,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  bool get isConfigured => apiKey != null && apiKey!.isNotEmpty;

  String get displayName {
    switch (provider) {
      case AIProvider.openai:
        return 'OpenAI';
      case AIProvider.claude:
        return 'Claude';
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.local:
        return 'Local Model';
      case AIProvider.custom:
        return 'Custom';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIConfig &&
        other.provider == provider &&
        other.model == model &&
        other.apiKey == apiKey;
  }

  @override
  int get hashCode {
    return Object.hash(provider, model, apiKey);
  }
}

@HiveType(typeId: 6)
enum AIProvider {
  @HiveField(0)
  openai,
  @HiveField(1)
  claude,
  @HiveField(2)
  gemini,
  @HiveField(3)
  local,
  @HiveField(4)
  custom,
}