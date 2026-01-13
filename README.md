# POS Printer D

A clean Flutter plugin for POS thermal printers. Supports Bluetooth, USB, and Network (TCP) connections.

Reference - flutter_pos_printer_platform

## Features

- ✅ **Bluetooth** - Classic Bluetooth and BLE (Android, iOS)
- ✅ **USB** - Direct USB connection (Android, Windows)
- ✅ **Network/TCP** - Ethernet printers (All platforms)
- ✅ **Simple API** - Single `PrinterService` for all operations
- ✅ **Reactive** - Stream-based state management
- ✅ **Type-safe** - Full Dart null-safety support

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  pos_printer_d: ^1.0.0
```

Or from Git:

```yaml
dependencies:
  pos_printer_d:
    git:
      url: https://github.com/alexdlov/pos_printer.git
```

## Quick Start

```dart
import 'package:pos_printer_d/pos_printer_d.dart';

// Get the service instance
final printerService = PrinterService.instance;

// Discover printers
await for (final device in printerService.discover(PrinterType.bluetooth)) {
  print('Found: ${device.name}');
}

// Connect to a printer
await printerService.connect(device);

// Send ESC/POS data
await printerService.send(bytes);

// Disconnect
await printerService.disconnect();
```

## API Overview

### PrinterService

Main entry point for all printer operations:

```dart
final service = PrinterService.instance;

// Check supported types
service.supportedTypes; // [bluetooth, usb, network]
service.isSupported(PrinterType.bluetooth); // true/false

// Discovery
service.discover(PrinterType.bluetooth);
service.discoverAll(); // All types at once
service.stopDiscovery();

// Connection
service.connect(device, config: ConnectionConfig.reliable);
service.connectToIp('192.168.1.100', port: 9100);
service.disconnect();
service.isConnected; // bool
service.currentDevice; // PrinterDevice?

// State
service.stateStream; // Stream<ConnectionState>
service.currentState; // ConnectionState

// Printing
service.send(bytes);
service.sendBytes(list);
service.sendText('Hello');

// ESC/POS helpers
service.initialize();
service.cut();
service.feed(3);
service.beep();
```

### PrinterDevice

Represents a discovered printer:

```dart
// Factory constructors
PrinterDevice.bluetooth(name: 'Printer', address: 'AA:BB:CC:DD:EE:FF');
PrinterDevice.usb(name: 'USB Printer', vendorId: '1234', productId: '5678');
PrinterDevice.network(address: '192.168.1.100', port: 9100);

// Properties
device.name;        // Display name
device.type;        // PrinterType
device.address;     // MAC/IP address
device.vendorId;    // USB vendor (USB only)
device.productId;   // USB product (USB only)
device.port;        // Network port (Network only)
device.isBle;       // BLE flag (Bluetooth only)
```

### ConnectionConfig

Configure connection behavior:

```dart
ConnectionConfig(
  timeout: Duration(seconds: 5),
  autoReconnect: false,
  discoveryTimeout: Duration(seconds: 10),
);

// Presets
ConnectionConfig.defaultConfig;
ConnectionConfig.fast;
ConnectionConfig.reliable;
```

### ConnectionState

Track connection status:

```dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

// Extensions
state.isConnected;    // bool
state.isConnecting;   // bool
state.displayName;    // "Connected", "Connecting...", etc.
```

## Platform Support

| Feature | Android | iOS | Windows | macOS | Linux |
|---------|---------|-----|---------|-------|-------|
| Bluetooth | ✅ | ✅ | ❌ | ❌ | ❌ |
| USB | ✅ | ❌ | ✅ | ❌ | ❌ |
| Network | ✅ | ✅ | ✅ | ✅ | ✅ |

## Permissions

### Android

Add to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### iOS

Add to `Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app needs Bluetooth to connect to printers</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app needs Bluetooth to connect to printers</string>
```

## Example

See the [example](example/) directory for a complete demo app.

## License

MIT
