import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/widget_layout.dart';
import '../services/storage_service.dart';

// Widget Layout Provider
final widgetLayoutProvider = StateNotifierProvider<WidgetLayoutNotifier, List<WidgetLayout>>((ref) {
  return WidgetLayoutNotifier(ref.read(storageServiceProvider));
});

// Dashboard Layout Provider
final dashboardLayoutProvider = StateNotifierProvider<DashboardLayoutNotifier, DashboardLayoutState>((ref) {
  return DashboardLayoutNotifier(ref.read(storageServiceProvider));
});

class WidgetLayoutNotifier extends StateNotifier<List<WidgetLayout>> {
  final StorageService _storageService;
  static const String _boxName = 'widget_layouts';

  WidgetLayoutNotifier(this._storageService) : super([]) {
    _loadLayouts();
  }

  Future<void> _loadLayouts() async {
    try {
      final box = await _storageService.openBox<WidgetLayout>(_boxName);
      final layouts = box.values.toList();
      layouts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      state = layouts;
    } catch (e) {
      print('Failed to load widget layouts: $e');
      state = _getDefaultLayouts();
    }
  }

  Future<void> _saveLayout(WidgetLayout layout) async {
    try {
      final box = await _storageService.openBox<WidgetLayout>(_boxName);
      await box.put(layout.id, layout);
    } catch (e) {
      print('Failed to save widget layout: $e');
      throw Exception('Failed to save widget layout');
    }
  }

  Future<void> _deleteLayout(String id) async {
    try {
      final box = await _storageService.openBox<WidgetLayout>(_boxName);
      await box.delete(id);
    } catch (e) {
      print('Failed to delete widget layout: $e');
      throw Exception('Failed to delete widget layout');
    }
  }

