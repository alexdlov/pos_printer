import 'dart:io';
import 'printer_type.dart';

/// Represents a discovered printer device.
class PrinterDevice {
  /// Display name of the device.
  final String name;

  /// Device address (MAC for Bluetooth, IP for Network, path for USB).
  final String? address;

  /// Connection type.
  final PrinterType type;

  /// USB Vendor ID (only for USB printers).
  final String? vendorId;

  /// USB Product ID (only for USB printers).
  final String? productId;

  /// Network port (only for Network printers, default 9100).
  final int port;

  /// Whether this is a BLE device (only for Bluetooth).
  final bool isBle;

  const PrinterDevice({
    required this.name,
    this.address,
    required this.type,
    this.vendorId,
    this.productId,
    this.port = 9100,
    this.isBle = false,
  });

  /// Create from Bluetooth discovery result.
  factory PrinterDevice.bluetooth({
    required String name,
    required String address,
    bool isBle = false,
  }) {
    return PrinterDevice(
      name: name,
      address: address,
      type: PrinterType.bluetooth,
      isBle: isBle,
    );
  }

  /// Create from USB discovery result.
  factory PrinterDevice.usb({
    required String name,
    required String vendorId,
    required String productId,
  }) {
    return PrinterDevice(
      name: name,
      type: PrinterType.usb,
      vendorId: vendorId,
      productId: productId,
    );
  }

  /// Create from Network discovery result.
  factory PrinterDevice.network({
    required String address,
    String? name,
    int port = 9100,
  }) {
    return PrinterDevice(
      name: name ?? '$address:$port',
      address: address,
      type: PrinterType.network,
      port: port,
    );
  }

  /// Create from manual IP input.
  factory PrinterDevice.fromIp(String ip, {int port = 9100}) {
    return PrinterDevice.network(address: ip, port: port);
  }

  /// Unique identifier for the device.
  String get id {
    switch (type) {
      case PrinterType.bluetooth:
        return 'bt_$address';
      case PrinterType.usb:
        // On Windows, USB printers are identified by name (via Print Spooler)
        // On Android, USB printers use VID/PID
        if (Platform.isWindows || (vendorId == null && productId == null)) {
          return 'usb_$name';
        }
        return 'usb_${vendorId}_$productId';
      case PrinterType.network:
        return 'net_${address}_$port';
    }
  }

  /// Display string showing connection info.
  String get connectionInfo {
    switch (type) {
      case PrinterType.bluetooth:
        return address ?? 'Unknown';
      case PrinterType.usb:
        return 'VID:$vendorId PID:$productId';
      case PrinterType.network:
        return '$address:$port';
    }
  }

  /// Operating system name.
  String get platform => Platform.operatingSystem;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PrinterDevice($name, $type, $connectionInfo)';

  /// Create a copy with modified fields.
  PrinterDevice copyWith({
    String? name,
    String? address,
    PrinterType? type,
    String? vendorId,
    String? productId,
    int? port,
    bool? isBle,
  }) {
    return PrinterDevice(
      name: name ?? this.name,
      address: address ?? this.address,
      type: type ?? this.type,
      vendorId: vendorId ?? this.vendorId,
      productId: productId ?? this.productId,
      port: port ?? this.port,
      isBle: isBle ?? this.isBle,
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'type': type.name,
      'vendorId': vendorId,
      'productId': productId,
      'port': port,
      'isBle': isBle,
    };
  }

  /// Create from JSON map.
  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(
      name: json['name'] as String,
      address: json['address'] as String?,
      type: PrinterType.values.byName(json['type'] as String),
      vendorId: json['vendorId'] as String?,
      productId: json['productId'] as String?,
      port: json['port'] as int? ?? 9100,
      isBle: json['isBle'] as bool? ?? false,
    );
  }
}
