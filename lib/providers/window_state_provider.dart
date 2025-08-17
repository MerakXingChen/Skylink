import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/window_state.dart';
import '../services/storage_service.dart';
import '../services/window_service.dart';

// Window State Provider
final windowStateProvider = StateNotifierProvider<WindowStateNotifier, List<WindowState>>((ref) {
  return WindowStateNotifier(
    ref.read(storageServiceProvider),
    ref.read(windowServiceProvider),
  );
});

// Active Window Provider
final activeWindowProvider = StateNotifierProvider<ActiveWindowNotifier, WindowState?>((ref) {
  return ActiveWindowNotifier(
    ref.read(storageServiceProvider),
    ref.read(windowServiceProvider),
  );
});

class WindowStateNotifier extends StateNotifier<List<WindowState>> {
  final StorageService _storageService;
  final WindowService _windowService;
  static const String _boxName = 'window_states';

  WindowStateNotifier(this._storageService, this._windowService) : super([]) {
    _loadWindowStates();
    _initializeWindowListener();
  }

  Future<void> _loadWindowStates() async {
    try {
      final box = await _storageService.openBox<WindowState>(_boxName);
      final windows = box.values.toList();
      windows.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
      state = windows;
    } catch (e) {
      print('Failed to load window states: $e');
      state = [];
    }
  }

  void _initializeWindowListener() {
    // Listen to window service events
    _windowService.windowEventsStream.listen((event) {
      _handleWindowEvent(event);
    });
  }

  void _handleWindowEvent(WindowEvent event) {
    switch (event.type) {
      case WindowEventType.created:
        _addWindow(event.windowState);
        break;
      case WindowEventType.updated:
        _updateWindow(event.windowState);
        break;
      case WindowEventType.closed:
        _removeWindow(event.windowState.id);
        break;
      case WindowEventType.focused:
        _updateLastActive(event.windowState.id);
        break;
      case WindowEventType.minimized:
        _updateMinimized(event.windowState.id, true);
        break;
      case WindowEventType.restored:
        _updateMinimized(event.windowState.id, false);
        break;
      case WindowEventType.maximized:
        _updateMaximized(event.windowState.id, true);
        break;
      case WindowEventType.unmaximized:
        _updateMaximized(event.windowState.id, false);
        break;
    }
  }

  Future<void> _saveWindow(WindowState window) async {
    try {
      final box = await _storageService.openBox<WindowState>(_boxName);
      await box.put(window.id, window);
    } catch (e) {
      print('Failed to save window state: $e');
    }
  }

  Future<void> _deleteWindow(String id) async {
    try {
      final box = await _storageService.openBox<WindowState>(_boxName);
      await box.delete(id);
    } catch (e) {
      print('Failed to delete window state: $e');
    }
  }

  // Window management operations
  Future<void> createWindow(WindowState window) async {
    await _windowService.createWindow(window);
    // Window will be added via event listener
  }

  void _addWindow(WindowState window) {
    final currentWindows = List<WindowState>.from(state);
    currentWindows.insert(0, window); // Add to front (most recent)
    state = currentWindows;
    _saveWindow(window);
  }

  Future<void> updateWindow(WindowState window) async {
    await _windowService.updateWindow(window);
    // Window will be updated via event listener
  }

  void _updateWindow(WindowState window) {
    final currentWindows = List<WindowState>.from(state);
    final index = currentWindows.indexWhere((w) => w.id == window.id);
    
    if (index != -1) {
      currentWindows[index] = window;
      state = currentWindows;
      _saveWindow(window);
    }
  }

  Future<void> closeWindow(String id) async {
    await _windowService.closeWindow(id);
    // Window will be removed via event listener
  }

  void _removeWindow(String id) {
    final currentWindows = List<WindowState>.from(state);
    currentWindows.removeWhere((w) => w.id == id);
    state = currentWindows;
    _deleteWindow(id);
  }

  // Window state updates
  Future<void> updateWindowPosition(String id, WindowPosition position) async {
    final window = _getWindowById(id);
    if (window != null) {
      final updatedWindow = window.copyWith(position: position);
      await updateWindow(updatedWindow);
    }
  }

  Future<void> updateWindowSize(String id, WindowSize size) async {
    final window = _getWindowById(id);
    if (window != null) {
      final updatedWindow = window.copyWith(size: size);
      await updateWindow(updatedWindow);
    }
  }

  Future<void> updateWindowVisibility(String id, bool isVisible) async {
    final window = _getWindowById(id);
    if (window != null) {
      final updatedWindow = window.copyWith(isVisible: isVisible);
      await updateWindow(updatedWindow);
    }
  }

  void _updateLastActive(String id) {
    final currentWindows = List<WindowState>.from(state);
    final index = currentWindows.indexWhere((w) => w.id == id);
    
    if (index != -1) {
      final updatedWindow = currentWindows[index].copyWith(
        lastActiveAt: DateTime.now(),
      );
      
      // Move to front and update
      currentWindows.removeAt(index);
      currentWindows.insert(0, updatedWindow);
      state = currentWindows;
      _saveWindow(updatedWindow);
    }
  }

