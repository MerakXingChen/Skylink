import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/server_card.dart';
import '../widgets/server_grid.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/floating_action_menu.dart';
import '../widgets/search_bar_custom.dart';
import '../widgets/filter_chips.dart';
import '../widgets/sort_dropdown.dart';
import '../widgets/view_mode_toggle.dart';
import '../widgets/refresh_indicator_custom.dart';

/// Server Preview Screen - Main dashboard showing server grid with real-time metrics
class ServerPreviewScreen extends ConsumerStatefulWidget {
  const ServerPreviewScreen({super.key});

  @override
  ConsumerState<ServerPreviewScreen> createState() => _ServerPreviewScreenState;
}

class _ServerPreviewScreenState extends ConsumerState<ServerPreviewScreen>
    with TickerProviderStateMixin {
  late AnimationController _refreshController;
  late AnimationController _fabController;
  
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _searchQuery = '';
  ServerStatus? _statusFilter;
  ServerSortBy _sortBy = ServerSortBy.name;
  bool _sortAscending = true;
  ViewMode _viewMode = ViewMode.grid;
  bool _isRefreshing = false;
  bool _showFab = true;
  
  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scrollController.addListener(_onScroll);
    _fabController.forward();
    
    // Load servers and start monitoring
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadServers();
    });
  }
  
  @override
  void dispose() {
    _refreshController.dispose();
    _fabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    final shouldShowFab = _scrollController.offset < 100;
    if (shouldShowFab != _showFab) {
      setState(() {
        _showFab = shouldShowFab;
      });
      if (_showFab) {
        _fabController.forward();
      } else {
        _fabController.reverse();
      }
    }
  }
  
  Future<void> _loadServers() async {
    try {
      await ref.read(serverNotifierProvider.notifier).loadServers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorLoadingServers),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  Future<void> _refreshServers() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    _refreshController.repeat();
    
    try {
      await ref.read(serverNotifierProvider.notifier).refreshServers();
      await ref.read(serverMetricsNotifierProvider.notifier).refreshAllMetrics();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorRefreshingServers),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      _refreshController.stop();
      _refreshController.reset();
      setState(() {
        _isRefreshing = false;
      });
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }
  
  void _onStatusFilterChanged(ServerStatus? status) {
    setState(() {
      _statusFilter = status;
    });
  }
  
  void _onSortChanged(ServerSortBy sortBy, bool ascending) {
    setState(() {
      _sortBy = sortBy;
      _sortAscending = ascending;
    });
  }
  
  void _onViewModeChanged(ViewMode mode) {
    setState(() {
      _viewMode = mode;
    });
  }
  
  List<Server> _getFilteredAndSortedServers(List<Server> servers) {
    var filtered = servers.where((server) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!server.name.toLowerCase().contains(query) &&
            !server.host.toLowerCase().contains(query) &&
            !(server.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false)) {
          return false;
        }
      }
      
      // Status filter
      if (_statusFilter != null && server.status != _statusFilter) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case ServerSortBy.name:
          comparison = a.name.compareTo(b.name);
          break;
        case ServerSortBy.host:
          comparison = a.host.compareTo(b.host);
          break;
        case ServerSortBy.status:
          comparison = a.status.index.compareTo(b.status.index);
          break;
        case ServerSortBy.lastConnected:
          comparison = (a.lastConnectedAt ?? DateTime(0))
              .compareTo(b.lastConnectedAt ?? DateTime(0));
          break;
        case ServerSortBy.createdAt:
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });
    
    return filtered;
  }
  
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final servers = ref.watch(serverListProvider);
    final filteredServers = _getFilteredAndSortedServers(servers);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: l10n.serverPreview,
        actions: [
          IconButton(
            icon: AnimatedBuilder(
              animation: _refreshController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _refreshController.value * 2 * 3.14159,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                );
              },
            ),
            onPressed: _isRefreshing ? null : _refreshServers,
            tooltip: l10n.refresh,
          ),
          IconButton(
            icon: Icon(
              Icons.settings_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
            tooltip: l10n.settings,
          ),
        ],
      ),
      body: RefreshIndicatorCustom(
        onRefresh: _refreshServers,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Search and filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    // Search bar
                    SearchBarCustom(
                      controller: _searchController,
                      hintText: l10n.searchServers,
                      onChanged: _onSearchChanged,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    
                    // Filters and controls
                    Row(
                      children: [
                        // Status filter chips
                        Expanded(
                          child: FilterChips(
                            selectedStatus: _statusFilter,
                            onStatusChanged: _onStatusFilterChanged,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        
                        // Sort dropdown
                        SortDropdown(
                          sortBy: _sortBy,
                          ascending: _sortAscending,
                          onChanged: _onSortChanged,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        
                        // View mode toggle
                        ViewModeToggle(
                          mode: _viewMode,
                          onChanged: _onViewModeChanged,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // Server count and status
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.serversCount(filteredServers.length, servers.length),
                      style: AppTypography.bodySmall.copyWith(
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (_isRefreshing)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDark ? AppColors.primaryDark : AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.refreshing,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Server grid/list
            if (filteredServers.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _searchQuery.isNotEmpty || _statusFilter != null
                            ? Icons.search_off_rounded
                            : Icons.dns_rounded,
                        size: 64,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        _searchQuery.isNotEmpty || _statusFilter != null
                            ? l10n.noServersFound
                            : l10n.noServersAdded,
                        style: AppTypography.titleMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _searchQuery.isNotEmpty || _statusFilter != null
                            ? l10n.tryDifferentSearch
                            : l10n.addFirstServer,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_searchQuery.isEmpty && _statusFilter == null) ..[
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pushNamed(context, '/server/add');
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: Text(l10n.addServer),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ServerGrid(
                servers: filteredServers,
                viewMode: _viewMode,
                onServerTap: (server) {
                  Navigator.pushNamed(
                    context,
                    '/server/detail',
                    arguments: server.id,
                  );
                },
                onServerConnect: (server) async {
                  try {
                    await ref.read(sshServiceProvider).connect(server);
                    if (mounted) {
                      Navigator.pushNamed(
                        context,
                        '/terminal',
                        arguments: server.id,
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.connectionFailed(e.toString())),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                onServerEdit: (server) {
                  Navigator.pushNamed(
                    context,
                    '/server/edit',
                    arguments: server.id,
                  );
                },
                onServerDelete: (server) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.deleteServer),
                      content: Text(l10n.deleteServerConfirmation(server.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                          ),
                          child: Text(l10n.delete),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      await ref.read(serverNotifierProvider.notifier).deleteServer(server.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.serverDeleted(server.name)),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.errorDeletingServer),
                            backgroundColor: AppColors.error,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
          ],
        ),
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabController.value,
            child: FloatingActionMenu(
              visible: _showFab,
              onAddServer: () {
                Navigator.pushNamed(context, '/server/add');
              },
              onImportServers: () {
                Navigator.pushNamed(context, '/server/import');
              },
              onScanNetwork: () {
                Navigator.pushNamed(context, '/server/scan');
              },
            ),
          );
        },
      ),
    );
  }
}

// Enums for sorting and view mode
enum ServerSortBy {
  name,
  host,
  status,
  lastConnected,
  createdAt,
}

enum ViewMode {
  grid,
  list,
  compact,
}