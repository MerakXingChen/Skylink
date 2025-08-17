import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/index.dart';
import '../models/index.dart';
import '../providers/index.dart';

/// Application routes configuration
class AppRoutes {
  // Route paths
  static const String home = '/';
  static const String serverPreview = '/servers';
  static const String connectionManager = '/connections';
  static const String terminal = '/terminal';
  static const String fileTransfer = '/files';
  static const String aiAssistant = '/ai';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String serverAdd = '/servers/add';
  static const String serverEdit = '/servers/edit';
  static const String serverDetails = '/servers/details';
  
  // Route names for navigation
  static const String homeRoute = 'home';
  static const String serverPreviewRoute = 'serverPreview';
  static const String connectionManagerRoute = 'connectionManager';
  static const String terminalRoute = 'terminal';
  static const String fileTransferRoute = 'fileTransfer';
  static const String aiAssistantRoute = 'aiAssistant';
  static const String dashboardRoute = 'dashboard';
  static const String settingsRoute = 'settings';
  static const String serverAddRoute = 'serverAdd';
  static const String serverEditRoute = 'serverEdit';
  static const String serverDetailsRoute = 'serverDetails';
}

/// Router configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: true,
    routes: [
      // Home/Server Preview (Main screen)
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.homeRoute,
        builder: (context, state) => const ServerPreviewScreen(),
      ),
      
      // Server Preview (Alternative path)
      GoRoute(
        path: AppRoutes.serverPreview,
        name: AppRoutes.serverPreviewRoute,
        builder: (context, state) => const ServerPreviewScreen(),
      ),
      
      // Connection Manager
      GoRoute(
        path: AppRoutes.connectionManager,
        name: AppRoutes.connectionManagerRoute,
        builder: (context, state) => const ConnectionManagerScreen(),
      ),
      
      // Terminal
      GoRoute(
        path: AppRoutes.terminal,
        name: AppRoutes.terminalRoute,
        builder: (context, state) {
          final serverId = state.uri.queryParameters['serverId'];
          final sessionId = state.uri.queryParameters['sessionId'];
          return TerminalScreen(
            serverId: serverId,
            sessionId: sessionId,
          );
        },
      ),
      
      // File Transfer
      GoRoute(
        path: AppRoutes.fileTransfer,
        name: AppRoutes.fileTransferRoute,
        builder: (context, state) {
          final sessionId = state.uri.queryParameters['sessionId'];
          final remotePath = state.uri.queryParameters['remotePath'];
          final localPath = state.uri.queryParameters['localPath'];
          return FileTransferScreen(
            sessionId: sessionId,
            initialRemotePath: remotePath,
            initialLocalPath: localPath,
          );
        },
      ),
      
      // AI Assistant
      GoRoute(
        path: AppRoutes.aiAssistant,
        name: AppRoutes.aiAssistantRoute,
        builder: (context, state) {
          final serverId = state.uri.queryParameters['serverId'];
          final sessionId = state.uri.queryParameters['sessionId'];
          final mode = state.uri.queryParameters['mode'];
          return AIAssistantScreen(
            serverId: serverId,
            sessionId: sessionId,
            initialMode: mode != null ? AIMode.values.firstWhere(
              (m) => m.name == mode,
              orElse: () => AIMode.chat,
            ) : AIMode.chat,
          );
        },
      ),
      
      // Widget Dashboard
      GoRoute(
        path: AppRoutes.dashboard,
        name: AppRoutes.dashboardRoute,
        builder: (context, state) {
          final serverId = state.uri.queryParameters['serverId'];
          final editMode = state.uri.queryParameters['edit'] == 'true';
          return WidgetDashboardScreen(
            serverId: serverId,
            isEditMode: editMode,
          );
        },
      ),
      
      // Settings
      GoRoute(
        path: AppRoutes.settings,
        name: AppRoutes.settingsRoute,
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Server Management Routes
      GoRoute(
        path: AppRoutes.serverAdd,
        name: AppRoutes.serverAddRoute,
        builder: (context, state) => const ServerEditScreen(),
      ),
      
      GoRoute(
        path: '${AppRoutes.serverEdit}/:id',
        name: AppRoutes.serverEditRoute,
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          return ServerEditScreen(serverId: serverId);
        },
      ),
      
      GoRoute(
        path: '${AppRoutes.serverDetails}/:id',
        name: AppRoutes.serverDetailsRoute,
        builder: (context, state) {
          final serverId = state.pathParameters['id']!;
          return ServerDetailsScreen(serverId: serverId);
        },
      ),
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The page "${state.uri.path}" could not be found.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    
    // Redirect handling
    redirect: (context, state) {
      // Add any authentication or initialization redirects here
      return null;
    },
  );
});

