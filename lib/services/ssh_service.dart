import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dartssh2/dartssh2.dart';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import '../models/index.dart';
import 'storage_service.dart';

// SSH Service Provider
final sshServiceProvider = Provider<SSHService>((ref) {
  final storageService = ref.watch(storageServiceProvider);
  return SSHService(storageService);
});

class SSHService {
  final StorageService _storageService;
  final Map<String, SSHSession> _activeSessions = {};
  final Map<String, StreamController<SSHConnectionEvent>> _eventControllers = {};

  SSHService(this._storageService);

  /// Get all active SSH sessions
  Map<String, SSHSession> get activeSessions => Map.unmodifiable(_activeSessions);

  /// Get session by server ID
  SSHSession? getSession(String serverId) => _activeSessions[serverId];

  /// Check if server is connected
  bool isConnected(String serverId) {
    final session = _activeSessions[serverId];
    return session?.isConnected ?? false;
  }

  /// Get connection event stream for a server
  Stream<SSHConnectionEvent> getConnectionEvents(String serverId) {
    _eventControllers[serverId] ??= StreamController<SSHConnectionEvent>.broadcast();
    return _eventControllers[serverId]!.stream;
  }

  /// Connect to a server
  Future<SSHConnectionResult> connect(Server server) async {
    try {
      _emitEvent(server.id, SSHConnectionEvent(
        serverId: server.id,
        type: SSHConnectionEventType.connecting,
        timestamp: DateTime.now(),
      ));

      // Close existing connection if any
      await disconnect(server.id);

      // Create SSH client
      final socket = await SSHSocket.connect(
        server.hostname,
        server.port,
        timeout: Duration(seconds: server.customSettings['connectionTimeout'] ?? 30),
      );

      final client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: () => server.password ?? '',
        onPrivateKeyRequest: () => _loadPrivateKey(server.privateKeyPath),
      );

      // Authenticate based on auth type
      bool authenticated = false;
      switch (server.authType) {
        case AuthType.password:
          if (server.password?.isNotEmpty == true) {
            authenticated = await client.authenticate(
              SSHPasswordAuth(server.password!),
            );
          }
          break;
        case AuthType.privateKey:
          if (server.privateKeyPath?.isNotEmpty == true) {
            final privateKey = await _loadPrivateKey(server.privateKeyPath!);
            if (privateKey != null) {
              authenticated = await client.authenticate(
                SSHPrivateKeyAuth(privateKey),
              );
            }
          }
          break;
        case AuthType.publicKey:
          // TODO: Implement public key authentication
          break;
      }

      if (!authenticated) {
        await client.close();
        throw SSHException('Authentication failed');
      }

      // Create session
      final session = SSHSession(
        serverId: server.id,
        client: client,
        connectedAt: DateTime.now(),
      );

      _activeSessions[server.id] = session;

      // Update server connection status
      await _updateServerStatus(server.id, true);

      _emitEvent(server.id, SSHConnectionEvent(
        serverId: server.id,
        type: SSHConnectionEventType.connected,
        timestamp: DateTime.now(),
      ));

      return SSHConnectionResult.success(session);
    } catch (e) {
      await _updateServerStatus(server.id, false, e.toString());
      
      _emitEvent(server.id, SSHConnectionEvent(
        serverId: server.id,
        type: SSHConnectionEventType.error,
        timestamp: DateTime.now(),
        error: e.toString(),
      ));

      return SSHConnectionResult.failure(e.toString());
    }
  }

  /// Disconnect from a server
  Future<void> disconnect(String serverId) async {
    try {
      final session = _activeSessions[serverId];
      if (session != null) {
        await session.client.close();
        _activeSessions.remove(serverId);
        
        _emitEvent(serverId, SSHConnectionEvent(
          serverId: serverId,
          type: SSHConnectionEventType.disconnected,
          timestamp: DateTime.now(),
        ));
      }

      await _updateServerStatus(serverId, false);
    } catch (e) {
      print('Error disconnecting from server $serverId: $e');
    }
  }

  /// Disconnect all sessions
  Future<void> disconnectAll() async {
    final serverIds = _activeSessions.keys.toList();
    await Future.wait(serverIds.map(disconnect));
  }

  /// Execute a command on a server
  Future<SSHCommandResult> executeCommand(
    String serverId,
    String command, {
    Duration? timeout,
    Map<String, String>? environment,
  }) async {
    final session = _activeSessions[serverId];
    if (session == null) {
      return SSHCommandResult.failure('Server not connected');
    }

    try {
      final result = await session.client.run(
        command,
        environment: environment,
        timeout: timeout ?? const Duration(seconds: 30),
      );

      return SSHCommandResult.success(
        stdout: result.stdout,
        stderr: result.stderr,
        exitCode: result.exitCode,
      );
    } catch (e) {
      return SSHCommandResult.failure(e.toString());
    }
  }

  /// Create an interactive shell session
  Future<SSHShellResult> createShell(
    String serverId, {
    String? terminalType,
    int? columns,
    int? rows,
  }) async {
    final session = _activeSessions[serverId];
    if (session == null) {
      return SSHShellResult.failure('Server not connected');
    }

    try {
      final shell = await session.client.shell(
        pty: SSHPtyConfig(
          type: terminalType ?? 'xterm-256color',
          width: columns ?? 80,
          height: rows ?? 24,
        ),
      );

      return SSHShellResult.success(shell);
    } catch (e) {
      return SSHShellResult.failure(e.toString());
    }
  }

  /// Create SFTP session for file operations
  Future<SSHSftpResult> createSftp(String serverId) async {
    final session = _activeSessions[serverId];
    if (session == null) {
      return SSHSftpResult.failure('Server not connected');
    }

    try {
      final sftp = await session.client.sftp();
      return SSHSftpResult.success(sftp);
    } catch (e) {
      return SSHSftpResult.failure(e.toString());
    }
  }

  /// Port forwarding - Local to Remote
  Future<SSHPortForwardResult> createLocalForward(
    String serverId,
    String localHost,
    int localPort,
    String remoteHost,
    int remotePort,
  ) async {
    final session = _activeSessions[serverId];
    if (session == null) {
      return SSHPortForwardResult.failure('Server not connected');
    }

    try {
      final forward = await session.client.forwardLocal(
        localHost,
        localPort,
        remoteHost,
        remotePort,
      );

      return SSHPortForwardResult.success(forward);
    } catch (e) {
      return SSHPortForwardResult.failure(e.toString());
    }
  }

  /// Port forwarding - Remote to Local
  Future<SSHPortForwardResult> createRemoteForward(
    String serverId,
    String remoteHost,
    int remotePort,
    String localHost,
    int localPort,
  ) async {
    final session = _activeSessions[serverId];
    if (session == null) {
      return SSHPortForwardResult.failure('Server not connected');
    }

    try {
      final forward = await session.client.forwardRemote(
        remoteHost,
        remotePort,
        localHost,
        localPort,
      );

      return SSHPortForwardResult.success(forward);
    } catch (e) {
      return SSHPortForwardResult.failure(e.toString());
    }
  }

  /// Test connection to a server
  Future<SSHTestResult> testConnection(Server server) async {
    try {
      final socket = await SSHSocket.connect(
        server.hostname,
        server.port,
        timeout: const Duration(seconds: 10),
      );

      final client = SSHClient(
        socket,
        username: server.username,
        onPasswordRequest: () => server.password ?? '',
        onPrivateKeyRequest: () => _loadPrivateKey(server.privateKeyPath),
      );

      bool authenticated = false;
      switch (server.authType) {
        case AuthType.password:
          if (server.password?.isNotEmpty == true) {
            authenticated = await client.authenticate(
              SSHPasswordAuth(server.password!),
            );
          }
          break;
        case AuthType.privateKey:
          if (server.privateKeyPath?.isNotEmpty == true) {
            final privateKey = await _loadPrivateKey(server.privateKeyPath!);
            if (privateKey != null) {
              authenticated = await client.authenticate(
                SSHPrivateKeyAuth(privateKey),
              );
            }
          }
          break;
        case AuthType.publicKey:
          // TODO: Implement public key authentication
          break;
      }

      await client.close();

      if (authenticated) {
        return SSHTestResult.success();
      } else {
        return SSHTestResult.failure('Authentication failed');
      }
    } catch (e) {
      return SSHTestResult.failure(e.toString());
    }
  }

  /// Load private key from file or secure storage
  Future<SSHKeyPair?> _loadPrivateKey(String? keyPath) async {
    if (keyPath == null || keyPath.isEmpty) return null;

    try {
      // Try to load from secure storage first
      final secureKey = await _storageService.getSecureData('private_key_$keyPath');
      if (secureKey != null) {
        return SSHKeyPair.fromPem(secureKey);
      }

      // Try to load from file
      final file = File(keyPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        return SSHKeyPair.fromPem(content);
      }

      return null;
    } catch (e) {
      print('Failed to load private key from $keyPath: $e');
      return null;
    }
  }

  /// Update server connection status in storage
  Future<void> _updateServerStatus(String serverId, bool isConnected, [String? error]) async {
    try {
      final box = await _storageService.openBox<Server>('servers');
      final server = box.get(serverId);
      if (server != null) {
        final updatedServer = server.copyWith(
          isConnected: isConnected,
          lastError: error,
          lastConnectedAt: isConnected ? DateTime.now() : server.lastConnectedAt,
        );
        await box.put(serverId, updatedServer);
      }
    } catch (e) {
      print('Failed to update server status: $e');
    }
  }

  /// Emit connection event
  void _emitEvent(String serverId, SSHConnectionEvent event) {
    final controller = _eventControllers[serverId];
    if (controller != null && !controller.isClosed) {
      controller.add(event);
    }
  }

  /// Dispose resources
  void dispose() {
    // Close all event controllers
    for (final controller in _eventControllers.values) {
      controller.close();
    }
    _eventControllers.clear();

    // Disconnect all sessions
    disconnectAll();
  }
}

