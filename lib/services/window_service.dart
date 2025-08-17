import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/index.dart';
import 'storage_service.dart';

// Window Service Provider
final windowServiceProvider = Provider<WindowService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return WindowService(storageService);
});

class WindowService {
  final StorageService _storageService;
  final StreamController<WindowEvent> _eventController = StreamController<WindowEvent>.broadcast();
  final Map<String, WindowState> _windowCache = {};
  
  WindowService(this._storageService);

  /// Get window events stream
  Stream<WindowEvent> get events => _eventController.stream;

  /// Create a new window
  Future<WindowState> createWindow({
    required WindowType type,
    required String title,
    WindowPosition? position,
    WindowSize? size,
    String? serverId,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) async {
    final window = WindowState(
      id: _generateWindowId(),
      type: type,
      title: title,
      position: position ?? const WindowPosition(x: 100, y: 100),
      size: size ?? const WindowSize(width: 800, height: 600),
      isMaximized: false,
      isMinimized: false,
      isVisible: true,
      serverId: serverId,
      sessionId: sessionId,
      metadata: metadata ?? {},
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(window);
    _windowCache[window.id] = window;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.created,
      windowId: window.id,
      window: window,
      timestamp: DateTime.now(),
    ));
    
    return window;
  }

  /// Get window by ID
  Future<WindowState?> getWindow(String windowId) async {
    // Check cache first
    if (_windowCache.containsKey(windowId)) {
      return _windowCache[windowId];
    }
    
    try {
      final box = await _storageService.openBox<WindowState>('window_states');
      final window = box.get(windowId);
      
      if (window != null) {
        _windowCache[windowId] = window;
      }
      
      return window;
    } catch (e) {
      print('Failed to get window $windowId: $e');
      return null;
    }
  }

  /// Get all windows
  Future<List<WindowState>> getAllWindows() async {
    try {
      final box = await _storageService.openBox<WindowState>('window_states');
      final windows = box.values.toList();
      
      // Update cache
      _windowCache.clear();
      for (final window in windows) {
        _windowCache[window.id] = window;
      }
      
      return windows;
    } catch (e) {
      print('Failed to get all windows: $e');
      return [];
    }
  }

  /// Get windows by type
  Future<List<WindowState>> getWindowsByType(WindowType type) async {
    final allWindows = await getAllWindows();
    return allWindows.where((w) => w.type == type).toList();
  }

  /// Get windows by server
  Future<List<WindowState>> getWindowsByServer(String serverId) async {
    final allWindows = await getAllWindows();
    return allWindows.where((w) => w.serverId == serverId).toList();
  }

  /// Get visible windows
  Future<List<WindowState>> getVisibleWindows() async {
    final allWindows = await getAllWindows();
    return allWindows.where((w) => w.isVisible && !w.isMinimized).toList();
  }

  /// Get minimized windows
  Future<List<WindowState>> getMinimizedWindows() async {
    final allWindows = await getAllWindows();
    return allWindows.where((w) => w.isMinimized).toList();
  }

  /// Update window position
  Future<WindowState?> updateWindowPosition(String windowId, WindowPosition position) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      position: position,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.moved,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Update window size
  Future<WindowState?> updateWindowSize(String windowId, WindowSize size) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      size: size,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.resized,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Maximize window
  Future<WindowState?> maximizeWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      isMaximized: true,
      isMinimized: false,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.maximized,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Minimize window
  Future<WindowState?> minimizeWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      isMinimized: true,
      isMaximized: false,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.minimized,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Restore window
  Future<WindowState?> restoreWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      isMaximized: false,
      isMinimized: false,
      isVisible: true,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.restored,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Show window
  Future<WindowState?> showWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      isVisible: true,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.shown,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Hide window
  Future<WindowState?> hideWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      isVisible: false,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.hidden,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Focus window
  Future<WindowState?> focusWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.focused,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Update window title
  Future<WindowState?> updateWindowTitle(String windowId, String title) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      title: title,
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.titleChanged,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Update window metadata
  Future<WindowState?> updateWindowMetadata(String windowId, Map<String, dynamic> metadata) async {
    final window = await getWindow(windowId);
    if (window == null) return null;
    
    final updatedWindow = window.copyWith(
      metadata: {...window.metadata, ...metadata},
      lastActiveAt: DateTime.now(),
    );
    
    await _saveWindow(updatedWindow);
    _windowCache[windowId] = updatedWindow;
    
    _emitEvent(WindowEvent(
      type: WindowEventType.metadataChanged,
      windowId: windowId,
      window: updatedWindow,
      timestamp: DateTime.now(),
    ));
    
    return updatedWindow;
  }

  /// Close window
  Future<bool> closeWindow(String windowId) async {
    final window = await getWindow(windowId);
    if (window == null) return false;
    
    try {
      final box = await _storageService.openBox<WindowState>('window_states');
      await box.delete(windowId);
      _windowCache.remove(windowId);
      
      _emitEvent(WindowEvent(
        type: WindowEventType.closed,
        windowId: windowId,
        window: window,
        timestamp: DateTime.now(),
      ));
      
      return true;
    } catch (e) {
      print('Failed to close window $windowId: $e');
      return false;
    }
  }

