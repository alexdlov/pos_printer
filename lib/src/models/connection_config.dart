/// Configuration for printer connection.
class ConnectionConfig {
  /// Connection timeout duration.
  final Duration timeout;

  /// Auto-reconnect on connection loss (Bluetooth only).
  final bool autoReconnect;

  /// Discovery timeout duration.
  final Duration discoveryTimeout;

  const ConnectionConfig({
    this.timeout = const Duration(seconds: 5),
    this.autoReconnect = false,
    this.discoveryTimeout = const Duration(seconds: 10),
  });

  /// Default configuration.
  static const ConnectionConfig defaultConfig = ConnectionConfig();

  /// Configuration for fast connections.
  static const ConnectionConfig fast = ConnectionConfig(
    timeout: Duration(seconds: 2),
    discoveryTimeout: Duration(seconds: 5),
  );

  /// Configuration for reliable connections.
  static const ConnectionConfig reliable = ConnectionConfig(
    timeout: Duration(seconds: 10),
    autoReconnect: true,
    discoveryTimeout: Duration(seconds: 15),
  );

  ConnectionConfig copyWith({
    Duration? timeout,
    bool? autoReconnect,
    Duration? discoveryTimeout,
  }) {
    return ConnectionConfig(
      timeout: timeout ?? this.timeout,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      discoveryTimeout: discoveryTimeout ?? this.discoveryTimeout,
    );
  }
}