  void _updateMinimized(String id, bool isMinimized) {
    final currentWindows = List<WindowState>.from(state);
    final index = currentWindows.indexWhere((w) => w.id == id);
    
    if (index != -1) {
      final updatedWindow = currentWindows[index].copyWith(
        isMinimized: isMinimized,
        lastActiveAt: DateTime.now(),
      );
      currentWindows[index] = updatedWindow;
      state = currentWindows;
      _saveWindow(updatedWindow);
    }
  }

  void _updateMaximized(String id, bool isMaximized) {
    final currentWindows = List<WindowState>.from(state);
    final index = currentWindows.indexWhere((w) => w.id == id);
    
    if (index != -1) {
      final updatedWindow = currentWindows[index].copyWith(
        isMaximized: isMaximized,
        lastActiveAt: DateTime.now(),
      );
      currentWindows[index] = updatedWindow;
      state = currentWindows;
      _saveWindow(updatedWindow);
    }
  }

  // Query operations
  WindowState? _getWindowById(String id) {
    try {
      return state.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  List<WindowState> getWindowsByType(WindowType type) {
    return state.where((w) => w.type == type).toList();
  }

  List<WindowState> getWindowsByServer(String serverId) {
    return state.where((w) => w.serverId == serverId).toList();
  }

  List<WindowState> getVisibleWindows() {
    return state.where((w) => w.isVisible && !w.isMinimized).toList();
  }

  List<WindowState> getMinimizedWindows() {
    return state.where((w) => w.isMinimized).toList();
  }

  // Batch operations
  Future<void> closeAllWindows() async {
    for (final window in state) {
      await _windowService.closeWindow(window.id);
    }
  }

  Future<void> closeWindowsByServer(String serverId) async {
    final serverWindows = getWindowsByServer(serverId);
    for (final window in serverWindows) {
      await _windowService.closeWindow(window.id);
    }
  }

  Future<void> minimizeAllWindows() async {
    for (final window in state) {
      if (!window.isMinimized) {
        await _windowService.minimizeWindow(window.id);
      }
    }
  }

  Future<void> restoreAllWindows() async {
    for (final window in state) {
      if (window.isMinimized) {
        await _windowService.restoreWindow(window.id);
      }
    }
  }

  // Cleanup
  Future<void> clearClosedWindows() async {
    try {
      final box = await _storageService.openBox<WindowState>(_boxName);
      await box.clear();
      state = [];
    } catch (e) {
      print('Failed to clear window states: $e');
    }
  }
}

class ActiveWindowNotifier extends StateNotifier<WindowState?> {
  final StorageService _storageService;
  final WindowService _windowService;
  static const String _boxName = 'active_window';
  static const String _activeKey = 'current';

  ActiveWindowNotifier(this._storageService, this._windowService) : super(null) {
    _loadActiveWindow();
    _initializeActiveWindowListener();
  }

  Future<void> _loadActiveWindow() async {
    try {
      final box = await _storageService.openBox<WindowState>(_boxName);
      final activeWindow = box.get(_activeKey);
      state = activeWindow;
    } catch (e) {
      print('Failed to load active window: $e');
    }
  }

  void _initializeActiveWindowListener() {
    _windowService.activeWindowStream.listen((window) {
      state = window;
      _saveActiveWindow(window);
    });
  }

  Future<void> _saveActiveWindow(WindowState? window) async {
    try {
      final box = await _storageService.openBox<WindowState>(_boxName);
      if (window != null) {
        await box.put(_activeKey, window);
      } else {
        await box.delete(_activeKey);
      }
    } catch (e) {
      print('Failed to save active window: $e');
    }
  }

  Future<void> setActiveWindow(String windowId) async {
    await _windowService.focusWindow(windowId);
  }

  void clearActiveWindow() {
    state = null;
    _saveActiveWindow(null);
  }
}

// Window Event Classes
class WindowEvent {
  final WindowEventType type;
  final WindowState windowState;

  const WindowEvent({
    required this.type,
    required this.windowState,
  });
}

enum WindowEventType {
  created,
  updated,
  closed,
  focused,
  minimized,
  restored,
  maximized,
  unmaximized,
}

// Convenience providers
final windowCountProvider = Provider<int>((ref) {
  return ref.watch(windowStateProvider).length;
});

final visibleWindowCountProvider = Provider<int>((ref) {
  return ref.watch(windowStateProvider)
      .where((w) => w.isVisible && !w.isMinimized)
      .length;
});

final minimizedWindowCountProvider = Provider<int>((ref) {
  return ref.watch(windowStateProvider)
      .where((w) => w.isMinimized)
      .length;
});

final windowsByTypeProvider = Provider.family<List<WindowState>, WindowType>((ref, type) {
  return ref.watch(windowStateProvider)
      .where((w) => w.type == type)
      .toList();
});

final windowsByServerProvider = Provider.family<List<WindowState>, String>((ref, serverId) {
  return ref.watch(windowStateProvider)
      .where((w) => w.serverId == serverId)
      .toList();
});

final hasActiveWindowProvider = Provider<bool>((ref) {
  return ref.watch(activeWindowProvider) != null;
});

final activeWindowTypeProvider = Provider<WindowType?>((ref) {
  return ref.watch(activeWindowProvider)?.type;
});