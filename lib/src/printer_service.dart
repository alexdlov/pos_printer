import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import 'models/printer_device.dart';
import 'models/printer_type.dart';
import 'models/connection_state.dart';
import 'models/connection_config.dart';
import 'connectors/printer_connector.dart';
import 'connectors/bluetooth_connector.dart';
import 'connectors/usb_connector.dart';
import 'connectors/tcp_connector.dart';

/// Main service for printer operations.
///
/// Provides a unified interface for discovering, connecting, and printing
/// to thermal printers via Bluetooth, USB, or Network (TCP).
///
/// ## Usage
///
/// ```dart
/// final service = PrinterService.instance;
///
/// // Discover printers
/// await for (final device in service.discover(PrinterType.bluetooth)) {
///   print('Found: ${device.name}');
/// }
///
/// // Connect
/// await service.connect(device);
///
/// // Print
/// await service.send(bytes);
///
/// // Disconnect
/// await service.disconnect();
/// ```
class PrinterService {
  PrinterService._();

  static PrinterService? _instance;

  /// Singleton instance of the printer service.
  static PrinterService get instance {
    _instance ??= PrinterService._();
    return _instance!;
  }

  /// Create a new instance (useful for testing or multiple connections).
  factory PrinterService.create() => PrinterService._();

  // Connectors
  final _bluetoothConnector = BluetoothConnector.instance;
  final _usbConnector = UsbConnector.instance;
  final _tcpConnector = TcpConnector.instance;

  // State
  final _currentDeviceController = BehaviorSubject<PrinterDevice?>.seeded(null);
  final _stateController =
      BehaviorSubject<ConnectionState>.seeded(ConnectionState.disconnected);

  PrinterType? _currentType;
  StreamSubscription? _stateSubscription;

  /// Stream of the currently connected device (null if disconnected).
  Stream<PrinterDevice?> get currentDeviceStream =>
      _currentDeviceController.stream;

  /// Currently connected device, or null if not connected.
  PrinterDevice? get currentDevice => _currentDeviceController.value;

  /// Stream of connection state changes.
  Stream<ConnectionState> get stateStream => _stateController.stream;

  /// Current connection state.
  ConnectionState get currentState => _stateController.value;

  /// Whether currently connected to a printer.
  bool get isConnected => currentState == ConnectionState.connected;

  /// Get the connector for a specific printer type.
  PrinterConnector _getConnector(PrinterType type) {
    switch (type) {
      case PrinterType.bluetooth:
        return _bluetoothConnector;
      case PrinterType.usb:
        return _usbConnector;
      case PrinterType.network:
        return _tcpConnector;
    }
  }

  /// Check if a printer type is supported on the current platform.
  bool isSupported(PrinterType type) {
    switch (type) {
      case PrinterType.bluetooth:
        return Platform.isAndroid || Platform.isIOS;
      case PrinterType.usb:
        return Platform.isAndroid || Platform.isWindows;
      case PrinterType.network:
        return true; // Supported on all platforms
    }
  }

  /// Get list of supported printer types for current platform.
  List<PrinterType> get supportedTypes {
    return PrinterType.values.where(isSupported).toList();
  }

  /// Discover printers of a specific type.
  ///
  /// Returns a stream of discovered [PrinterDevice] objects.
  ///
  /// ```dart
  /// await for (final device in service.discover(PrinterType.bluetooth)) {
  ///   print('Found: ${device.name}');
  /// }
  /// ```
  Stream<PrinterDevice> discover(
    PrinterType type, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    if (!isSupported(type)) {
      return Stream.error(
        PrinterException('$type not supported on ${Platform.operatingSystem}'),
      );
    }

    return _getConnector(type).discover(timeout: timeout);
  }

  /// Discover all supported printer types simultaneously.
  ///
  /// Returns a combined stream of all discovered devices.
  Stream<PrinterDevice> discoverAll({
    Duration timeout = const Duration(seconds: 10),
  }) {
    final streams = supportedTypes.map(
      (type) => discover(type, timeout: timeout),
    );

    return Rx.merge(streams);
  }

