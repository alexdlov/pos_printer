import 'dart:async';
import 'dart:typed_data';

import '../models/printer_device.dart';
import '../models/connection_state.dart';
import '../models/connection_config.dart';

/// Abstract interface for printer connectors.
///
/// Each connection type (Bluetooth, USB, Network) implements this interface.
abstract class PrinterConnector {
  /// Stream of connection state changes.
  Stream<ConnectionState> get stateStream;

  /// Current connection state.
  ConnectionState get currentState;

  /// Currently connected device, if any.
  PrinterDevice? get connectedDevice;

  /// Discover available printers.
  ///
  /// Returns a stream of discovered [PrinterDevice] objects.
  /// The stream completes when discovery timeout is reached.
  Stream<PrinterDevice> discover({
    Duration timeout = const Duration(seconds: 10),
  });

  /// Stop ongoing discovery.
  Future<void> stopDiscovery();

  /// Connect to a printer device.
  ///
  /// Returns `true` if connection was successful.
  Future<bool> connect(
    PrinterDevice device, {
    ConnectionConfig config = ConnectionConfig.defaultConfig,
  });

  /// Disconnect from the current printer.
  ///
  /// Returns `true` if disconnection was successful.
  Future<bool> disconnect();

  /// Send raw bytes to the connected printer.
  ///
  /// Returns `true` if data was sent successfully.
  Future<bool> send(Uint8List bytes);

  /// Dispose resources.
  void dispose();
}

/// Exception thrown when printer operations fail.
class PrinterException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const PrinterException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'PrinterException: $message${code != null ? ' ($code)' : ''}';
}
