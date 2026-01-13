import 'dart:async';
import 'dart:typed_data';

import 'package:pos_printer_d/pos_printer_d.dart';

import 'printer_repository.dart';

/// Service for working with the printer.
///
/// Implements the pattern "connect -> print -> disconnect",
/// so as not to occupy the connection constantly.
class PrinterLocalService {
  final PrinterService _printerService;
  final PrinterRepository _repository;

  PrinterLocalService({
    required PrinterService printerService,
    required PrinterRepository repository,
  })  : _printerService = printerService,
        _repository = repository;

  /// Get the saved printer.
  PrinterDevice? get savedPrinter => _repository.getSavedPrinter();

  /// Check if there is a saved printer.
  bool get hasSavedPrinter => _repository.hasSavedPrinter();

  /// Save the printer.
  Future<void> savePrinter(PrinterDevice device) =>
      _repository.savePrinter(device);

  /// Remove the saved printer.
  Future<void> removePrinter() => _repository.removePrinter();

  /// Discover printers.
  Stream<PrinterDevice> discover(
    PrinterType type, {
    Duration timeout = const Duration(seconds: 10),
  }) {
    return _printerService.discover(type, timeout: timeout);
  }

  /// Stop discovery.
  Future<void> stopDiscovery() => _printerService.stopDiscovery();

  /// Connect to a printer.
  Future<bool> connect(PrinterDevice device) async {
    return _printerService.connect(
      device,
      config: const ConnectionConfig(
        timeout: Duration(seconds: 5),
        autoReconnect: false,
      ),
    );
  }

  /// Disconnect from the printer.
  Future<void> disconnect() => _printerService.disconnect();

  /// Check connection.
  bool get isConnected => _printerService.isConnected;

  /// Connection state stream.
  Stream<ConnectionState> get stateStream => _printerService.stateStream;

  /// Current state.
  ConnectionState get currentState => _printerService.currentState;

  /// Print with automatic connect and disconnect.
  ///
  /// Connects to the saved or specified printer,
  /// sends data and disconnects.
  Future<bool> printWithAutoConnect(
    Uint8List bytes, {
    PrinterDevice? device,
  }) async {
    final targetDevice = device ?? savedPrinter;

    if (targetDevice == null) {
      throw PrinterException('Printer not selected');
    }

    try {
      // Connect
      final connected = await connect(targetDevice);
      if (!connected) {
        throw PrinterException('Failed to connect to the printer');
      }

      // Send data
      final success = await _printerService.send(bytes);

      // Always disconnect
      await disconnect();

      return success;
    } catch (e) {
      // Try to disconnect even on error
      try {
        await disconnect();
      } catch (_) {}
      rethrow;
    }
  }

  /// Print test line.
  Future<bool> printTestLine({PrinterDevice? device}) async {
    // Simple ESC/POS command: initialize + text + line feed + cut
    final bytes = Uint8List.fromList([
      0x1B, 0x40, // ESC @ - Initialize printer
      ...('Test Print - ${DateTime.now()}\n').codeUnits,
      0x0A, 0x0A, 0x0A, // Line feeds
      0x1D, 0x56, 0x00, // GS V 0 - Full cut
    ]);

    return printWithAutoConnect(bytes, device: device);
  }

  /// Test connection to the printer.
  Future<bool> testConnection(PrinterDevice device) async {
    try {
      final connected = await connect(device);
      if (connected) {
        await disconnect();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