// SSH Session wrapper
class SSHSession {
  final String serverId;
  final SSHClient client;
  final DateTime connectedAt;
  DateTime lastActivity;

  SSHSession({
    required this.serverId,
    required this.client,
    required this.connectedAt,
  }) : lastActivity = DateTime.now();

  bool get isConnected => client.isClosed == false;

  void updateActivity() {
    lastActivity = DateTime.now();
  }

  Duration get connectionDuration => DateTime.now().difference(connectedAt);
  Duration get idleDuration => DateTime.now().difference(lastActivity);
}

// Connection Events
class SSHConnectionEvent {
  final String serverId;
  final SSHConnectionEventType type;
  final DateTime timestamp;
  final String? error;
  final Map<String, dynamic>? metadata;

  const SSHConnectionEvent({
    required this.serverId,
    required this.type,
    required this.timestamp,
    this.error,
    this.metadata,
  });
}

enum SSHConnectionEventType {
  connecting,
  connected,
  disconnected,
  error,
  reconnecting,
}

// Result classes
class SSHConnectionResult {
  final bool isSuccess;
  final SSHSession? session;
  final String? error;

  const SSHConnectionResult._({required this.isSuccess, this.session, this.error});

  factory SSHConnectionResult.success(SSHSession session) {
    return SSHConnectionResult._(isSuccess: true, session: session);
  }

