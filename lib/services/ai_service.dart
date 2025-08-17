import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../models/index.dart';
import 'storage_service.dart';

// AI Service Provider
final aiServiceProvider = Provider<AIService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return AIService(storageService);
});

class AIService {
  final StorageService _storageService;
  final Map<String, List<AIMessage>> _conversationHistory = {};
  final Map<String, StreamController<AIResponse>> _responseControllers = {};

  AIService(this._storageService);

  /// Test AI configuration
  Future<AITestResult> testConfiguration(AIConfig config) async {
    try {
      final client = _createClient(config);
      final result = await client.testConnection();
      return result;
    } catch (e) {
      return AITestResult.failure(e.toString());
    }
  }

  /// Send a message to AI assistant
  Future<AIResponse> sendMessage(
    AIConfig config,
    String message, {
    String? conversationId,
    Map<String, dynamic>? context,
    bool useHistory = true,
  }) async {
    try {
      final client = _createClient(config);
      
      // Get conversation history if enabled
      List<AIMessage> history = [];
      if (useHistory && conversationId != null && config.contextMemory) {
        history = _getConversationHistory(conversationId, config.contextWindowSize);
      }

      // Add current message to history
      final userMessage = AIMessage(
        role: AIMessageRole.user,
        content: message,
        timestamp: DateTime.now(),
        metadata: context,
      );
      
      if (conversationId != null) {
        _addToHistory(conversationId, userMessage);
      }

      // Send to AI provider
      final response = await client.sendMessage(
        message,
        history: history,
        context: context,
      );

      // Add response to history
      if (conversationId != null && response.isSuccess) {
        final assistantMessage = AIMessage(
          role: AIMessageRole.assistant,
          content: response.content ?? '',
          timestamp: DateTime.now(),
          metadata: {
            'model': config.model,
            'provider': config.provider.name,
            'tokens_used': response.tokensUsed,
          },
        );
        _addToHistory(conversationId, assistantMessage);
      }

      return response;
    } catch (e) {
      return AIResponse.failure(e.toString());
    }
  }

  /// Send a streaming message to AI assistant
  Stream<AIResponse> sendStreamingMessage(
    AIConfig config,
    String message, {
    String? conversationId,
    Map<String, dynamic>? context,
    bool useHistory = true,
  }) async* {
    try {
      final client = _createClient(config);
      
      // Get conversation history if enabled
      List<AIMessage> history = [];
      if (useHistory && conversationId != null && config.contextMemory) {
        history = _getConversationHistory(conversationId, config.contextWindowSize);
      }

      // Add current message to history
      final userMessage = AIMessage(
        role: AIMessageRole.user,
        content: message,
        timestamp: DateTime.now(),
        metadata: context,
      );
      
      if (conversationId != null) {
        _addToHistory(conversationId, userMessage);
      }

      // Stream response from AI provider
      String fullResponse = '';
      await for (final chunk in client.sendStreamingMessage(
        message,
        history: history,
        context: context,
      )) {
        if (chunk.isSuccess && chunk.content != null) {
          fullResponse += chunk.content!;
        }
        yield chunk;
      }

      // Add complete response to history
      if (conversationId != null && fullResponse.isNotEmpty) {
        final assistantMessage = AIMessage(
          role: AIMessageRole.assistant,
          content: fullResponse,
          timestamp: DateTime.now(),
          metadata: {
            'model': config.model,
            'provider': config.provider.name,
            'streaming': true,
          },
        );
        _addToHistory(conversationId, assistantMessage);
      }
    } catch (e) {
      yield AIResponse.failure(e.toString());
    }
  }

  /// Analyze code with AI
  Future<AICodeAnalysisResult> analyzeCode(
    AIConfig config,
    String code, {
    String? language,
    String? analysisType,
    Map<String, dynamic>? context,
  }) async {
    if (!config.codeAnalysis) {
      return AICodeAnalysisResult.failure('Code analysis is disabled');
    }

    try {
      final client = _createClient(config);
      
      final prompt = _buildCodeAnalysisPrompt(
        code,
        language: language,
        analysisType: analysisType,
        context: context,
      );

      final response = await client.sendMessage(prompt);
      
      if (response.isSuccess) {
        return AICodeAnalysisResult.success(
          analysis: response.content ?? '',
          suggestions: _extractSuggestions(response.content ?? ''),
          issues: _extractIssues(response.content ?? ''),
        );
      } else {
        return AICodeAnalysisResult.failure(response.error ?? 'Analysis failed');
      }
    } catch (e) {
      return AICodeAnalysisResult.failure(e.toString());
    }
  }

