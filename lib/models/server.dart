import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'server.g.dart';

@HiveType(typeId: 0)
@JsonSerializable()
class Server {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String hostname;

  @HiveField(3)
  final int port;

  @HiveField(4)
  final String username;

  @HiveField(5)
  final String? password;

  @HiveField(6)
  final String? privateKeyPath;

  @HiveField(7)
  final String? privateKeyPassphrase;

  @HiveField(8)
  final AuthType authType;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final bool isConnected;

  @HiveField(12)
  final String? lastConnectionError;

  @HiveField(13)
  final DateTime? lastConnectedAt;

  @HiveField(14)
  final Map<String, dynamic>? customSettings;

  const Server({
    required this.id,
    required this.name,
    required this.hostname,
    required this.port,
    required this.username,
    this.password,
    this.privateKeyPath,
    this.privateKeyPassphrase,
    required this.authType,
    required this.createdAt,
    required this.updatedAt,
    this.isConnected = false,
    this.lastConnectionError,
    this.lastConnectedAt,
    this.customSettings,
  });

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
  Map<String, dynamic> toJson() => _$ServerToJson(this);

  Server copyWith({
    String? id,
    String? name,
    String? hostname,
    int? port,
    String? username,
    String? password,
    String? privateKeyPath,
    String? privateKeyPassphrase,
    AuthType? authType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isConnected,
    String? lastConnectionError,
    DateTime? lastConnectedAt,
    Map<String, dynamic>? customSettings,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      password: password ?? this.password,
      privateKeyPath: privateKeyPath ?? this.privateKeyPath,
      privateKeyPassphrase: privateKeyPassphrase ?? this.privateKeyPassphrase,
      authType: authType ?? this.authType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isConnected: isConnected ?? this.isConnected,
      lastConnectionError: lastConnectionError ?? this.lastConnectionError,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Server && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Server(id: $id, name: $name, hostname: $hostname, port: $port)';
  }
}

@HiveType(typeId: 1)
enum AuthType {
  @HiveField(0)
  password,
  @HiveField(1)
  privateKey,
  @HiveField(2)
  passwordAndPrivateKey,
}