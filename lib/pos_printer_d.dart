/// A clean Flutter plugin for POS thermal printers.
///
/// Supports Bluetooth, USB, and Network (TCP) connections.
///
/// ## Usage
///
/// ```dart
/// import 'package:pos_printer_d/pos_printer_d.dart';
///
/// // Get the printer service instance
/// final printerService = PrinterService.instance;
///
/// // Discover printers
/// printerService.discover(PrinterType.bluetooth).listen((device) {
///   print('Found: ${device.name}');
/// });
///
/// // Connect to a printer
/// await printerService.connect(device);
///
/// // Send data
/// await printerService.send(bytes);
///
/// // Disconnect
/// await printerService.disconnect();
/// ```
library pos_printer_d;

// Models
export 'src/models/printer_device.dart';
export 'src/models/printer_type.dart';
export 'src/models/connection_state.dart';
export 'src/models/connection_config.dart';

// Connectors (for advanced usage)
export 'src/connectors/printer_connector.dart';

// Main service
export 'src/printer_service.dart';
