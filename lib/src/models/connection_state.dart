/// Represents the current connection state of a printer.
enum ConnectionState {
  /// Not connected to any printer.
  disconnected,

  /// Currently attempting to connect.
  connecting,

  /// Successfully connected to a printer.
  connected,

  /// Connection failed or lost.
  error,
}

extension ConnectionStateExtension on ConnectionState {
  bool get isConnected => this == ConnectionState.connected;
  bool get isConnecting => this == ConnectionState.connecting;
  bool get isDisconnected => this == ConnectionState.disconnected;
  bool get hasError => this == ConnectionState.error;

  String get displayName {
    switch (this) {
      case ConnectionState.disconnected:
        return 'Disconnected';
      case ConnectionState.connecting:
        return 'Connecting...';
      case ConnectionState.connected:
        return 'Connected';
      case ConnectionState.error:
        return 'Error';
    }
  }
}