  /// Stop all ongoing discovery operations.
  Future<void> stopDiscovery() async {
    await Future.wait([
      _bluetoothConnector.stopDiscovery(),
      _usbConnector.stopDiscovery(),
      _tcpConnector.stopDiscovery(),
    ]);
  }

  /// Connect to a printer device.
  ///
  /// Returns `true` if connection was successful.
  ///
  /// ```dart
  /// final success = await service.connect(device);
  /// if (success) {
  ///   print('Connected to ${device.name}');
  /// }
  /// ```
  Future<bool> connect(
    PrinterDevice device, {
    ConnectionConfig config = ConnectionConfig.defaultConfig,
  }) async {
    // Disconnect from current device if connected
    if (isConnected) {
      await disconnect();
    }

    final connector = _getConnector(device.type);

    // Subscribe to connector's state stream
    _stateSubscription?.cancel();
    _stateSubscription = connector.stateStream.listen((state) {
      _stateController.add(state);
      if (state == ConnectionState.disconnected) {
        _currentDeviceController.add(null);
        _currentType = null;
      }
    });

    try {
      final result = await connector.connect(device, config: config);

      if (result) {
        _currentDeviceController.add(device);
        _currentType = device.type;
        _stateController.add(ConnectionState.connected);
      }

      return result;
    } catch (e) {
      _stateController.add(ConnectionState.error);
      rethrow;
    }
  }

  /// Connect directly to a network printer by IP address.
  ///
  /// Convenience method for quick network printer connections.
  ///
  /// ```dart
  /// await service.connectToIp('192.168.1.100');
  /// ```
  Future<bool> connectToIp(
    String ip, {
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) {
    return connect(
      PrinterDevice.network(address: ip, port: port),
      config: ConnectionConfig(timeout: timeout),
    );
  }

  /// Disconnect from the current printer.
  ///
  /// Returns `true` if disconnection was successful.
  Future<bool> disconnect() async {
    if (_currentType == null) {
      return true;
    }

    try {
      final result = await _getConnector(_currentType!).disconnect();
      _currentDeviceController.add(null);
      _currentType = null;
      _stateController.add(ConnectionState.disconnected);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Send raw bytes to the connected printer.
  ///
  /// ```dart
  /// final bytes = [0x1B, 0x40]; // ESC @ (Initialize)
  /// await service.send(Uint8List.fromList(bytes));
  /// ```
  Future<bool> send(Uint8List bytes) async {
    if (!isConnected || _currentType == null) {
      throw const PrinterException('Not connected to any printer');
    }

    return _getConnector(_currentType!).send(bytes);
  }

  /// Send raw bytes as List < int > (convenience method).
  Future<bool> sendBytes(List<int> bytes) => send(Uint8List.fromList(bytes));

  /// Send text string (encoded as UTF-8 bytes).
  Future<bool> sendText(String text) => sendBytes(text.codeUnits);

  /// Print and then disconnect (one-shot print).
  ///
  /// Useful for quick print jobs where you don't need to maintain connection.
  Future<bool> printAndDisconnect(Uint8List bytes) async {
    final result = await send(bytes);
    await disconnect();
    return result;
  }

  /// Send common ESC/POS commands.
  Future<bool> initialize() => sendBytes([0x1B, 0x40]); // ESC @

  Future<bool> cut({bool partial = false}) =>
      sendBytes([0x1D, 0x56, partial ? 0x01 : 0x00]); // GS V

  Future<bool> feed([int lines = 1]) => sendBytes([0x1B, 0x64, lines]); // ESC d

  Future<bool> beep([int times = 1]) =>
      sendBytes([0x1B, 0x42, times, 0x02]); // ESC B

  /// Dispose all resources.
  void dispose() {
    _stateSubscription?.cancel();
    _currentDeviceController.close();
    _stateController.close();
    _bluetoothConnector.dispose();
    _usbConnector.dispose();
    _tcpConnector.dispose();
  }
}
