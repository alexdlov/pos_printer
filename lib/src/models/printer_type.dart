/// Supported printer connection types.
enum PrinterType {
  /// Bluetooth Classic or BLE connection.
  /// Supported on: Android, iOS
  bluetooth,

  /// USB connection.
  /// Supported on: Android, Windows
  usb,

  /// Network/TCP connection.
  /// Supported on: All platforms
  network,
}

extension PrinterTypeExtension on PrinterType {
  String get displayName {
    switch (this) {
      case PrinterType.bluetooth:
        return 'Bluetooth';
      case PrinterType.usb:
        return 'USB';
      case PrinterType.network:
        return 'Network';
    }
  }

  String get icon {
    switch (this) {
      case PrinterType.bluetooth:
        return '📶';
      case PrinterType.usb:
        return '🔌';
      case PrinterType.network:
        return '🌐';
    }
  }
}
