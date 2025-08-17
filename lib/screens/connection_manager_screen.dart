import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/connection_card.dart';
import '../widgets/terminal_preview.dart';
import '../widgets/search_bar_custom.dart';
import '../widgets/empty_state.dart';

/// Connection Manager Screen - Manage active SSH connections and terminal sessions
class ConnectionManagerScreen extends ConsumerStatefulWidget {
  const ConnectionManagerScreen({super.key});

  @override
  ConsumerState<ConnectionManagerScreen> createState() => _ConnectionManagerScreenState;
}

class _ConnectionManagerScreenState extends ConsumerState<ConnectionManagerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  String _searchQuery = '';
  ConnectionFilter _filter = ConnectionFilter.all;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }
  
  void _onFilterChanged(ConnectionFilter filter) {
    setState(() {
      _filter = filter;
    });
  }
  
  List<SSHSession> _getFilteredConnections(List<SSHSession> connections) {
    return connections.where((connection) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!connection.serverName.toLowerCase().contains(query) &&
            !connection.host.toLowerCase().contains(query) &&
            !connection.username.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Status filter
      switch (_filter) {
        case ConnectionFilter.all:
          return true;
        case ConnectionFilter.connected:
          return connection.isConnected;
        case ConnectionFilter.disconnected:
          return !connection.isConnected;
        case ConnectionFilter.error:
          return connection.hasError;
      }
    }).toList();
  }
  
  List<WindowState> _getFilteredWindows(List<WindowState> windows) {
    return windows.where((window) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!window.title.toLowerCase().contains(query) &&
            !(window.metadata?['serverName']?.toLowerCase().contains(query) ?? false)) {
          return false;
        }
      }
      
      // Type filter - only show terminal and SSH windows
      return window.type == WindowType.terminal || window.type == WindowType.ssh;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final connections = ref.watch(sshSessionListProvider);
    final windows = ref.watch(windowListProvider);
    final activeWindow = ref.watch(activeWindowProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final filteredConnections = _getFilteredConnections(connections);
    final filteredWindows = _getFilteredWindows(windows);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: l10n.connectionManager,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.link_rounded),
              text: l10n.connections,
            ),
            Tab(
              icon: const Icon(Icons.terminal_rounded),
              text: l10n.terminals,
            ),
            Tab(
              icon: const Icon(Icons.window_rounded),
              text: l10n.windows,
            ),
          ],
          labelColor: isDark ? AppColors.primaryDark : AppColors.primary,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          indicatorColor: isDark ? AppColors.primaryDark : AppColors.primary,
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: () {
              // Refresh connections and windows
              ref.read(sshSessionNotifierProvider.notifier).refreshSessions();
              ref.read(windowStateNotifierProvider.notifier).refreshWindows();
            },
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                SearchBarCustom(
                  controller: _searchController,
                  hintText: l10n.searchConnections,
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: AppSpacing.sm),
                
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ConnectionFilter.values.map((filter) {
                      final isSelected = _filter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          label: Text(_getFilterLabel(filter, l10n)),
                          selected: isSelected,
                          onSelected: (_) => _onFilterChanged(filter),
                          backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
                          selectedColor: isDark ? AppColors.primaryDark.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                          checkmarkColor: isDark ? AppColors.primaryDark : AppColors.primary,
                          labelStyle: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? (isDark ? AppColors.primaryDark : AppColors.primary)
                                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Connections tab
                _buildConnectionsTab(filteredConnections, l10n, isDark),
                
                // Terminals tab
                _buildTerminalsTab(filteredWindows.where((w) => w.type == WindowType.terminal).toList(), l10n, isDark),
                
                // Windows tab
                _buildWindowsTab(filteredWindows, activeWindow, l10n, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionsTab(List<SSHSession> connections, AppLocalizations l10n, bool isDark) {
    if (connections.isEmpty) {
      return EmptyState(
        icon: Icons.link_off_rounded,
        title: _searchQuery.isNotEmpty ? l10n.noConnectionsFound : l10n.noActiveConnections,
        subtitle: _searchQuery.isNotEmpty ? l10n.tryDifferentSearch : l10n.connectToServerFirst,
        actionLabel: _searchQuery.isEmpty ? l10n.browseServers : null,
        onAction: _searchQuery.isEmpty ? () {
          Navigator.pushReplacementNamed(context, '/servers');
        } : null,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: connections.length,
      itemBuilder: (context, index) {
        final connection = connections[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ConnectionCard(
            connection: connection,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/terminal',
                arguments: connection.serverId,
              );
            },
            onDisconnect: () async {
              try {
                await ref.read(sshServiceProvider).disconnect(connection.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.disconnected),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.disconnectionFailed),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            onReconnect: () async {
              try {
                final server = await ref.read(serverByIdProvider(connection.serverId).future);
                if (server != null) {
                  await ref.read(sshServiceProvider).connect(server);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.reconnected),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.reconnectionFailed),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
  
  Widget _buildTerminalsTab(List<WindowState> terminals, AppLocalizations l10n, bool isDark) {
    if (terminals.isEmpty) {
      return EmptyState(
        icon: Icons.terminal_rounded,
        title: _searchQuery.isNotEmpty ? l10n.noTerminalsFound : l10n.noActiveTerminals,
        subtitle: _searchQuery.isNotEmpty ? l10n.tryDifferentSearch : l10n.openTerminalFirst,
        actionLabel: _searchQuery.isEmpty ? l10n.browseServers : null,
        onAction: _searchQuery.isEmpty ? () {
          Navigator.pushReplacementNamed(context, '/servers');
        } : null,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: terminals.length,
      itemBuilder: (context, index) {
        final terminal = terminals[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TerminalPreview(
            window: terminal,
            onTap: () {
              ref.read(windowServiceProvider).focusWindow(terminal.id);
              Navigator.pushNamed(
                context,
                '/terminal',
                arguments: terminal.metadata?['serverId'],
              );
            },
            onClose: () async {
              await ref.read(windowServiceProvider).closeWindow(terminal.id);
            },
            onMinimize: () async {
              await ref.read(windowServiceProvider).minimizeWindow(terminal.id);
            },
            onMaximize: () async {
              await ref.read(windowServiceProvider).maximizeWindow(terminal.id);
            },
          ),
        );
      },
    );
  }
  
  Widget _buildWindowsTab(List<WindowState> windows, WindowState? activeWindow, AppLocalizations l10n, bool isDark) {
    if (windows.isEmpty) {
      return EmptyState(
        icon: Icons.window_rounded,
        title: _searchQuery.isNotEmpty ? l10n.noWindowsFound : l10n.noActiveWindows,
        subtitle: _searchQuery.isNotEmpty ? l10n.tryDifferentSearch : l10n.openWindowFirst,
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: windows.length,
      itemBuilder: (context, index) {
        final window = windows[index];
        final isActive = activeWindow?.id == window.id;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Card(
            elevation: isActive ? 4 : 1,
            color: isActive
                ? (isDark ? AppColors.primaryDark.withOpacity(0.1) : AppColors.primary.withOpacity(0.1))
                : (isDark ? AppColors.surfaceDark : AppColors.surface),
            shape: RoundedRectangleBorder(
              borderRadius: AppBorders.radiusLGAll,
              side: BorderSide(
                color: isActive
                    ? (isDark ? AppColors.primaryDark : AppColors.primary)
                    : (isDark ? AppColors.borderDark : AppColors.border),
                width: isActive ? 2 : 1,
              ),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getWindowTypeColor(window.type, isDark),
                child: Icon(
                  _getWindowTypeIcon(window.type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                window.title,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${window.type.name.toUpperCase()} • ${_formatWindowSize(window)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  if (window.metadata?['serverName'] != null)
                    Text(
                      window.metadata!['serverName']!,
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (window.isMinimized)
                    Icon(
                      Icons.minimize_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      size: 16,
                    ),
                  if (window.isMaximized)
                    Icon(
                      Icons.fullscreen_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      size: 16,
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    onSelected: (action) async {
                      switch (action) {
                        case 'focus':
                          await ref.read(windowServiceProvider).focusWindow(window.id);
                          break;
                        case 'minimize':
                          await ref.read(windowServiceProvider).minimizeWindow(window.id);
                          break;
                        case 'maximize':
                          await ref.read(windowServiceProvider).maximizeWindow(window.id);
                          break;
                        case 'restore':
                          await ref.read(windowServiceProvider).restoreWindow(window.id);
                          break;
                        case 'close':
                          await ref.read(windowServiceProvider).closeWindow(window.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'focus',
                        child: Row(
                          children: [
                            const Icon(Icons.visibility_rounded),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.focus),
                          ],
                        ),
                      ),
                      if (!window.isMinimized)
                        PopupMenuItem(
                          value: 'minimize',
                          child: Row(
                            children: [
                              const Icon(Icons.minimize_rounded),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l10n.minimize),
                            ],
                          ),
                        ),
                      if (!window.isMaximized)
                        PopupMenuItem(
                          value: 'maximize',
                          child: Row(
                            children: [
                              const Icon(Icons.fullscreen_rounded),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l10n.maximize),
                            ],
                          ),
                        ),
                      if (window.isMinimized || window.isMaximized)
                        PopupMenuItem(
                          value: 'restore',
                          child: Row(
                            children: [
                              const Icon(Icons.fullscreen_exit_rounded),
                              const SizedBox(width: AppSpacing.sm),
                              Text(l10n.restore),
                            ],
                          ),
                        ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'close',
                        child: Row(
                          children: [
                            Icon(Icons.close_rounded, color: AppColors.error),
                            const SizedBox(width: AppSpacing.sm),
                            Text(l10n.close, style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                ref.read(windowServiceProvider).focusWindow(window.id);
              },
            ),
          ),
        );
      },
    );
  }
  
  String _getFilterLabel(ConnectionFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case ConnectionFilter.all:
        return l10n.all;
      case ConnectionFilter.connected:
        return l10n.connected;
      case ConnectionFilter.disconnected:
        return l10n.disconnected;
      case ConnectionFilter.error:
        return l10n.error;
    }
  }
  
  Color _getWindowTypeColor(WindowType type, bool isDark) {
    switch (type) {
      case WindowType.terminal:
        return AppColors.terminal;
      case WindowType.ssh:
        return AppColors.sshConnected;
      case WindowType.sftp:
        return AppColors.fileTransfer;
      case WindowType.monitoring:
        return AppColors.chartLine;
      case WindowType.settings:
        return AppColors.gray500;
      default:
        return isDark ? AppColors.primaryDark : AppColors.primary;
    }
  }
  
  IconData _getWindowTypeIcon(WindowType type) {
    switch (type) {
      case WindowType.terminal:
        return Icons.terminal_rounded;
      case WindowType.ssh:
        return Icons.link_rounded;
      case WindowType.sftp:
        return Icons.folder_rounded;
      case WindowType.monitoring:
        return Icons.analytics_rounded;
      case WindowType.settings:
        return Icons.settings_rounded;
      default:
        return Icons.window_rounded;
    }
  }
  
  String _formatWindowSize(WindowState window) {
    return '${window.width.toInt()}×${window.height.toInt()}';
  }
}

// Connection filter enum
enum ConnectionFilter {
  all,
  connected,
  disconnected,
  error,
}