/// Navigation helper class
class AppNavigation {
  static void goToHome(BuildContext context) {
    context.go(AppRoutes.home);
  }
  
  static void goToServerPreview(BuildContext context) {
    context.go(AppRoutes.serverPreview);
  }
  
  static void goToConnectionManager(BuildContext context) {
    context.go(AppRoutes.connectionManager);
  }
  
  static void goToTerminal(BuildContext context, {
    String? serverId,
    String? sessionId,
  }) {
    final uri = Uri(
      path: AppRoutes.terminal,
      queryParameters: {
        if (serverId != null) 'serverId': serverId,
        if (sessionId != null) 'sessionId': sessionId,
      },
    );
    context.go(uri.toString());
  }
  
  static void goToFileTransfer(BuildContext context, {
    String? sessionId,
    String? remotePath,
    String? localPath,
  }) {
    final uri = Uri(
      path: AppRoutes.fileTransfer,
      queryParameters: {
        if (sessionId != null) 'sessionId': sessionId,
        if (remotePath != null) 'remotePath': remotePath,
        if (localPath != null) 'localPath': localPath,
      },
    );
    context.go(uri.toString());
  }
  
  static void goToAIAssistant(BuildContext context, {
    String? serverId,
    String? sessionId,
    AIMode? mode,
  }) {
    final uri = Uri(
      path: AppRoutes.aiAssistant,
      queryParameters: {
        if (serverId != null) 'serverId': serverId,
        if (sessionId != null) 'sessionId': sessionId,
        if (mode != null) 'mode': mode.name,
      },
    );
    context.go(uri.toString());
  }
  
  static void goToDashboard(BuildContext context, {
    String? serverId,
    bool editMode = false,
  }) {
    final uri = Uri(
      path: AppRoutes.dashboard,
      queryParameters: {
        if (serverId != null) 'serverId': serverId,
        if (editMode) 'edit': 'true',
      },
    );
    context.go(uri.toString());
  }
  
  static void goToSettings(BuildContext context) {
    context.go(AppRoutes.settings);
  }
  
  static void goToServerAdd(BuildContext context) {
    context.go(AppRoutes.serverAdd);
  }
  
  static void goToServerEdit(BuildContext context, String serverId) {
    context.go('${AppRoutes.serverEdit}/$serverId');
  }
  
  static void goToServerDetails(BuildContext context, String serverId) {
    context.go('${AppRoutes.serverDetails}/$serverId');
  }
  
  // Push methods for modal navigation
  static void pushTerminal(BuildContext context, {
    String? serverId,
    String? sessionId,
  }) {
    final uri = Uri(
      path: AppRoutes.terminal,
      queryParameters: {
        if (serverId != null) 'serverId': serverId,
        if (sessionId != null) 'sessionId': sessionId,
      },
    );
    context.push(uri.toString());
  }
  