  /// Generate system command with AI
  Future<AICommandResult> generateCommand(
    AIConfig config,
    String description, {
    String? platform,
    Map<String, dynamic>? context,
  }) async {
    if (!config.systemCommands) {
      return AICommandResult.failure('System commands are disabled');
    }

    try {
      final client = _createClient(config);
      
      final prompt = _buildCommandGenerationPrompt(
        description,
        platform: platform,
        context: context,
      );

      final response = await client.sendMessage(prompt);
      
      if (response.isSuccess) {
        final command = _extractCommand(response.content ?? '');
        final isSafe = _isCommandSafe(command, config.allowedCommands);
        
        return AICommandResult.success(
          command: command,
          explanation: response.content ?? '',
          isSafe: isSafe,
        );
      } else {
        return AICommandResult.failure(response.error ?? 'Command generation failed');
      }
    } catch (e) {
      return AICommandResult.failure(e.toString());
    }
  }

  /// Get conversation history
  List<AIMessage> getConversationHistory(String conversationId) {
    return _conversationHistory[conversationId] ?? [];
  }

  /// Clear conversation history
  void clearConversationHistory(String conversationId) {
    _conversationHistory.remove(conversationId);
  }

  /// Clear all conversation histories
  void clearAllConversationHistories() {
    _conversationHistory.clear();
  }

  /// Get conversation statistics
  AIConversationStats getConversationStats(String conversationId) {
    final history = _conversationHistory[conversationId] ?? [];
    
    int userMessages = 0;
    int assistantMessages = 0;
    int totalTokens = 0;
    DateTime? firstMessage;
    DateTime? lastMessage;

    for (final message in history) {
      if (message.role == AIMessageRole.user) {
        userMessages++;
      } else if (message.role == AIMessageRole.assistant) {
        assistantMessages++;
        totalTokens += (message.metadata?['tokens_used'] as int?) ?? 0;
      }
      
      firstMessage ??= message.timestamp;
      lastMessage = message.timestamp;
    }

    return AIConversationStats(
      conversationId: conversationId,
      totalMessages: history.length,
      userMessages: userMessages,
      assistantMessages: assistantMessages,
      totalTokens: totalTokens,
      firstMessage: firstMessage,
      lastMessage: lastMessage,
    );
  }

  /// Create AI client based on provider
  AIClient _createClient(AIConfig config) {
    switch (config.provider) {
      case AIProvider.openai:
        return OpenAIClient(config);
      case AIProvider.claude:
        return ClaudeClient(config);
      case AIProvider.gemini:
        return GeminiClient(config);
      case AIProvider.local:
        return LocalAIClient(config);
    }
  }

  /// Get conversation history with limit
  List<AIMessage> _getConversationHistory(String conversationId, int limit) {
    final history = _conversationHistory[conversationId] ?? [];
    if (history.length <= limit) return history;
    return history.sublist(history.length - limit);
  }

  /// Add message to conversation history
  void _addToHistory(String conversationId, AIMessage message) {
    _conversationHistory[conversationId] ??= [];
    _conversationHistory[conversationId]!.add(message);
  }

  /// Build code analysis prompt
  String _buildCodeAnalysisPrompt(
    String code, {
    String? language,
    String? analysisType,
    Map<String, dynamic>? context,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Please analyze the following code:');
    buffer.writeln();
    
    if (language != null) {
      buffer.writeln('Language: $language');
    }
    
    if (analysisType != null) {
      buffer.writeln('Analysis Type: $analysisType');
    }
    
    if (context != null && context.isNotEmpty) {
      buffer.writeln('Context: ${json.encode(context)}');
    }
    
    buffer.writeln();
    buffer.writeln('```${language ?? ''}');
    buffer.writeln(code);
    buffer.writeln('```');
    buffer.writeln();
    buffer.writeln('Please provide:');
    buffer.writeln('1. Code quality assessment');
    buffer.writeln('2. Potential issues or bugs');
    buffer.writeln('3. Improvement suggestions');
    buffer.writeln('4. Security considerations');
    
    return buffer.toString();
  }

  /// Build command generation prompt
  String _buildCommandGenerationPrompt(
    String description, {
    String? platform,
    Map<String, dynamic>? context,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('Generate a system command for the following task:');
    buffer.writeln();
    buffer.writeln('Task: $description');
    
    if (platform != null) {
      buffer.writeln('Platform: $platform');
    }
    
    if (context != null && context.isNotEmpty) {
      buffer.writeln('Context: ${json.encode(context)}');
    }
    
    buffer.writeln();
    buffer.writeln('Please provide:');
    buffer.writeln('1. The exact command to run');
    buffer.writeln('2. Explanation of what the command does');
    buffer.writeln('3. Any prerequisites or warnings');
    buffer.writeln('4. Expected output or behavior');
    
    return buffer.toString();
  }

  /// Extract command from AI response
  String _extractCommand(String response) {
    // Look for code blocks or command patterns
    final codeBlockRegex = RegExp(r'```(?:bash|sh|cmd|powershell)?\s*([^`]+)```');
    final match = codeBlockRegex.firstMatch(response);
    
    if (match != null) {
      return match.group(1)?.trim() ?? '';
    }
    
    // Look for lines starting with $ or >
    final lines = response.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith(r'$ ') || trimmed.startsWith('> ')) {
        return trimmed.substring(2);
      }
    }
    
    return response.trim();
  }

