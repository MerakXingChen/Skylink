import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/server.dart';
import '../services/storage_service.dart';
import '../services/ssh_service.dart';

// Server List Provider
final serverListProvider = StateNotifierProvider<ServerListNotifier, List<Server>>((ref) {
  return ServerListNotifier(
    ref.read(storageServiceProvider),
    ref.read(sshServiceProvider),
  );
});

// Current Server Provider
final currentServerProvider = StateProvider<Server?>((ref) => null);

// Server Connection Status Provider
final serverConnectionStatusProvider = StateNotifierProvider.family<ServerConnectionNotifier, ConnectionStatus, String>(
  (ref, serverId) {
    return ServerConnectionNotifier(serverId, ref.read(sshServiceProvider));
  },
);

class ServerListNotifier extends StateNotifier<List<Server>> {
  final StorageService _storageService;
  final SSHService _sshService;
  static const String _boxName = 'servers';

  ServerListNotifier(this._storageService, this._sshService) : super([]) {
    _loadServers();
  }

  Future<void> _loadServers() async {
    try {
      final box = await _storageService.openBox<Server>(_boxName);
      final servers = box.values.toList();
      servers.sort((a, b) => a.name.compareTo(b.name));
      state = servers;
    } catch (e) {
      print('Failed to load servers: $e');
      state = [];
    }
  }

  Future<void> addServer(Server server) async {
    try {
      final box = await _storageService.openBox<Server>(_boxName);
      await box.put(server.id, server);
      state = [...state, server];
      _sortServers();
    } catch (e) {
      print('Failed to add server: $e');
      throw Exception('Failed to add server');
    }
  }

  Future<void> updateServer(Server server) async {
    try {
      final box = await _storageService.openBox<Server>(_boxName);
      await box.put(server.id, server);
      
      final index = state.indexWhere((s) => s.id == server.id);
      if (index != -1) {
        final newState = [...state];
        newState[index] = server;
        state = newState;
        _sortServers();
      }
    } catch (e) {
      print('Failed to update server: $e');
      throw Exception('Failed to update server');
    }
  }

  Future<void> deleteServer(String serverId) async {
    try {
      final box = await _storageService.openBox<Server>(_boxName);
      await box.delete(serverId);
      
      // Disconnect if currently connected
      await _sshService.disconnect(serverId);
      
      state = state.where((server) => server.id != serverId).toList();
    } catch (e) {
      print('Failed to delete server: $e');
      throw Exception('Failed to delete server');
    }
  }

  Future<void> connectToServer(String serverId) async {
    try {
      final server = state.firstWhere((s) => s.id == serverId);
      await _sshService.connect(server);
      
      // Update server's last connection time and status
      final updatedServer = server.copyWith(
        lastConnectedAt: DateTime.now(),
        connectionStatus: ConnectionStatus.connected,
        errorMessage: null,
      );
      await updateServer(updatedServer);
    } catch (e) {
      // Update server with error status
      final server = state.firstWhere((s) => s.id == serverId);
      final updatedServer = server.copyWith(
        connectionStatus: ConnectionStatus.error,
        errorMessage: e.toString(),
      );
      await updateServer(updatedServer);
      rethrow;
    }
  }

  Future<void> disconnectFromServer(String serverId) async {
    try {
      await _sshService.disconnect(serverId);
      
      // Update server status
      final server = state.firstWhere((s) => s.id == serverId);
      final updatedServer = server.copyWith(
        connectionStatus: ConnectionStatus.disconnected,
        errorMessage: null,
      );
      await updateServer(updatedServer);
    } catch (e) {
      print('Failed to disconnect from server: $e');
      throw Exception('Failed to disconnect from server');
    }
  }

  Future<bool> testConnection(Server server) async {
    try {
      return await _sshService.testConnection(server);
    } catch (e) {
      return false;
    }
  }

  void _sortServers() {
    final sortedList = [...state];
    sortedList.sort((a, b) => a.name.compareTo(b.name));
    state = sortedList;
  }

  Server? getServerById(String id) {
    try {
      return state.firstWhere((server) => server.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Server> getConnectedServers() {
    return state.where((server) => server.connectionStatus == ConnectionStatus.connected).toList();
  }

  List<Server> searchServers(String query) {
    if (query.isEmpty) return state;
    
    final lowerQuery = query.toLowerCase();
    return state.where((server) {
      return server.name.toLowerCase().contains(lowerQuery) ||
             server.hostname.toLowerCase().contains(lowerQuery) ||
             server.username.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

class ServerConnectionNotifier extends StateNotifier<ConnectionStatus> {
  final String serverId;
  final SSHService _sshService;

  ServerConnectionNotifier(this.serverId, this._sshService) : super(ConnectionStatus.disconnected) {
    _initializeStatus();
  }

  void _initializeStatus() {
    state = _sshService.getConnectionStatus(serverId);
  }

  void updateStatus(ConnectionStatus status) {
    state = status;
  }
}

// Convenience providers
final connectedServersProvider = Provider<List<Server>>((ref) {
  final servers = ref.watch(serverListProvider);
  return servers.where((server) => server.connectionStatus == ConnectionStatus.connected).toList();
});

final serverCountProvider = Provider<int>((ref) {
  return ref.watch(serverListProvider).length;
});

final connectedServerCountProvider = Provider<int>((ref) {
  return ref.watch(connectedServersProvider).length;
});