  static void pushFileTransfer(BuildContext context, {
    String? sessionId,
    String? remotePath,
    String? localPath,
  }) {
    final uri = Uri(
      path: AppRoutes.fileTransfer,
      queryParameters: {
        if (sessionId != null) 'sessionId': sessionId,
        if (remotePath != null) 'remotePath': remotePath,
        if (localPath != null) 'localPath': localPath,
      },
    );
    context.push(uri.toString());
  }
  
  static void pushAIAssistant(BuildContext context, {
    String? serverId,
    String? sessionId,
    AIMode? mode,
  }) {
    final uri = Uri(
      path: AppRoutes.aiAssistant,
      queryParameters: {
        if (serverId != null) 'serverId': serverId,
        if (sessionId != null) 'sessionId': sessionId,
        if (mode != null) 'mode': mode.name,
      },
    );
    context.push(uri.toString());
  }
  
  static void pushDashboard(BuildContext context, {
    String? serverId,
    bool editMode = false,
  }) {
    final uri = Uri(
      path: AppRoutes.dashboard,
      queryParameters: {
        if (serverId != null) 'serverId': serverId,
        if (editMode) 'edit': 'true',
      },
    );
    context.push(uri.toString());
  }
  
  static void pushSettings(BuildContext context) {
    context.push(AppRoutes.settings);
  }
  
  static void pushServerAdd(BuildContext context) {
    context.push(AppRoutes.serverAdd);
  }
  
  static void pushServerEdit(BuildContext context, String serverId) {
    context.push('${AppRoutes.serverEdit}/$serverId');
  }
  
  static void pushServerDetails(BuildContext context, String serverId) {
    context.push('${AppRoutes.serverDetails}/$serverId');
  }
}

/// Route information provider
final currentRouteProvider = Provider<GoRouterState?>((ref) {
  // This would be updated by the router delegate
  // For now, return null - will be implemented with proper router integration
  return null;
});

/// Navigation state provider
final navigationStateProvider = StateNotifierProvider<NavigationStateNotifier, NavigationState>((ref) {
  return NavigationStateNotifier();
});

class NavigationState {
  final String currentRoute;
  final Map<String, dynamic> routeParameters;
  final bool canGoBack;
  final List<String> navigationHistory;
  
  const NavigationState({
    required this.currentRoute,
    required this.routeParameters,
    required this.canGoBack,
    required this.navigationHistory,
  });
  
  NavigationState copyWith({
    String? currentRoute,
    Map<String, dynamic>? routeParameters,
    bool? canGoBack,
    List<String>? navigationHistory,
  }) {
    return NavigationState(
      currentRoute: currentRoute ?? this.currentRoute,
      routeParameters: routeParameters ?? this.routeParameters,
      canGoBack: canGoBack ?? this.canGoBack,
      navigationHistory: navigationHistory ?? this.navigationHistory,
    );
  }
}

class NavigationStateNotifier extends StateNotifier<NavigationState> {
  NavigationStateNotifier() : super(
    const NavigationState(
      currentRoute: AppRoutes.home,
      routeParameters: {},
      canGoBack: false,
      navigationHistory: [],
    ),
  );
  
  void updateRoute(String route, Map<String, dynamic> parameters) {
    final newHistory = [...state.navigationHistory, route];
    state = state.copyWith(
      currentRoute: route,
      routeParameters: parameters,
      canGoBack: newHistory.length > 1,
      navigationHistory: newHistory,
    );
  }
  
  void goBack() {
    if (state.canGoBack && state.navigationHistory.isNotEmpty) {
      final newHistory = [...state.navigationHistory];
      newHistory.removeLast();
      
      final previousRoute = newHistory.isNotEmpty ? newHistory.last : AppRoutes.home;
      
      state = state.copyWith(
        currentRoute: previousRoute,
        routeParameters: {},
        canGoBack: newHistory.length > 1,
        navigationHistory: newHistory,
      );
    }
  }
  
  void clearHistory() {
    state = state.copyWith(
      navigationHistory: [state.currentRoute],
      canGoBack: false,
    );
  }
}