import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/index.dart';
import '../providers/index.dart';
import '../theme/index.dart';
import '../generated/l10n.dart';
import '../routes/app_routes.dart';
import '../utils/index.dart';

class ServerDetailsScreen extends ConsumerStatefulWidget {
  final String serverId;
  
  const ServerDetailsScreen({super.key, required this.serverId});
  
  @override
  ConsumerState<ServerDetailsScreen> createState() => _ServerDetailsScreenState();
}

class _ServerDetailsScreenState extends ConsumerState<ServerDetailsScreen> {
  bool _isConnecting = false;
  bool _isRefreshing = false;
  
  @override
  Widget build(BuildContext context) {
    final servers = ref.watch(serversProvider);
    final server = servers.firstWhere(
      (s) => s.id == widget.serverId,
      orElse: () => throw Exception('Server not found'),
    );
    
    final metrics = ref.watch(serverMetricsProvider(widget.serverId));
    final sessions = ref.watch(sshSessionsProvider)
        .where((session) => session.serverId == widget.serverId)
        .toList();
    
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          server.name,
          style: AppTypography.h3.copyWith(
            color: AppColors.textPrimary(context),
          ),
        ),
        backgroundColor: AppColors.surface(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppColors.textPrimary(context),
            ),
            onPressed: _isRefreshing ? null : _refreshServerData,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: AppColors.textPrimary(context),
            ),
            onSelected: (value) => _handleMenuAction(value, server),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_rounded, color: AppColors.textSecondary(context)),
                    AppSpacing.horizontalS,
                    Text(S.of(context).edit),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded, color: AppColors.textSecondary(context)),
                    AppSpacing.horizontalS,
                    Text(S.of(context).duplicate),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download_rounded, color: AppColors.textSecondary(context)),
                    AppSpacing.horizontalS,
                    Text(S.of(context).export),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: AppColors.error),
                    AppSpacing.horizontalS,
                    Text(
                      S.of(context).delete,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshServerData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.paddingL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Status Card
              _buildServerStatusCard(server),
              
              AppSpacing.verticalL,
              
              // Quick Actions
              _buildQuickActions(server, sessions),
              
              AppSpacing.verticalL,
              
              // Server Metrics
              if (metrics.hasValue && metrics.value != null)
                _buildMetricsSection(metrics.value!),
              
              AppSpacing.verticalL,
              
              // Active Sessions
              _buildActiveSessionsSection(sessions),
              
              AppSpacing.verticalL,
              
              // Server Information
              _buildServerInfoSection(server),
              
              AppSpacing.verticalL,
              
              // Connection History
              _buildConnectionHistorySection(server),
              
              AppSpacing.verticalXXL,
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isConnecting ? null : () => _connectToServer(server),
        backgroundColor: _getConnectionButtonColor(server.status),
        icon: _isConnecting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                ),
              )
            : Icon(
                _getConnectionButtonIcon(server.status),
                color: AppColors.onPrimary,
              ),
        label: Text(
          _getConnectionButtonText(server.status),
          style: AppTypography.button.copyWith(
            color: AppColors.onPrimary,
          ),
        ),
      ),
    );
  }
  
  Widget _buildServerStatusCard(Server server) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.paddingL,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        border: Border.all(color: AppColors.border(context)),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getStatusColor(server.status),
                  shape: BoxShape.circle,
                ),
              ),
              AppSpacing.horizontalS,
              Text(
                _getStatusText(server.status),
                style: AppTypography.body1.copyWith(
                  color: AppColors.textPrimary(context),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (server.lastConnected != null)
                Text(
                  DateTimeUtils.formatRelative(server.lastConnected!),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
            ],
          ),
          AppSpacing.verticalM,
          Row(
            children: [
              Icon(
                Icons.computer_rounded,
                size: 16,
                color: AppColors.textSecondary(context),
              ),
              AppSpacing.horizontalXS,
              Text(
                '${server.host}:${server.port}',
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
              AppSpacing.horizontalM,
              Icon(
                Icons.person_rounded,
                size: 16,
                color: AppColors.textSecondary(context),
              ),
              AppSpacing.horizontalXS,
              Text(
                server.username,
                style: AppTypography.body2.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
          if (server.description != null) ...[
            AppSpacing.verticalS,
            Text(
              server.description!,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
          if (server.tags.isNotEmpty) ...[
            AppSpacing.verticalM,
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: server.tags.map((tag) => _buildTag(tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusS),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: Text(
        tag,
        style: AppTypography.caption.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
  
  Widget _buildQuickActions(Server server, List<SSHSession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).quickActions,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.verticalM,
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.terminal_rounded,
                label: S.of(context).terminal,
                onPressed: () => AppNavigation.pushTerminal(
                  context,
                  serverId: server.id,
                ),
              ),
            ),
            AppSpacing.horizontalS,
            Expanded(
              child: _buildActionButton(
                icon: Icons.folder_rounded,
                label: S.of(context).files,
                onPressed: () => AppNavigation.pushFileTransfer(
                  context,
                  sessionId: sessions.isNotEmpty ? sessions.first.id : null,
                ),
              ),
            ),
            AppSpacing.horizontalS,
            Expanded(
              child: _buildActionButton(
                icon: Icons.smart_toy_rounded,
                label: S.of(context).aiAssistant,
                onPressed: () => AppNavigation.pushAIAssistant(
                  context,
                  serverId: server.id,
                ),
              ),
            ),
            AppSpacing.horizontalS,
            Expanded(
              child: _buildActionButton(
                icon: Icons.dashboard_rounded,
                label: S.of(context).dashboard,
                onPressed: () => AppNavigation.pushDashboard(
                  context,
                  serverId: server.id,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(AppSpacing.radiusM),
      child: Container(
        padding: AppSpacing.paddingM,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusM),
          border: Border.all(color: AppColors.border(context)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppColors.primary,
              size: 24,
            ),
            AppSpacing.verticalXS,
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricsSection(ServerPreviewMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).systemMetrics,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.verticalM,
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.memory_rounded,
                label: S.of(context).cpu,
                value: '${metrics.cpuUsage.toStringAsFixed(1)}%',
                color: AppColors.chartBlue,
              ),
            ),
            AppSpacing.horizontalS,
            Expanded(
              child: _buildMetricCard(
                icon: Icons.storage_rounded,
                label: S.of(context).memory,
                value: '${metrics.memoryUsage.toStringAsFixed(1)}%',
                color: AppColors.chartGreen,
              ),
            ),
            AppSpacing.horizontalS,
            Expanded(
              child: _buildMetricCard(
                icon: Icons.trending_up_rounded,
                label: S.of(context).load,
                value: metrics.loadAverage.toStringAsFixed(2),
                color: AppColors.chartOrange,
              ),
            ),
            AppSpacing.horizontalS,
            Expanded(
              child: _buildMetricCard(
                icon: Icons.hard_drive_2_rounded,
                label: S.of(context).disk,
                value: '${metrics.diskUsage.toStringAsFixed(1)}%',
                color: AppColors.chartRed,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: AppSpacing.paddingM,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          AppSpacing.verticalXS,
          Text(
            value,
            style: AppTypography.h4.copyWith(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary(context),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActiveSessionsSection(List<SSHSession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              S.of(context).activeSessions,
              style: AppTypography.h4.copyWith(
                color: AppColors.textPrimary(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '${sessions.length}',
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ],
        ),
        AppSpacing.verticalM,
        if (sessions.isEmpty)
          Container(
            width: double.infinity,
            padding: AppSpacing.paddingL,
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(AppSpacing.radiusM),
              border: Border.all(color: AppColors.border(context)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: AppColors.textSecondary(context),
                ),
                AppSpacing.verticalS,
                Text(
                  S.of(context).noActiveSessions,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          )
        else
          ...sessions.map((session) => _buildSessionCard(session)),
      ],
    );
  }
  
  Widget _buildSessionCard(SSHSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s),
      padding: AppSpacing.paddingM,
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(AppSpacing.radiusM),
        border: Border.all(color: AppColors.border(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getConnectionStatusColor(session.status),
              shape: BoxShape.circle,
            ),
          ),
          AppSpacing.horizontalS,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.name ?? S.of(context).terminalSession,
                  style: AppTypography.body1.copyWith(
                    color: AppColors.textPrimary(context),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  DateTimeUtils.formatRelative(session.createdAt),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary(context),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.open_in_new_rounded,
              color: AppColors.textSecondary(context),
            ),
            onPressed: () => AppNavigation.pushTerminal(
              context,
              sessionId: session.id,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServerInfoSection(Server server) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).serverInformation,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.verticalM,
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingL,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              _buildInfoRow(S.of(context).name, server.name),
              _buildInfoRow(S.of(context).host, server.host),
              _buildInfoRow(S.of(context).port, server.port.toString()),
              _buildInfoRow(S.of(context).username, server.username),
              _buildInfoRow(S.of(context).authenticationType, _getAuthTypeText(server.authType)),
              if (server.description != null)
                _buildInfoRow(S.of(context).description, server.description!),
              _buildInfoRow(S.of(context).created, DateTimeUtils.formatDateTime(server.createdAt)),
              _buildInfoRow(S.of(context).lastUpdated, DateTimeUtils.formatDateTime(server.updatedAt)),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTypography.body2.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body2.copyWith(
                color: AppColors.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildConnectionHistorySection(Server server) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.of(context).connectionHistory,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        AppSpacing.verticalM,
        Container(
          width: double.infinity,
          padding: AppSpacing.paddingL,
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: BorderRadius.circular(AppSpacing.radiusM),
            border: Border.all(color: AppColors.border(context)),
          ),
          child: Column(
            children: [
              Icon(
                Icons.history_rounded,
                size: 48,
                color: AppColors.textSecondary(context),
              ),
              AppSpacing.verticalS,
              Text(
                S.of(context).connectionHistoryEmpty,
                style: AppTypography.body1.copyWith(
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Color _getStatusColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.connected:
        return AppColors.success;
      case ServerStatus.connecting:
        return AppColors.warning;
      case ServerStatus.disconnected:
        return AppColors.textSecondary(context);
      case ServerStatus.error:
        return AppColors.error;
    }
  }
  
  String _getStatusText(ServerStatus status) {
    switch (status) {
      case ServerStatus.connected:
        return S.of(context).connected;
      case ServerStatus.connecting:
        return S.of(context).connecting;
      case ServerStatus.disconnected:
        return S.of(context).disconnected;
      case ServerStatus.error:
        return S.of(context).connectionError;
    }
  }
  
  Color _getConnectionStatusColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.connected:
        return AppColors.success;
      case ConnectionStatus.connecting:
        return AppColors.warning;
      case ConnectionStatus.disconnected:
        return AppColors.textSecondary(context);
      case ConnectionStatus.error:
        return AppColors.error;
    }
  }
  
  Color _getConnectionButtonColor(ServerStatus status) {
    switch (status) {
      case ServerStatus.connected:
        return AppColors.error;
      case ServerStatus.connecting:
        return AppColors.warning;
      case ServerStatus.disconnected:
      case ServerStatus.error:
        return AppColors.primary;
    }
  }
  
  IconData _getConnectionButtonIcon(ServerStatus status) {
    switch (status) {
      case ServerStatus.connected:
        return Icons.power_off_rounded;
      case ServerStatus.connecting:
        return Icons.hourglass_empty_rounded;
      case ServerStatus.disconnected:
      case ServerStatus.error:
        return Icons.power_rounded;
    }
  }
  
  String _getConnectionButtonText(ServerStatus status) {
    switch (status) {
      case ServerStatus.connected:
        return S.of(context).disconnect;
      case ServerStatus.connecting:
        return S.of(context).connecting;
      case ServerStatus.disconnected:
      case ServerStatus.error:
        return S.of(context).connect;
    }
  }
  
  String _getAuthTypeText(AuthType authType) {
    switch (authType) {
      case AuthType.password:
        return S.of(context).password;
      case AuthType.privateKey:
        return S.of(context).privateKey;
    }
  }
  
  void _handleMenuAction(String action, Server server) {
    switch (action) {
      case 'edit':
        AppNavigation.pushServerEdit(context, server.id);
        break;
      case 'duplicate':
        _duplicateServer(server);
        break;
      case 'export':
        _exportServer(server);
        break;
      case 'delete':
        _showDeleteConfirmation(server);
        break;
    }
  }
  
  void _duplicateServer(Server server) {
    // TODO: Implement server duplication
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).featureNotImplemented),
        backgroundColor: AppColors.warning,
      ),
    );
  }
  
  void _exportServer(Server server) {
    // TODO: Implement server export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(S.of(context).featureNotImplemented),
        backgroundColor: AppColors.warning,
      ),
    );
  }
  
  void _showDeleteConfirmation(Server server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          S.of(context).deleteServer,
          style: AppTypography.h4.copyWith(
            color: AppColors.textPrimary(context),
          ),
        ),
        content: Text(
          S.of(context).deleteServerConfirmation,
          style: AppTypography.body1.copyWith(
            color: AppColors.textSecondary(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              S.of(context).cancel,
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary(context),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteServer(server);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              S.of(context).delete,
              style: AppTypography.button.copyWith(
                color: AppColors.onError,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _deleteServer(Server server) async {
    try {
      await ref.read(serversProvider.notifier).deleteServer(server.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).serverDeleted),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).deleteServerError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _connectToServer(Server server) async {
    setState(() {
      _isConnecting = true;
    });
    
    try {
      // TODO: Implement server connection logic
      await Future.delayed(const Duration(seconds: 2)); // Simulate connection
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).connectionSuccessful),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).connectionFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }
  
  Future<void> _refreshServerData() async {
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      // TODO: Implement server data refresh
      await Future.delayed(const Duration(seconds: 1)); // Simulate refresh
      
      // Refresh metrics
      ref.invalidate(serverMetricsProvider(widget.serverId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).dataRefreshed),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(S.of(context).refreshFailed),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }
}