  /// Close all windows
  Future<int> closeAllWindows() async {
    final windows = await getAllWindows();
    int closedCount = 0;
    
    for (final window in windows) {
      if (await closeWindow(window.id)) {
        closedCount++;
      }
    }
    
    return closedCount;
  }

  /// Close windows by type
  Future<int> closeWindowsByType(WindowType type) async {
    final windows = await getWindowsByType(type);
    int closedCount = 0;
    
    for (final window in windows) {
      if (await closeWindow(window.id)) {
        closedCount++;
      }
    }
    
    return closedCount;
  }

  /// Close windows by server
  Future<int> closeWindowsByServer(String serverId) async {
    final windows = await getWindowsByServer(serverId);
    int closedCount = 0;
    
    for (final window in windows) {
      if (await closeWindow(window.id)) {
        closedCount++;
      }
    }
    
    return closedCount;
  }

  /// Minimize all windows
  Future<int> minimizeAllWindows() async {
    final windows = await getVisibleWindows();
    int minimizedCount = 0;
    
    for (final window in windows) {
      if (await minimizeWindow(window.id) != null) {
        minimizedCount++;
      }
    }
    
    return minimizedCount;
  }

  /// Restore all minimized windows
  Future<int> restoreAllWindows() async {
    final windows = await getMinimizedWindows();
    int restoredCount = 0;
    
    for (final window in windows) {
      if (await restoreWindow(window.id) != null) {
        restoredCount++;
      }
    }
    
    return restoredCount;
  }

  /// Get window statistics
  Future<WindowStats> getWindowStats() async {
    final allWindows = await getAllWindows();
    
    return WindowStats(
      totalWindows: allWindows.length,
      visibleWindows: allWindows.where((w) => w.isVisible && !w.isMinimized).length,
      minimizedWindows: allWindows.where((w) => w.isMinimized).length,
      maximizedWindows: allWindows.where((w) => w.isMaximized).length,
      windowsByType: _groupWindowsByType(allWindows),
    );
  }

  /// Group windows by type
  Map<WindowType, int> _groupWindowsByType(List<WindowState> windows) {
    final grouped = <WindowType, int>{};
    
    for (final window in windows) {
      grouped[window.type] = (grouped[window.type] ?? 0) + 1;
    }
    
    return grouped;
  }

  /// Save window to storage
  Future<void> _saveWindow(WindowState window) async {
    try {
      final box = await _storageService.openBox<WindowState>('window_states');
      await box.put(window.id, window);
    } catch (e) {
      print('Failed to save window ${window.id}: $e');
      rethrow;
    }
  }

  /// Generate unique window ID
  String _generateWindowId() {
    return 'window_${DateTime.now().millisecondsSinceEpoch}_${_windowCache.length}';
  }

  /// Emit window event
  void _emitEvent(WindowEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  /// Clean up inactive windows
  Future<int> cleanupInactiveWindows({Duration inactiveThreshold = const Duration(days: 7)}) async {
    final allWindows = await getAllWindows();
    final cutoffTime = DateTime.now().subtract(inactiveThreshold);
    int cleanedCount = 0;
    
    for (final window in allWindows) {
      if (window.lastActiveAt.isBefore(cutoffTime)) {
        if (await closeWindow(window.id)) {
          cleanedCount++;
        }
      }
    }
    
    return cleanedCount;
  }

  /// Export window layout
  Future<Map<String, dynamic>> exportWindowLayout() async {
    final windows = await getAllWindows();
    
    return {
      'version': '1.0.0',
      'exported_at': DateTime.now().toIso8601String(),
      'windows': windows.map((w) => w.toJson()).toList(),
    };
  }

  /// Import window layout
  Future<bool> importWindowLayout(Map<String, dynamic> layout) async {
    try {
      if (!layout.containsKey('windows')) {
        return false;
      }
      
      final windowsList = layout['windows'] as List;
      final box = await _storageService.openBox<WindowState>('window_states');
      
      // Clear existing windows
      await box.clear();
      _windowCache.clear();
      
      // Import windows
      for (final windowData in windowsList) {
        final window = WindowState.fromJson(windowData);
        await box.put(window.id, window);
        _windowCache[window.id] = window;
      }
      
      return true;
    } catch (e) {
      print('Failed to import window layout: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _windowCache.clear();
  }
}

class WindowEvent {
  final WindowEventType type;
  final String windowId;
  final WindowState window;
  final DateTime timestamp;
  final Map<String, dynamic>? data;

  const WindowEvent({
    required this.type,
    required this.windowId,
    required this.window,
    required this.timestamp,
    this.data,
  });
}

enum WindowEventType {
  created,
  closed,
  moved,
  resized,
  maximized,
  minimized,
  restored,
  shown,
  hidden,
  focused,
  titleChanged,
  metadataChanged,
}

class WindowStats {
  final int totalWindows;
  final int visibleWindows;
  final int minimizedWindows;
  final int maximizedWindows;
  final Map<WindowType, int> windowsByType;

  const WindowStats({
    required this.totalWindows,
    required this.visibleWindows,
    required this.minimizedWindows,
    required this.maximizedWindows,
    required this.windowsByType,
  });
}