  // CRUD operations
  Future<void> addWidget(WidgetLayout layout) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    currentLayouts.add(layout);
    state = currentLayouts;
    await _saveLayout(layout);
  }

  Future<void> updateWidget(WidgetLayout layout) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    final index = currentLayouts.indexWhere((w) => w.id == layout.id);
    
    if (index != -1) {
      final updatedLayout = layout.copyWith(updatedAt: DateTime.now());
      currentLayouts[index] = updatedLayout;
      state = currentLayouts;
      await _saveLayout(updatedLayout);
    }
  }

  Future<void> removeWidget(String id) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    currentLayouts.removeWhere((w) => w.id == id);
    state = currentLayouts;
    await _deleteLayout(id);
  }

  // Position and size updates
  Future<void> updateWidgetPosition(String id, WidgetPosition position) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    final index = currentLayouts.indexWhere((w) => w.id == id);
    
    if (index != -1) {
      final updatedLayout = currentLayouts[index].copyWith(
        position: position,
        updatedAt: DateTime.now(),
      );
      currentLayouts[index] = updatedLayout;
      state = currentLayouts;
      await _saveLayout(updatedLayout);
    }
  }

  Future<void> updateWidgetSize(String id, WidgetSize size) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    final index = currentLayouts.indexWhere((w) => w.id == id);
    
    if (index != -1) {
      final updatedLayout = currentLayouts[index].copyWith(
        size: size,
        updatedAt: DateTime.now(),
      );
      currentLayouts[index] = updatedLayout;
      state = currentLayouts;
      await _saveLayout(updatedLayout);
    }
  }

  Future<void> updateWidgetVisibility(String id, bool isVisible) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    final index = currentLayouts.indexWhere((w) => w.id == id);
    
    if (index != -1) {
      final updatedLayout = currentLayouts[index].copyWith(
        isVisible: isVisible,
        updatedAt: DateTime.now(),
      );
      currentLayouts[index] = updatedLayout;
      state = currentLayouts;
      await _saveLayout(updatedLayout);
    }
  }

  // Batch operations
  Future<void> updateMultipleWidgets(List<WidgetLayout> layouts) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    
    for (final layout in layouts) {
      final index = currentLayouts.indexWhere((w) => w.id == layout.id);
      if (index != -1) {
        final updatedLayout = layout.copyWith(updatedAt: DateTime.now());
        currentLayouts[index] = updatedLayout;
        await _saveLayout(updatedLayout);
      }
    }
    
    state = currentLayouts;
  }

  Future<void> reorderWidgets(List<String> orderedIds) async {
    final currentLayouts = List<WidgetLayout>.from(state);
    final reorderedLayouts = <WidgetLayout>[];
    
    // Add widgets in the specified order
    for (final id in orderedIds) {
      final widget = currentLayouts.firstWhere((w) => w.id == id);
      reorderedLayouts.add(widget);
    }
    
    // Add any remaining widgets that weren't in the ordered list
    for (final widget in currentLayouts) {
      if (!orderedIds.contains(widget.id)) {
        reorderedLaygets.add(widget);
      }
    }
    
    state = reorderedLayouts;
    
    // Save all layouts with updated timestamps
    for (final layout in reorderedLayouts) {
      await _saveLayout(layout.copyWith(updatedAt: DateTime.now()));
    }
  }

  // Filter and query operations
  List<WidgetLayout> getWidgetsByType(WidgetType type) {
    return state.where((w) => w.type == type).toList();
  }

  List<WidgetLayout> getWidgetsByServer(String serverId) {
    return state.where((w) => w.serverId == serverId).toList();
  }

  List<WidgetLayout> getVisibleWidgets() {
    return state.where((w) => w.isVisible).toList();
  }

  WidgetLayout? getWidgetById(String id) {
    try {
      return state.firstWhere((w) => w.id == id);
    } catch (e) {
      return null;
    }
  }

  // Reset and defaults
  Future<void> resetToDefaults() async {
    try {
      final box = await _storageService.openBox<WidgetLayout>(_boxName);
      await box.clear();
      
      final defaultLayouts = _getDefaultLayouts();
      for (final layout in defaultLayouts) {
        await _saveLayout(layout);
      }
      
      state = defaultLayouts;
    } catch (e) {
      print('Failed to reset widget layouts: $e');
      throw Exception('Failed to reset widget layouts');
    }
  }

  List<WidgetLayout> _getDefaultLayouts() {
    return [
      WidgetLayout(
        id: 'server_overview',
        type: WidgetType.serverOverview,
        title: 'Server Overview',
        position: const WidgetPosition(x: 0, y: 0),
        size: const WidgetSize(width: 2, height: 1),
        isVisible: true,
        config: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WidgetLayout(
        id: 'cpu_monitor',
        type: WidgetType.cpuMonitor,
        title: 'CPU Monitor',
        position: const WidgetPosition(x: 2, y: 0),
        size: const WidgetSize(width: 1, height: 1),
        isVisible: true,
        config: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      WidgetLayout(
        id: 'memory_monitor',
        type: WidgetType.memoryMonitor,
        title: 'Memory Monitor',
        position: const WidgetPosition(x: 3, y: 0),
        size: const WidgetSize(width: 1, height: 1),
        isVisible: true,
        config: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

class DashboardLayoutNotifier extends StateNotifier<DashboardLayoutState> {
  final StorageService _storageService;
  static const String _boxName = 'dashboard_layout';
  static const String _stateKey = 'layout_state';

  DashboardLayoutNotifier(this._storageService) : super(const DashboardLayoutState()) {
    _loadLayoutState();
  }

  Future<void> _loadLayoutState() async {
    try {
      final box = await _storageService.openBox<DashboardLayoutState>(_boxName);
      final layoutState = box.get(_stateKey);
      if (layoutState != null) {
        state = layoutState;
      }
    } catch (e) {
      print('Failed to load dashboard layout state: $e');
      state = const DashboardLayoutState();
    }
  }

  Future<void> _saveLayoutState() async {
    try {
      final box = await _storageService.openBox<DashboardLayoutState>(_boxName);
      await box.put(_stateKey, state);
    } catch (e) {
      print('Failed to save dashboard layout state: $e');
    }
  }

  Future<void> updateGridColumns(int columns) async {
    state = state.copyWith(gridColumns: columns);
    await _saveLayoutState();
  }

  Future<void> updateGridSpacing(double spacing) async {
    state = state.copyWith(gridSpacing: spacing);
    await _saveLayoutState();
  }

  Future<void> updateEditMode(bool isEditing) async {
    state = state.copyWith(isEditMode: isEditing);
    await _saveLayoutState();
  }

  Future<void> updateShowGrid(bool showGrid) async {
    state = state.copyWith(showGrid: showGrid);
    await _saveLayoutState();
  }

  Future<void> updateSnapToGrid(bool snapToGrid) async {
    state = state.copyWith(snapToGrid: snapToGrid);
    await _saveLayoutState();
  }
}

class DashboardLayoutState {
  final int gridColumns;
  final double gridSpacing;
  final bool isEditMode;
  final bool showGrid;
  final bool snapToGrid;

  const DashboardLayoutState({
    this.gridColumns = 4,
    this.gridSpacing = 16.0,
    this.isEditMode = false,
    this.showGrid = false,
    this.snapToGrid = true,
  });

  DashboardLayoutState copyWith({
    int? gridColumns,
    double? gridSpacing,
    bool? isEditMode,
    bool? showGrid,
    bool? snapToGrid,
  }) {
    return DashboardLayoutState(
      gridColumns: gridColumns ?? this.gridColumns,
      gridSpacing: gridSpacing ?? this.gridSpacing,
      isEditMode: isEditMode ?? this.isEditMode,
      showGrid: showGrid ?? this.showGrid,
      snapToGrid: snapToGrid ?? this.snapToGrid,
    );
  }
}

// Convenience providers
final visibleWidgetsProvider = Provider<List<WidgetLayout>>((ref) {
  return ref.watch(widgetLayoutProvider).where((w) => w.isVisible).toList();
});

final widgetsByTypeProvider = Provider.family<List<WidgetLayout>, WidgetType>((ref, type) {
  return ref.watch(widgetLayoutProvider).where((w) => w.type == type).toList();
});

final widgetsByServerProvider = Provider.family<List<WidgetLayout>, String>((ref, serverId) {
  return ref.watch(widgetLayoutProvider).where((w) => w.serverId == serverId).toList();
});

final dashboardEditModeProvider = Provider<bool>((ref) {
  return ref.watch(dashboardLayoutProvider).isEditMode;
});

final dashboardGridColumnsProvider = Provider<int>((ref) {
  return ref.watch(dashboardLayoutProvider).gridColumns;
});