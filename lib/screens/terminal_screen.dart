import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xterm/xterm.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/terminal_widget.dart';
import '../widgets/connection_status_bar.dart';
import '../widgets/ai_assistant_panel.dart';
import '../widgets/sftp_panel.dart';
import '../widgets/quick_actions_bar.dart';

/// Terminal Screen - SSH terminal interface with AI assistant and file transfer
class TerminalScreen extends ConsumerStatefulWidget {
  final String? serverId;
  final String? sessionId;
  
  const TerminalScreen({
    super.key,
    this.serverId,
    this.sessionId,
  });

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState;
}

class _TerminalScreenState extends ConsumerState<TerminalScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late Terminal _terminal;
  
  bool _isConnecting = false;
  bool _showAIPanel = false;
  bool _showSftpPanel = false;
  String? _currentSessionId;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _terminal = Terminal();
    _currentSessionId = widget.sessionId;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeConnection();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _terminal.dispose();
    super.dispose();
  }
  
  Future<void> _initializeConnection() async {
    if (widget.serverId == null) return;
    
    setState(() => _isConnecting = true);
    
    try {
      final server = await ref.read(serverByIdProvider(widget.serverId!).future);
      if (server != null && mounted) {
        final sessionId = await ref.read(sshServiceProvider).connect(server);
        setState(() {
          _currentSessionId = sessionId;
          _isConnecting = false;
        });
        
        // Create terminal session
        await _createTerminalSession(sessionId);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        _showErrorSnackBar(AppLocalizations.of(context)!.connectionFailed);
      }
    }
  }
  
  Future<void> _createTerminalSession(String sessionId) async {
    try {
      final shellResult = await ref.read(sshServiceProvider).createShell(sessionId);
      if (shellResult.success && shellResult.shell != null) {
        // Connect terminal to SSH shell
        _terminal.onOutput = (data) {
          shellResult.shell!.write(data);
        };
        
        shellResult.shell!.stdout.listen((data) {
          _terminal.write(String.fromCharCodes(data));
        });
        
        shellResult.shell!.stderr.listen((data) {
          _terminal.write(String.fromCharCodes(data));
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.terminalCreationFailed);
      }
    }
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
    final session = _currentSessionId != null
        ? ref.watch(sshSessionByIdProvider(_currentSessionId!))
        : null;
    final settings = ref.watch(appSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: session?.serverName ?? l10n.terminal,
        subtitle: session != null ? '${session.username}@${session.host}' : null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (session != null) ..[
            IconButton(
              icon: Icon(
                _showAIPanel ? Icons.smart_toy_rounded : Icons.smart_toy_outlined,
                color: _showAIPanel
                    ? (isDark ? AppColors.primaryDark : AppColors.primary)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ),
              onPressed: settings.enableAI ? () {
                setState(() => _showAIPanel = !_showAIPanel);
              } : null,
              tooltip: l10n.aiAssistant,
            ),
            IconButton(
              icon: Icon(
                _showSftpPanel ? Icons.folder_rounded : Icons.folder_outlined,
                color: _showSftpPanel
                    ? (isDark ? AppColors.primaryDark : AppColors.primary)
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
              ),
              onPressed: () {
                setState(() => _showSftpPanel = !_showSftpPanel);
              },
              tooltip: l10n.fileManager,
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert_rounded,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              onSelected: (action) => _handleMenuAction(action, session),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'reconnect',
                  child: Row(
                    children: [
                      const Icon(Icons.refresh_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.reconnect),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_tab',
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.newTab),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      const Icon(Icons.content_copy_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.duplicate),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings_rounded),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.settings),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'disconnect',
                  child: Row(
                    children: [
                      Icon(Icons.close_rounded, color: AppColors.error),
                      const SizedBox(width: AppSpacing.sm),
                      Text(l10n.disconnect, style: TextStyle(color: AppColors.error)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      body: _isConnecting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.connecting,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : session == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 64,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        l10n.connectionFailed,
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.checkConnectionSettings,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.goBack),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Connection status bar
                    ConnectionStatusBar(
                      session: session,
                      onReconnect: () => _reconnect(session),
                    ),
                    
                    // Main content area
                    Expanded(
                      child: Row(
                        children: [
                          // Terminal area
                          Expanded(
                            flex: _showAIPanel || _showSftpPanel ? 2 : 3,
                            child: Column(
                              children: [
                                // Terminal tabs
                                if (_tabController.length > 1)
                                  Container(
                                    color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                    child: TabBar(
                                      controller: _tabController,
                                      isScrollable: true,
                                      tabs: List.generate(
                                        _tabController.length,
                                        (index) => Tab(
                                          text: 'Terminal ${index + 1}',
                                          icon: const Icon(Icons.terminal_rounded, size: 16),
                                        ),
                                      ),
                                      labelColor: isDark ? AppColors.primaryDark : AppColors.primary,
                                      unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                      indicatorColor: isDark ? AppColors.primaryDark : AppColors.primary,
                                    ),
                                  ),
                                
                                // Terminal content
                                Expanded(
                                  child: Container(
                                    color: isDark ? AppColors.terminalBackgroundDark : AppColors.terminalBackground,
                                    child: TabBarView(
                                      controller: _tabController,
                                      children: List.generate(
                                        _tabController.length,
                                        (index) => TerminalWidget(
                                          terminal: _terminal,
                                          session: session,
                                          settings: settings,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Quick actions bar
                                QuickActionsBar(
                                  session: session,
                                  onCommand: (command) => _executeCommand(command),
                                  onClear: () => _terminal.clear(),
                                  onCopy: () => _copySelection(),
                                  onPaste: () => _pasteFromClipboard(),
                                ),
                              ],
                            ),
                          ),
                          
                          // AI Assistant Panel
                          if (_showAIPanel)
                            Container(
                              width: 400,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.border,
                                  ),
                                ),
                              ),
                              child: AIAssistantPanel(
                                session: session,
                                onClose: () => setState(() => _showAIPanel = false),
                                onCommandSuggestion: (command) => _executeCommand(command),
                              ),
                            ),
                          
                          // SFTP Panel
                          if (_showSftpPanel)
                            Container(
                              width: 400,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.border,
                                  ),
                                ),
                              ),
                              child: SftpPanel(
                                session: session,
                                onClose: () => setState(() => _showSftpPanel = false),
                                onPathChange: (path) => _executeCommand('cd $path'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
  
  void _handleMenuAction(String action, SSHSession session) async {
    final l10n = AppLocalizations.of(context)!;
    
    switch (action) {
      case 'reconnect':
        await _reconnect(session);
        break;
      case 'new_tab':
        _addNewTab();
        break;
      case 'duplicate':
        _duplicateTab();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
      case 'disconnect':
        await _disconnect(session);
        break;
    }
  }
  
  Future<void> _reconnect(SSHSession session) async {
    try {
      setState(() => _isConnecting = true);
      
      // Disconnect first
      await ref.read(sshServiceProvider).disconnect(session.id);
      
      // Get server and reconnect
      final server = await ref.read(serverByIdProvider(session.serverId).future);
      if (server != null) {
        final newSessionId = await ref.read(sshServiceProvider).connect(server);
        setState(() {
          _currentSessionId = newSessionId;
          _isConnecting = false;
        });
        
        await _createTerminalSession(newSessionId);
        _showSuccessSnackBar(AppLocalizations.of(context)!.reconnected);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConnecting = false);
        _showErrorSnackBar(AppLocalizations.of(context)!.reconnectionFailed);
      }
    }
  }
  
  Future<void> _disconnect(SSHSession session) async {
    try {
      await ref.read(sshServiceProvider).disconnect(session.id);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(AppLocalizations.of(context)!.disconnectionFailed);
      }
    }
  }
  
  void _addNewTab() {
    setState(() {
      _tabController.dispose();
      _tabController = TabController(length: _tabController.length + 1, vsync: this);
      _tabController.animateTo(_tabController.length - 1);
    });
  }
  
  void _duplicateTab() {
    _addNewTab();
  }
  
  void _executeCommand(String command) {
    _terminal.write('$command\n');
  }
  
  void _copySelection() {
    // TODO: Implement copy selection
    _showSuccessSnackBar(AppLocalizations.of(context)!.copied);
  }
  
  void _pasteFromClipboard() {
    // TODO: Implement paste from clipboard
    _showSuccessSnackBar(AppLocalizations.of(context)!.pasted);
  }
}