import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/ai_chat_widget.dart';
import '../widgets/ai_code_analysis_widget.dart';
import '../widgets/ai_command_generator_widget.dart';
import '../widgets/ai_settings_panel.dart';

/// AI Assistant Screen - AI chat, code analysis, and command generation
class AIAssistantScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? initialMessage;
  final AIAssistantMode mode;
  
  const AIAssistantScreen({
    super.key,
    this.sessionId,
    this.initialMessage,
    this.mode = AIAssistantMode.chat,
  });

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState;
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _messageController;
  late ScrollController _chatScrollController;
  
  bool _isLoading = false;
  bool _showSettings = false;
  AIAssistantMode _currentMode = AIAssistantMode.chat;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _messageController = TextEditingController(text: widget.initialMessage);
    _chatScrollController = ScrollController();
    _currentMode = widget.mode;
    
    // Set initial tab based on mode
    switch (widget.mode) {
      case AIAssistantMode.chat:
        _tabController.index = 0;
        break;
      case AIAssistantMode.codeAnalysis:
        _tabController.index = 1;
        break;
      case AIAssistantMode.commandGeneration:
        _tabController.index = 2;
        break;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAI();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }
  
  Future<void> _initializeAI() async {
    final aiConfig = ref.read(aiConfigProvider);
    if (!aiConfig.enableAI) {
      _showAIDisabledDialog();
      return;
    }
    
    // Test AI configuration
    setState(() => _isLoading = true);
    
    try {
      final testResult = await ref.read(aiServiceProvider).testConfiguration();
      if (!testResult.success && mounted) {
        _showConfigurationErrorDialog(testResult.error ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        _showConfigurationErrorDialog(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  void _showAIDisabledDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.aiDisabled),
        content: Text(AppLocalizations.of(context)!.aiDisabledMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
            child: Text(AppLocalizations.of(context)!.settings),
          ),
        ],
      ),
    );
  }
  
  void _showConfigurationErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.aiConfigurationError),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.aiConfigurationErrorMessage),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.errorLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSM),
                border: Border.all(color: AppColors.errorLight),
              ),
              child: Text(
                error,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.error,
                  fontFamily: AppTypography.fontFamilyMono,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _showSettings = true);
            },
            child: Text(AppLocalizations.of(context)!.configure),
          ),
        ],
      ),
    );
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aiConfig = ref.watch(aiConfigProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: l10n.aiAssistant,
        subtitle: _getSubtitle(l10n),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showSettings ? Icons.settings_rounded : Icons.settings_outlined,
              color: _showSettings
                  ? (isDark ? AppColors.primaryDark : AppColors.primary)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            onPressed: () {
              setState(() => _showSettings = !_showSettings);
            },
            tooltip: l10n.settings,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onSelected: (action) => _handleMenuAction(action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear_history',
                child: Row(
                  children: [
                    const Icon(Icons.clear_all_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.clearHistory),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_chat',
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.exportChat),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'test_connection',
                child: Row(
                  children: [
                    const Icon(Icons.wifi_tethering_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.testConnection),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset_session',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, color: AppColors.warning),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.resetSession, style: TextStyle(color: AppColors.warning)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.initializingAI,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : !aiConfig.enableAI
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        size: 64,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.aiDisabled,
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.enableAIInSettings,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/settings'),
                        child: Text(l10n.openSettings),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Main content area
                    Expanded(
                      flex: _showSettings ? 2 : 3,
                      child: Column(
                        children: [
                          // Tab bar
                          Container(
                            color: isDark ? AppColors.surfaceDark : AppColors.surface,
                            child: TabBar(
                              controller: _tabController,
                              onTap: (index) {
                                setState(() {
                                  _currentMode = AIAssistantMode.values[index];
                                });
                              },
                              tabs: [
                                Tab(
                                  icon: const Icon(Icons.chat_rounded, size: 20),
                                  text: l10n.chat,
                                ),
                                Tab(
                                  icon: const Icon(Icons.code_rounded, size: 20),
                                  text: l10n.codeAnalysis,
                                ),
                                Tab(
                                  icon: const Icon(Icons.terminal_rounded, size: 20),
                                  text: l10n.commandGenerator,
                                ),
                              ],
                              labelColor: isDark ? AppColors.primaryDark : AppColors.primary,
                              unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              indicatorColor: isDark ? AppColors.primaryDark : AppColors.primary,
                            ),
                          ),
                          
                          // Tab content
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                // Chat tab
                                AIChatWidget(
                                  sessionId: widget.sessionId,
                                  messageController: _messageController,
                                  scrollController: _chatScrollController,
                                  onSendMessage: _sendMessage,
                                  onClearHistory: _clearHistory,
                                ),
                                
                                // Code analysis tab
                                AICodeAnalysisWidget(
                                  sessionId: widget.sessionId,
                                  onAnalyze: _analyzeCode,
                                  onSendToChat: _sendToChat,
                                ),
                                
                                // Command generator tab
                                AICommandGeneratorWidget(
                                  sessionId: widget.sessionId,
                                  onGenerate: _generateCommand,
                                  onExecute: _executeCommand,
                                  onSendToTerminal: _sendToTerminal,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Settings panel
                    if (_showSettings)
                      Container(
                        width: 350,
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surface,
                          border: Border(
                            left: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                        ),
                        child: AISettingsPanel(
                          onClose: () => setState(() => _showSettings = false),
                          onConfigurationChanged: _onConfigurationChanged,
                        ),
                      ),
                  ],
                ),
    );
  }
  
  String _getSubtitle(AppLocalizations l10n) {
    final aiConfig = ref.watch(aiConfigProvider);
    switch (_currentMode) {
      case AIAssistantMode.chat:
        return '${aiConfig.provider.name} • ${l10n.chat}';
      case AIAssistantMode.codeAnalysis:
        return '${aiConfig.provider.name} • ${l10n.codeAnalysis}';
      case AIAssistantMode.commandGeneration:
        return '${aiConfig.provider.name} • ${l10n.commandGenerator}';
    }
  }
  
  void _handleMenuAction(String action) async {
    final l10n = AppLocalizations.of(context)!;
    
    switch (action) {
      case 'clear_history':
        await _clearHistory();
        break;
      case 'export_chat':
        await _exportChat();
        break;
      case 'test_connection':
        await _testConnection();
        break;
      case 'reset_session':
        await _resetSession();
        break;
    }
  }
  
  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;
    
    try {
      setState(() => _isLoading = true);
      
      final response = await ref.read(aiServiceProvider).sendMessage(
        message,
        sessionId: widget.sessionId,
      );
      
      if (response.success) {
        _messageController.clear();
        _scrollToBottom();
        _showSuccessSnackBar(AppLocalizations.of(context)!.messageSent);
      } else {
        _showErrorSnackBar(response.error ?? AppLocalizations.of(context)!.messageFailed);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _analyzeCode(String code, String language) async {
    try {
      setState(() => _isLoading = true);
      
      final result = await ref.read(aiServiceProvider).analyzeCode(
        code,
        language: language,
        sessionId: widget.sessionId,
      );
      
      if (result.success) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.analysisCompleted);
      } else {
        _showErrorSnackBar(result.error ?? AppLocalizations.of(context)!.analysisFailed);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _generateCommand(String description, String context) async {
    try {
      setState(() => _isLoading = true);
      
      final result = await ref.read(aiServiceProvider).generateCommand(
        description,
        context: context,
        sessionId: widget.sessionId,
      );
      
      if (result.success) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.commandGenerated);
      } else {
        _showErrorSnackBar(result.error ?? AppLocalizations.of(context)!.commandGenerationFailed);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _clearHistory() async {
    try {
      await ref.read(aiServiceProvider).clearHistory(sessionId: widget.sessionId);
      _showSuccessSnackBar(AppLocalizations.of(context)!.historyCleared);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }
  
  Future<void> _exportChat() async {
    try {
      // TODO: Implement chat export
      _showSuccessSnackBar(AppLocalizations.of(context)!.chatExported);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }
  
  Future<void> _testConnection() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await ref.read(aiServiceProvider).testConfiguration();
      
      if (result.success) {
        _showSuccessSnackBar(AppLocalizations.of(context)!.connectionSuccessful);
      } else {
        _showErrorSnackBar(result.error ?? AppLocalizations.of(context)!.connectionFailed);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<void> _resetSession() async {
    try {
      await ref.read(aiServiceProvider).clearHistory(sessionId: widget.sessionId);
      _showSuccessSnackBar(AppLocalizations.of(context)!.sessionReset);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }
  
  void _sendToChat(String message) {
    _tabController.animateTo(0);
    _messageController.text = message;
  }
  
  void _executeCommand(String command) {
    // TODO: Execute command in terminal
    _showSuccessSnackBar('${AppLocalizations.of(context)!.executing}: $command');
  }
  
  void _sendToTerminal(String command) {
    Navigator.pushNamed(
      context,
      '/terminal',
      arguments: {
        'sessionId': widget.sessionId,
        'command': command,
      },
    );
  }
  
  void _onConfigurationChanged() {
    _initializeAI();
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

/// AI Assistant Mode enumeration
enum AIAssistantMode {
  chat,
  codeAnalysis,
  commandGeneration,
}