  factory SSHConnectionResult.failure(String error) {
    return SSHConnectionResult._(isSuccess: false, error: error);
  }
}

class SSHCommandResult {
  final bool isSuccess;
  final String? stdout;
  final String? stderr;
  final int? exitCode;
  final String? error;

  const SSHCommandResult._({required this.isSuccess, this.stdout, this.stderr, this.exitCode, this.error});

  factory SSHCommandResult.success({String? stdout, String? stderr, int? exitCode}) {
    return SSHCommandResult._(
      isSuccess: true,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
    );
  }

  factory SSHCommandResult.failure(String error) {
    return SSHCommandResult._(isSuccess: false, error: error);
  }
}

class SSHShellResult {
  final bool isSuccess;
  final SSHSession? shell;
  final String? error;

  const SSHShellResult._({required this.isSuccess, this.shell, this.error});

  factory SSHShellResult.success(SSHSession shell) {
    return SSHShellResult._(isSuccess: true, shell: shell);
  }

  factory SSHShellResult.failure(String error) {
    return SSHShellResult._(isSuccess: false, error: error);
  }
}

class SSHSftpResult {
  final bool isSuccess;
  final SftpClient? sftp;
  final String? error;

  const SSHSftpResult._({required this.isSuccess, this.sftp, this.error});

  factory SSHSftpResult.success(SftpClient sftp) {
    return SSHSftpResult._(isSuccess: true, sftp: sftp);
  }

  factory SSHSftpResult.failure(String error) {
    return SSHSftpResult._(isSuccess: false, error: error);
  }
}

class SSHPortForwardResult {
  final bool isSuccess;
  final SSHForward? forward;
  final String? error;

  const SSHPortForwardResult._({required this.isSuccess, this.forward, this.error});

  factory SSHPortForwardResult.success(SSHForward forward) {
    return SSHPortForwardResult._(isSuccess: true, forward: forward);
  }

  factory SSHPortForwardResult.failure(String error) {
    return SSHPortForwardResult._(isSuccess: false, error: error);
  }
}

class SSHTestResult {
  final bool isSuccess;
  final String? error;
  final Duration? latency;

  const SSHTestResult._({required this.isSuccess, this.error, this.latency});

  factory SSHTestResult.success({Duration? latency}) {
    return SSHTestResult._(isSuccess: true, latency: latency);
  }

  factory SSHTestResult.failure(String error) {
    return SSHTestResult._(isSuccess: false, error: error);
  }
}

class SSHException implements Exception {
  final String message;
  const SSHException(this.message);
  
  @override
  String toString() => 'SSHException: $message';
}