  /// Check if command is safe to execute
  bool _isCommandSafe(String command, List<String> allowedCommands) {
    if (allowedCommands.isEmpty) return false;
    
    final commandLower = command.toLowerCase();
    
    // Check against allowed commands
    for (final allowed in allowedCommands) {
      if (commandLower.startsWith(allowed.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  /// Extract suggestions from analysis response
  List<String> _extractSuggestions(String response) {
    final suggestions = <String>[];
    final lines = response.split('\n');
    
    bool inSuggestions = false;
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.toLowerCase().contains('suggestion') ||
          trimmed.toLowerCase().contains('improvement')) {
        inSuggestions = true;
        continue;
      }
      
      if (inSuggestions && trimmed.isNotEmpty) {
        if (trimmed.startsWith('-') || trimmed.startsWith('*') || 
            RegExp(r'^\d+\.').hasMatch(trimmed)) {
          suggestions.add(trimmed.replaceFirst(RegExp(r'^[-*\d.]+\s*'), ''));
        }
      }
    }
    
    return suggestions;
  }

  /// Extract issues from analysis response
  List<String> _extractIssues(String response) {
    final issues = <String>[];
    final lines = response.split('\n');
    
    bool inIssues = false;
    for (final line in lines) {
      final trimmed = line.trim();
      
      if (trimmed.toLowerCase().contains('issue') ||
          trimmed.toLowerCase().contains('problem') ||
          trimmed.toLowerCase().contains('bug')) {
        inIssues = true;
        continue;
      }
      
      if (inIssues && trimmed.isNotEmpty) {
        if (trimmed.startsWith('-') || trimmed.startsWith('*') || 
            RegExp(r'^\d+\.').hasMatch(trimmed)) {
          issues.add(trimmed.replaceFirst(RegExp(r'^[-*\d.]+\s*'), ''));
        }
      }
    }
    
    return issues;
  }

  /// Dispose resources
  void dispose() {
    for (final controller in _responseControllers.values) {
      controller.close();
    }
    _responseControllers.clear();
    _conversationHistory.clear();
  }
}

// AI Message
class AIMessage {
  final AIMessageRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const AIMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });
}

enum AIMessageRole {
  user,
  assistant,
  system,
}

// AI Response
class AIResponse {
  final bool isSuccess;
  final String? content;
  final String? error;
  final int? tokensUsed;
  final Map<String, dynamic>? metadata;

  const AIResponse._({required this.isSuccess, this.content, this.error, this.tokensUsed, this.metadata});

  factory AIResponse.success({
    required String content,
    int? tokensUsed,
    Map<String, dynamic>? metadata,
  }) {
    return AIResponse._(
      isSuccess: true,
      content: content,
      tokensUsed: tokensUsed,
      metadata: metadata,
    );
  }

  factory AIResponse.failure(String error) {
    return AIResponse._(isSuccess: false, error: error);
  }
}

// Result classes
class AITestResult {
  final bool isSuccess;
  final String? error;
  final Map<String, dynamic>? metadata;

  const AITestResult._({required this.isSuccess, this.error, this.metadata});

  factory AITestResult.success({Map<String, dynamic>? metadata}) {
    return AITestResult._(isSuccess: true, metadata: metadata);
  }

  factory AITestResult.failure(String error) {
    return AITestResult._(isSuccess: false, error: error);
  }
}

class AICodeAnalysisResult {
  final bool isSuccess;
  final String? analysis;
  final List<String>? suggestions;
  final List<String>? issues;
  final String? error;

  const AICodeAnalysisResult._({required this.isSuccess, this.analysis, this.suggestions, this.issues, this.error});

  factory AICodeAnalysisResult.success({
    required String analysis,
    List<String>? suggestions,
    List<String>? issues,
  }) {
    return AICodeAnalysisResult._(
      isSuccess: true,
      analysis: analysis,
      suggestions: suggestions ?? [],
      issues: issues ?? [],
    );
  }

  factory AICodeAnalysisResult.failure(String error) {
    return AICodeAnalysisResult._(isSuccess: false, error: error);
  }
}

class AICommandResult {
  final bool isSuccess;
  final String? command;
  final String? explanation;
  final bool? isSafe;
  final String? error;

