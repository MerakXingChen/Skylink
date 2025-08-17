import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';
import '../providers/index.dart';
import '../models/index.dart';
import '../theme/index.dart';
import '../widgets/app_bar_custom.dart';
import '../widgets/file_browser_widget.dart';
import '../widgets/file_transfer_queue_widget.dart';
import '../widgets/file_transfer_progress_widget.dart';
import '../widgets/file_operations_panel.dart';

/// File Transfer Screen - SFTP file management and transfer
class FileTransferScreen extends ConsumerStatefulWidget {
  final String? sessionId;
  final String? initialRemotePath;
  final String? initialLocalPath;
  
  const FileTransferScreen({
    super.key,
    this.sessionId,
    this.initialRemotePath,
    this.initialLocalPath,
  });

  @override
  ConsumerState<FileTransferScreen> createState() => _FileTransferScreenState;
}

class _FileTransferScreenState extends ConsumerState<FileTransferScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoading = false;
  bool _showTransferQueue = false;
  bool _showOperationsPanel = false;
  String _currentRemotePath = '/';
  String _currentLocalPath = '';
  List<FileItem> _selectedRemoteFiles = [];
  List<FileItem> _selectedLocalFiles = [];
  FileTransferMode _transferMode = FileTransferMode.upload;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentRemotePath = widget.initialRemotePath ?? '/';
    _currentLocalPath = widget.initialLocalPath ?? _getDefaultLocalPath();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFileTransfer();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  String _getDefaultLocalPath() {
    if (Platform.isWindows) {
      return 'C:\\Users\\${Platform.environment['USERNAME'] ?? 'User'}\\Documents';
    } else {
      return Platform.environment['HOME'] ?? '/home';
    }
  }
  
  Future<void> _initializeFileTransfer() async {
    if (widget.sessionId == null) {
      _showErrorSnackBar(AppLocalizations.of(context)!.noActiveSession);
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      // Initialize SFTP connection
      final sftpResult = await ref.read(sshServiceProvider).createSftp(widget.sessionId!);
      if (!sftpResult.success) {
        _showErrorSnackBar(sftpResult.error ?? AppLocalizations.of(context)!.sftpConnectionFailed);
        return;
      }
      
      // Load initial directories
      await _loadRemoteDirectory(_currentRemotePath);
      await _loadLocalDirectory(_currentLocalPath);
      
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
  
  Future<void> _loadRemoteDirectory(String path) async {
    try {
      final result = await ref.read(sshServiceProvider).listRemoteFiles(
        widget.sessionId!,
        path,
      );
      
      if (result.success) {
        setState(() => _currentRemotePath = path);
      } else {
        _showErrorSnackBar(result.error ?? AppLocalizations.of(context)!.directoryLoadFailed);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    }
  }
  
  Future<void> _loadLocalDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        setState(() => _currentLocalPath = path);
      } else {
        _showErrorSnackBar(AppLocalizations.of(context)!.directoryNotFound);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
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
    final session = widget.sessionId != null
        ? ref.watch(sshSessionByIdProvider(widget.sessionId!))
        : null;
    final transferQueue = ref.watch(fileTransferQueueProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBarCustom(
        title: l10n.fileTransfer,
        subtitle: session != null ? '${session.username}@${session.host}' : null,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Transfer mode toggle
          SegmentedButton<FileTransferMode>(
            segments: [
              ButtonSegment(
                value: FileTransferMode.upload,
                icon: const Icon(Icons.upload_rounded, size: 16),
                label: Text(l10n.upload),
              ),
              ButtonSegment(
                value: FileTransferMode.download,
                icon: const Icon(Icons.download_rounded, size: 16),
                label: Text(l10n.download),
              ),
            ],
            selected: {_transferMode},
            onSelectionChanged: (Set<FileTransferMode> selection) {
              setState(() => _transferMode = selection.first);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surface,
              foregroundColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              selectedBackgroundColor: isDark ? AppColors.primaryDark : AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          
          // Transfer queue toggle
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  _showTransferQueue ? Icons.queue_rounded : Icons.queue_outlined,
                  color: _showTransferQueue
                      ? (isDark ? AppColors.primaryDark : AppColors.primary)
                      : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                ),
                if (transferQueue.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        transferQueue.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () {
              setState(() => _showTransferQueue = !_showTransferQueue);
            },
            tooltip: l10n.transferQueue,
          ),
          
          // Operations panel toggle
          IconButton(
            icon: Icon(
              _showOperationsPanel ? Icons.build_rounded : Icons.build_outlined,
              color: _showOperationsPanel
                  ? (isDark ? AppColors.primaryDark : AppColors.primary)
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            ),
            onPressed: () {
              setState(() => _showOperationsPanel = !_showOperationsPanel);
            },
            tooltip: l10n.fileOperations,
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
                value: 'sync_folders',
                child: Row(
                  children: [
                    const Icon(Icons.sync_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.syncFolders),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'new_folder',
                child: Row(
                  children: [
                    const Icon(Icons.create_new_folder_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.newFolder),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'upload_files',
                child: Row(
                  children: [
                    const Icon(Icons.upload_file_rounded),
                    const SizedBox(width: AppSpacing.sm),
                    Text(l10n.uploadFiles),
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
                    l10n.initializingFileTransfer,
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
                        l10n.noActiveSession,
                        style: AppTypography.headlineSmall.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        l10n.connectToServerFirst,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                        child: Text(l10n.goToServers),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // File browsers
                    Expanded(
                      child: Row(
                        children: [
                          // Local and remote file browsers
                          Expanded(
                            flex: _showTransferQueue || _showOperationsPanel ? 2 : 3,
                            child: Column(
                              children: [
                                // Tab bar
                                Container(
                                  color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                  child: TabBar(
                                    controller: _tabController,
                                    tabs: [
                                      Tab(
                                        icon: const Icon(Icons.computer_rounded, size: 20),
                                        text: l10n.localFiles,
                                      ),
                                      Tab(
                                        icon: const Icon(Icons.cloud_rounded, size: 20),
                                        text: l10n.remoteFiles,
                                      ),
                                    ],
                                    labelColor: isDark ? AppColors.primaryDark : AppColors.primary,
                                    unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                    indicatorColor: isDark ? AppColors.primaryDark : AppColors.primary,
                                  ),
                                ),
                                
                                // File browser content
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Local file browser
                                      FileBrowserWidget(
                                        isLocal: true,
                                        currentPath: _currentLocalPath,
                                        selectedFiles: _selectedLocalFiles,
                                        onPathChanged: _loadLocalDirectory,
                                        onSelectionChanged: (files) {
                                          setState(() => _selectedLocalFiles = files);
                                        },
                                        onFileDoubleClick: _handleLocalFileDoubleClick,
                                        onContextMenu: _showLocalContextMenu,
                                      ),
                                      
                                      // Remote file browser
                                      FileBrowserWidget(
                                        isLocal: false,
                                        sessionId: widget.sessionId,
                                        currentPath: _currentRemotePath,
                                        selectedFiles: _selectedRemoteFiles,
                                        onPathChanged: _loadRemoteDirectory,
                                        onSelectionChanged: (files) {
                                          setState(() => _selectedRemoteFiles = files);
                                        },
                                        onFileDoubleClick: _handleRemoteFileDoubleClick,
                                        onContextMenu: _showRemoteContextMenu,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Transfer queue panel
                          if (_showTransferQueue)
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
                              child: FileTransferQueueWidget(
                                onClose: () => setState(() => _showTransferQueue = false),
                                onClearCompleted: _clearCompletedTransfers,
                                onCancelTransfer: _cancelTransfer,
                                onRetryTransfer: _retryTransfer,
                              ),
                            ),
                          
                          // Operations panel
                          if (_showOperationsPanel)
                            Container(
                              width: 300,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.surfaceDark : AppColors.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: isDark ? AppColors.borderDark : AppColors.border,
                                  ),
                                ),
                              ),
                              child: FileOperationsPanel(
                                selectedLocalFiles: _selectedLocalFiles,
                                selectedRemoteFiles: _selectedRemoteFiles,
                                transferMode: _transferMode,
                                onClose: () => setState(() => _showOperationsPanel = false),
                                onTransfer: _startTransfer,
                                onDelete: _deleteFiles,
                                onRename: _renameFile,
                                onCreateFolder: _createFolder,
                                onChangePermissions: _changePermissions,
                              ),
                            ),
                        ],
                      ),
                    ),
                    
                    // Transfer progress bar
                    FileTransferProgressWidget(
                      onCancel: _cancelCurrentTransfer,
                      onPause: _pauseCurrentTransfer,
                      onResume: _resumeCurrentTransfer,
                    ),
                  ],
                ),
    );
  }
  
  void _handleMenuAction(String action) async {
    final l10n = AppLocalizations.of(context)!;
    
    switch (action) {
      case 'refresh':
        await _refreshCurrentView();
        break;
      case 'sync_folders':
        await _syncFolders();
        break;
      case 'new_folder':
        await _showCreateFolderDialog();
        break;
      case 'upload_files':
        await _selectAndUploadFiles();
        break;
      case 'settings':
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }
  
  Future<void> _refreshCurrentView() async {
    final currentTab = _tabController.index;
    if (currentTab == 0) {
      await _loadLocalDirectory(_currentLocalPath);
    } else {
      await _loadRemoteDirectory(_currentRemotePath);
    }
    _showSuccessSnackBar(AppLocalizations.of(context)!.refreshed);
  }
  
  Future<void> _syncFolders() async {
    // TODO: Implement folder synchronization
    _showSuccessSnackBar(AppLocalizations.of(context)!.syncStarted);
  }
  
  Future<void> _showCreateFolderDialog() async {
    // TODO: Implement create folder dialog
    _showSuccessSnackBar(AppLocalizations.of(context)!.folderCreated);
  }
  
  Future<void> _selectAndUploadFiles() async {
    // TODO: Implement file picker and upload
    _showSuccessSnackBar(AppLocalizations.of(context)!.uploadStarted);
  }
  
  void _handleLocalFileDoubleClick(FileItem file) {
    if (file.isDirectory) {
      _loadLocalDirectory(file.path);
    } else {
      // TODO: Open file with default application
    }
  }
  
  void _handleRemoteFileDoubleClick(FileItem file) {
    if (file.isDirectory) {
      _loadRemoteDirectory(file.path);
    } else {
      // TODO: Download and open file
    }
  }
  
  void _showLocalContextMenu(FileItem file, Offset position) {
    // TODO: Implement local file context menu
  }
  
  void _showRemoteContextMenu(FileItem file, Offset position) {
    // TODO: Implement remote file context menu
  }
  
  Future<void> _startTransfer() async {
    // TODO: Implement file transfer
    _showSuccessSnackBar(AppLocalizations.of(context)!.transferStarted);
  }
  
  Future<void> _deleteFiles(List<FileItem> files) async {
    // TODO: Implement file deletion
    _showSuccessSnackBar(AppLocalizations.of(context)!.filesDeleted);
  }
  
  Future<void> _renameFile(FileItem file, String newName) async {
    // TODO: Implement file rename
    _showSuccessSnackBar(AppLocalizations.of(context)!.fileRenamed);
  }
  
  Future<void> _createFolder(String name) async {
    // TODO: Implement folder creation
    _showSuccessSnackBar(AppLocalizations.of(context)!.folderCreated);
  }
  
  Future<void> _changePermissions(FileItem file, String permissions) async {
    // TODO: Implement permission change
    _showSuccessSnackBar(AppLocalizations.of(context)!.permissionsChanged);
  }
  
  void _clearCompletedTransfers() {
    ref.read(fileTransferQueueProvider.notifier).clearCompleted();
    _showSuccessSnackBar(AppLocalizations.of(context)!.completedTransfersCleared);
  }
  
  void _cancelTransfer(String transferId) {
    ref.read(fileTransferQueueProvider.notifier).cancelTransfer(transferId);
    _showSuccessSnackBar(AppLocalizations.of(context)!.transferCancelled);
  }
  
  void _retryTransfer(String transferId) {
    ref.read(fileTransferQueueProvider.notifier).retryTransfer(transferId);
    _showSuccessSnackBar(AppLocalizations.of(context)!.transferRetried);
  }
  
  void _cancelCurrentTransfer() {
    // TODO: Cancel current transfer
    _showSuccessSnackBar(AppLocalizations.of(context)!.transferCancelled);
  }
  
  void _pauseCurrentTransfer() {
    // TODO: Pause current transfer
    _showSuccessSnackBar(AppLocalizations.of(context)!.transferPaused);
  }
  
  void _resumeCurrentTransfer() {
    // TODO: Resume current transfer
    _showSuccessSnackBar(AppLocalizations.of(context)!.transferResumed);
  }
}

/// File Transfer Mode enumeration
enum FileTransferMode {
  upload,
  download,
}