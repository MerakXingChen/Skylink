import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/draggable_widget_grid.dart';
import '../widgets/widget_config_panel.dart';
import '../widgets/server_metrics_widget.dart';
import '../widgets/system_info_widget.dart';
import '../widgets/network_stats_widget.dart';
import '../widgets/process_monitor_widget.dart';
import '../widgets/disk_usage_widget.dart';
import '../widgets/quick_actions_widget.dart';

/// Widget Dashboard Screen - Customizable monitoring dashboard
class WidgetDashboardScreen extends ConsumerStatefulWidget {
  final String? serverId;
  final bool isEditMode;
  
  const WidgetDashboardScreen({
    super.key,
    this.serverId,
    this.isEditMode = false,
  });

  @override
  ConsumerState<WidgetDashboardScreen> createState() => _WidgetDashboardScreenState;
}

class _WidgetDashboardScreenState extends ConsumerState<WidgetDashboardScreen>
    with TickerProviderStateMixin {
  bool _isEditMode = false;
  bool _showConfigPanel = false;
  bool _isLoading = false;
  String? _selectedWidgetId;
  List<DashboardWidget> _widgets = [];
  Map<String, ServerPreviewMetrics> _serverMetrics = {};
  
  late AnimationController _editModeController;
  late Animation<double> _editModeAnimation;
  
  @override
  void initState() {
    super.initState();
    _isEditMode = widget.isEditMode;
    
    _editModeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _editModeAnimation = CurvedAnimation(
      parent: _editModeController,
      curve: Curves.easeInOut,
    );
    
    if (_isEditMode) {
      _editModeController.forward();
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardLayout();
      _startMetricsUpdates();
    });
  }
  
  @override
  void dispose() {
    _editModeController.dispose();
    super.dispose();
  }
  
  Future<void> _loadDashboardLayout() async {
    setState(() => _isLoading = true);
    
    try {
      final layout = await ref.read(storageServiceProvider).getWidgetLayout();
      if (layout != null) {
        setState(() => _widgets = layout.widgets);
      } else {
        // Create default layout
        _createDefaultLayout();
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
  
  void _createDefaultLayout() {
    final defaultWidgets = [
      DashboardWidget(
        id: 'server_metrics_1',
        type: WidgetType.serverMetrics,
        title: 'Server Overview',
        position: const WidgetPosition(x: 0, y: 0, width: 2, height: 2),
        config: {
          'serverId': widget.serverId,
          'showCpu': true,
          'showMemory': true,
          'showDisk': true,
          'showNetwork': true,
        },
        isVisible: true,
      ),
      DashboardWidget(
        id: 'system_info_1',
        type: WidgetType.systemInfo,
        title: 'System Information',
        position: const WidgetPosition(x: 2, y: 0, width: 2, height: 1),
        config: {
          'serverId': widget.serverId,
          'showUptime': true,
          'showLoadAverage': true,
          'showProcessCount': true,
        },
        isVisible: true,
      ),
      DashboardWidget(
        id: 'quick_actions_1',
        type: WidgetType.quickActions,
        title: 'Quick Actions',
        position: const WidgetPosition(x: 2, y: 1, width: 2, height: 1),
        config: {
          'serverId': widget.serverId,
          'actions': ['connect', 'restart', 'shutdown', 'terminal'],
        },
        isVisible: true,
      ),
      DashboardWidget(
        id: 'network_stats_1',
        type: WidgetType.networkStats,
        title: 'Network Statistics',
        position: const WidgetPosition(x: 0, y: 2, width: 2, height: 1),
        config: {
          'serverId': widget.serverId,
          'showBandwidth': true,
          'showConnections': true,
          'showPackets': true,
        },
        isVisible: true,
      ),
      DashboardWidget(
        id: 'disk_usage_1',
        type: WidgetType.diskUsage,
        title: 'Disk Usage',
        position: const WidgetPosition(x: 2, y: 2, width: 2, height: 1),
        config: {
          'serverId': widget.serverId,
          'showAllDisks': true,
          'showUsageChart': true,
        },
        isVisible: true,
      ),
    ];
    
    setState(() => _widgets = defaultWidgets);
    _saveDashboardLayout();
  }
  
  Future<void> _saveDashboardLayout() async {
    try {
      final layout = WidgetLayout(
        id: 'dashboard_${widget.serverId ?? 'default'}',
        name: 'Dashboard Layout',
        widgets: _widgets,
        gridColumns: 4,
        gridRows: 6,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      await ref.read(storageServiceProvider).saveWidgetLayout(layout);
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }
  
  void _startMetricsUpdates() {
    if (widget.serverId != null) {
      ref.read(monitoringServiceProvider).startMonitoring([widget.serverId!]);
    }
  }
  
  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
    
    if (_isEditMode) {
      _editModeController.forward();
    } else {
      _editModeController.reverse();
      _saveDashboardLayout();
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
    final server = widget.serverId != null
        ? ref.watch(serverByIdProvider(widget.serverId!))
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: l10n.dashboard,
        subtitle: server?.name ?? l10n.allServers,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Edit mode toggle
          AnimatedBuilder(
            animation: _editModeAnimation,
            builder: (context, child) {
              return IconButton(
                icon: Icon(
                  _isEditMode ? Icons.done_rounded : Icons.edit_rounded,
                  color: _isEditMode
                      ? AppColors.success
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                ),
                onPressed: _toggleEditMode,
                tooltip: _isEditMode ? l10n.doneEditing : l10n.editLayout,
              );
            },
          ),
          
          // Add widget button (only in edit mode)
          AnimatedBuilder(
            animation: _editModeAnimation,
            builder: (context, child) {
              return AnimatedScale(
                scale: _editModeAnimation.value,
                duration: const Duration(milliseconds: 200),
                child: _editModeAnimation.value > 0.5
                    ? IconButton(
                        icon: const Icon(Icons.add_rounded),
                        onPressed: _showAddWidgetDialog,
                        tooltip: l10n.addWidget,
                      )
                    : const SizedBox.shrink(),
              );
            },
          ),
          
          // Config panel toggle
          IconButton(
            icon: Icon(
              _showConfigPanel ? Icons.settings_rounded : Icons.settings_outlined,
              color: _showConfigPanel
                  ? (isDark ? AppColors.primaryDark : AppColors.primary)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            onPressed: () {
              setState(() => _showConfigPanel = !_showConfigPanel);
            },
            tooltip: l10n.widgetSettings,
          ),
          
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onSelected: (action) => _handleMenuAction(action),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    const Icon(Icons.refresh_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.refresh),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'reset_layout',
                child: Row(
                  children: [
                    const Icon(Icons.restore_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.resetLayout),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'export_layout',
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.exportLayout),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import_layout',
                child: Row(
                  children: [
                    const Icon(Icons.upload_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.importLayout),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'fullscreen',
                child: Row(
                  children: [
                    const Icon(Icons.fullscreen_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.fullscreen),
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
                    l10n.loadingDashboard,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Main dashboard area
                Expanded(
                  flex: _showConfigPanel ? 3 : 4,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: DraggableWidgetGrid(
                      widgets: _widgets,
                      isEditMode: _isEditMode,
                      gridColumns: 4,
                      gridRows: 6,
                      onWidgetMoved: _onWidgetMoved,
                      onWidgetResized: _onWidgetResized,
                      onWidgetSelected: _onWidgetSelected,
                      onWidgetDeleted: _onWidgetDeleted,
                      widgetBuilder: _buildWidget,
                    ),
                  ),
                ),
                
                // Configuration panel
                if (_showConfigPanel)
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
                    child: WidgetConfigPanel(
                      selectedWidget: _selectedWidgetId != null
                          ? _widgets.firstWhere((w) => w.id == _selectedWidgetId)
                          : null,
                      onClose: () => setState(() => _showConfigPanel = false),
                      onWidgetUpdated: _onWidgetUpdated,
                      onWidgetDuplicated: _onWidgetDuplicated,
                      onWidgetDeleted: (widgetId) => _onWidgetDeleted(widgetId),
                    ),
                  ),
              ],
            ),
      
      // Floating action button for quick actions (only in non-edit mode)
      floatingActionButton: !_isEditMode
          ? FloatingActionButton(
              onPressed: _showQuickActionsMenu,
              backgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
              child: const Icon(Icons.speed_rounded, color: Colors.white),
              tooltip: l10n.quickActions,
            )
          : null,
    );
  }
  
  Widget _buildWidget(DashboardWidget widget) {
    switch (widget.type) {
      case WidgetType.serverMetrics:
        return ServerMetricsWidget(
          serverId: widget.config['serverId'] as String?,
          showCpu: widget.config['showCpu'] as bool? ?? true,
          showMemory: widget.config['showMemory'] as bool? ?? true,
          showDisk: widget.config['showDisk'] as bool? ?? true,
          showNetwork: widget.config['showNetwork'] as bool? ?? true,
        );
      
      case WidgetType.systemInfo:
        return SystemInfoWidget(
          serverId: widget.config['serverId'] as String?,
          showUptime: widget.config['showUptime'] as bool? ?? true,
          showLoadAverage: widget.config['showLoadAverage'] as bool? ?? true,
          showProcessCount: widget.config['showProcessCount'] as bool? ?? true,
        );
      
      case WidgetType.networkStats:
        return NetworkStatsWidget(
          serverId: widget.config['serverId'] as String?,
          showBandwidth: widget.config['showBandwidth'] as bool? ?? true,
          showConnections: widget.config['showConnections'] as bool? ?? true,
          showPackets: widget.config['showPackets'] as bool? ?? true,
        );
      
      case WidgetType.processMonitor:
        return ProcessMonitorWidget(
          serverId: widget.config['serverId'] as String?,
          maxProcesses: widget.config['maxProcesses'] as int? ?? 10,
          sortBy: widget.config['sortBy'] as String? ?? 'cpu',
        );
      
      case WidgetType.diskUsage:
        return DiskUsageWidget(
          serverId: widget.config['serverId'] as String?,
          showAllDisks: widget.config['showAllDisks'] as bool? ?? true,
          showUsageChart: widget.config['showUsageChart'] as bool? ?? true,
        );
      
      case WidgetType.quickActions:
        return QuickActionsWidget(
          serverId: widget.config['serverId'] as String?,
          actions: (widget.config['actions'] as List<dynamic>?)?.cast<String>() ?? [],
        );
      
      default:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.error),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Unknown Widget Type',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.error),
                ),
              ],
            ),
          ),
        );
    }
  }
  
  void _handleMenuAction(String action) async {
    final l10n = AppLocalizations.of(context)!;
    
    switch (action) {
      case 'refresh':
        await _refreshDashboard();
        break;
      case 'reset_layout':
        await _resetLayout();
        break;
      case 'export_layout':
        await _exportLayout();
        break;
      case 'import_layout':
        await _importLayout();
        break;
      case 'fullscreen':
        await _enterFullscreen();
        break;
    }
  }
  
  Future<void> _refreshDashboard() async {
    await _loadDashboardLayout();
    _startMetricsUpdates();
    _showSuccessSnackBar(AppLocalizations.of(context)!.dashboardRefreshed);
  }
  
  Future<void> _resetLayout() async {
    _createDefaultLayout();
    _showSuccessSnackBar(AppLocalizations.of(context)!.layoutReset);
  }
  
  Future<void> _exportLayout() async {
    // TODO: Implement layout export
    _showSuccessSnackBar(AppLocalizations.of(context)!.layoutExported);
  }
  
  Future<void> _importLayout() async {
    // TODO: Implement layout import
    _showSuccessSnackBar(AppLocalizations.of(context)!.layoutImported);
  }
  
  Future<void> _enterFullscreen() async {
    // TODO: Implement fullscreen mode
    _showSuccessSnackBar(AppLocalizations.of(context)!.enteredFullscreen);
  }
  
  void _showAddWidgetDialog() {
    // TODO: Implement add widget dialog
    _showSuccessSnackBar(AppLocalizations.of(context)!.widgetAdded);
  }
  
  void _showQuickActionsMenu() {
    // TODO: Implement quick actions menu
  }
  
  void _onWidgetMoved(String widgetId, WidgetPosition newPosition) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == widgetId);
      if (index != -1) {
        _widgets[index] = _widgets[index].copyWith(position: newPosition);
      }
    });
    
    if (!_isEditMode) {
      _saveDashboardLayout();
    }
  }
  
  void _onWidgetResized(String widgetId, WidgetPosition newPosition) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == widgetId);
      if (index != -1) {
        _widgets[index] = _widgets[index].copyWith(position: newPosition);
      }
    });
    
    if (!_isEditMode) {
      _saveDashboardLayout();
    }
  }
  
  void _onWidgetSelected(String? widgetId) {
    setState(() => _selectedWidgetId = widgetId);
    
    if (widgetId != null && !_showConfigPanel) {
      setState(() => _showConfigPanel = true);
    }
  }
  
  void _onWidgetDeleted(String widgetId) {
    setState(() {
      _widgets.removeWhere((w) => w.id == widgetId);
      if (_selectedWidgetId == widgetId) {
        _selectedWidgetId = null;
      }
    });
    
    _saveDashboardLayout();
    _showSuccessSnackBar(AppLocalizations.of(context)!.widgetDeleted);
  }
  
  void _onWidgetUpdated(DashboardWidget updatedWidget) {
    setState(() {
      final index = _widgets.indexWhere((w) => w.id == updatedWidget.id);
      if (index != -1) {
        _widgets[index] = updatedWidget;
      }
    });
    
    _saveDashboardLayout();
    _showSuccessSnackBar(AppLocalizations.of(context)!.widgetUpdated);
  }
  
  void _onWidgetDuplicated(DashboardWidget widget) {
    final duplicatedWidget = widget.copyWith(
      id: 'widget_${DateTime.now().millisecondsSinceEpoch}',
      position: WidgetPosition(
        x: widget.position.x + 1,
        y: widget.position.y + 1,
        width: widget.position.width,
        height: widget.position.height,
      ),
    );
    
    setState(() => _widgets.add(duplicatedWidget));
    _saveDashboardLayout();
    _showSuccessSnackBar(AppLocalizations.of(context)!.widgetDuplicated);
  }
}