  const AICommandResult._({required this.isSuccess, this.command, this.explanation, this.isSafe, this.error});

  factory AICommandResult.success({
    required String command,
    String? explanation,
    bool? isSafe,
  }) {
    return AICommandResult._(
      isSuccess: true,
      command: command,
      explanation: explanation,
      isSafe: isSafe ?? false,
    );
  }

  factory AICommandResult.failure(String error) {
    return AICommandResult._(isSuccess: false, error: error);
  }
}

class AIConversationStats {
  final String conversationId;
  final int totalMessages;
  final int userMessages;
  final int assistantMessages;
  final int totalTokens;
  final DateTime? firstMessage;
  final DateTime? lastMessage;

  const AIConversationStats({
    required this.conversationId,
    required this.totalMessages,
    required this.userMessages,
    required this.assistantMessages,
    required this.totalTokens,
    this.firstMessage,
    this.lastMessage,
  });

  Duration? get conversationDuration {
    if (firstMessage == null || lastMessage == null) return null;
    return lastMessage!.difference(firstMessage!);
  }
}

// Abstract AI Client
abstract class AIClient {
  final AIConfig config;
  
  AIClient(this.config);
  
  Future<AITestResult> testConnection();
  Future<AIResponse> sendMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context});
  Stream<AIResponse> sendStreamingMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context});
}

// OpenAI Client Implementation
class OpenAIClient extends AIClient {
  OpenAIClient(super.config);
  
  @override
  Future<AITestResult> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('${config.apiUrl}/models'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        return AITestResult.success();
      } else {
        return AITestResult.failure('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return AITestResult.failure(e.toString());
    }
  }
  
  @override
  Future<AIResponse> sendMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async {
    try {
      final messages = _buildMessages(message, history);
      
      final response = await http.post(
        Uri.parse('${config.apiUrl}/chat/completions'),
        headers: {
          'Authorization': 'Bearer ${config.apiKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': config.model,
          'messages': messages,
          'temperature': config.temperature,
          'max_tokens': config.maxTokens,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'];
        final tokensUsed = data['usage']['total_tokens'];
        
        return AIResponse.success(
          content: content,
          tokensUsed: tokensUsed,
        );
      } else {
        return AIResponse.failure('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      return AIResponse.failure(e.toString());
    }
  }
  
  @override
  Stream<AIResponse> sendStreamingMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async* {
    // TODO: Implement streaming for OpenAI
    final response = await sendMessage(message, history: history, context: context);
    yield response;
  }
  
  List<Map<String, String>> _buildMessages(String message, List<AIMessage>? history) {
    final messages = <Map<String, String>>[];
    
    // Add history
    if (history != null) {
      for (final msg in history) {
        messages.add({
          'role': msg.role.name,
          'content': msg.content,
        });
      }
    }
    
    // Add current message
    messages.add({
      'role': 'user',
      'content': message,
    });
    
    return messages;
  }
}

// Claude Client Implementation
class ClaudeClient extends AIClient {
  ClaudeClient(super.config);
  
  @override
  Future<AITestResult> testConnection() async {
    // TODO: Implement Claude test connection
    return AITestResult.success();
  }
  
  @override
  Future<AIResponse> sendMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async {
    // TODO: Implement Claude message sending
    return AIResponse.failure('Claude client not implemented yet');
  }
  
  @override
  Stream<AIResponse> sendStreamingMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async* {
    // TODO: Implement Claude streaming
    yield AIResponse.failure('Claude streaming not implemented yet');
  }
}

// Gemini Client Implementation
class GeminiClient extends AIClient {
  GeminiClient(super.config);
  
  @override
  Future<AITestResult> testConnection() async {
    // TODO: Implement Gemini test connection
    return AITestResult.success();
  }
  
  @override
  Future<AIResponse> sendMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async {
    // TODO: Implement Gemini message sending
    return AIResponse.failure('Gemini client not implemented yet');
  }
  
  @override
  Stream<AIResponse> sendStreamingMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async* {
    // TODO: Implement Gemini streaming
    yield AIResponse.failure('Gemini streaming not implemented yet');
  }
}

// Local AI Client Implementation
class LocalAIClient extends AIClient {
  LocalAIClient(super.config);
  
  @override
  Future<AITestResult> testConnection() async {
    // TODO: Implement local AI test connection
    return AITestResult.success();
  }
  
  @override
  Future<AIResponse> sendMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async {
    // TODO: Implement local AI message sending
    return AIResponse.failure('Local AI client not implemented yet');
  }
  
  @override
  Stream<AIResponse> sendStreamingMessage(String message, {List<AIMessage>? history, Map<String, dynamic>? context}) async* {
    // TODO: Implement local AI streaming
    yield AIResponse.failure('Local AI streaming not implemented yet');
  }
}