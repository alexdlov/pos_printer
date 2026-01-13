import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:rxdart/rxdart.dart';

import '../models/printer_device.dart';
import '../models/printer_type.dart';
import '../models/connection_state.dart';
import '../models/connection_config.dart';
import '../platform/channels.dart';
import 'printer_connector.dart';

/// USB printer connector.
///
/// Supported on Android and Windows.
class UsbConnector implements PrinterConnector {
  UsbConnector._() {
    _initializeChannels();
  }

  static UsbConnector? _instance;

  /// Singleton instance.
  static UsbConnector get instance {
    _instance ??= UsbConnector._();
    return _instance!;
  }

  final _stateController =
      BehaviorSubject<ConnectionState>.seeded(ConnectionState.disconnected);
  PrinterDevice? _connectedDevice;

  void _initializeChannels() {
    if (Platform.isAndroid) {
      PrinterChannels.usbState.receiveBroadcastStream().listen((data) {
        if (data is int) {
          _updateState(_mapNativeState(data));
        }
      });
    }
  }

  ConnectionState _mapNativeState(int nativeState) {
    switch (nativeState) {
      case 0:
        return ConnectionState.disconnected;
      case 1:
        return ConnectionState.connecting;
      case 2:
        return ConnectionState.connected;
      default:
        return ConnectionState.disconnected;
    }
  }

  void _updateState(ConnectionState state) {
    _stateController.add(state);
    if (state == ConnectionState.disconnected) {
      _connectedDevice = null;
    }
  }

  @override
  Stream<ConnectionState> get stateStream => _stateController.stream;

  @override
  ConnectionState get currentState => _stateController.value;

  @override
  PrinterDevice? get connectedDevice => _connectedDevice;

  @override
  Stream<PrinterDevice> discover({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    if (!Platform.isAndroid && !Platform.isWindows) {
      throw const PrinterException('USB not supported on this platform');
    }

    try {
      final results = await PrinterChannels.method.invokeMethod<List<dynamic>>(
        PrinterMethods.getUsbList,
      );

      if (results == null) return;

      for (final result in results) {
        if (Platform.isAndroid) {
          final name =
              (result['product'] ?? result['name']) ?? 'Unknown USB Device';
          yield PrinterDevice.usb(
            name: name,
            vendorId: result['vendorId']?.toString() ?? '',
            productId: result['productId']?.toString() ?? '',
          );
        }

        if (Platform.isWindows) {
          yield PrinterDevice(
            name: result['name'] ?? 'Unknown',
            type: PrinterType.usb,
          );
        }
      }
    } catch (e) {
      throw PrinterException('Failed to discover USB devices',
          originalError: e);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    // USB discovery is synchronous, nothing to stop
  }

  @override
  Future<bool> connect(
    PrinterDevice device, {
    ConnectionConfig config = ConnectionConfig.defaultConfig,
  }) async {
    if (device.type != PrinterType.usb) {
      throw const PrinterException('Device is not a USB printer');
    }

    try {
      _updateState(ConnectionState.connecting);

      if (Platform.isAndroid) {
        if (device.vendorId == null || device.productId == null) {
          throw const PrinterException(
              'USB device missing vendorId or productId');
        }

        final params = {
          'vendor': int.parse(device.vendorId!),
          'product': int.parse(device.productId!),
        };

        final result = await PrinterChannels.method.invokeMethod<bool>(
          PrinterMethods.connectPrinter,
          params,
        );

        if (result == true) {
          _connectedDevice = device;
          _updateState(ConnectionState.connected);
          return true;
        }
      }

      if (Platform.isWindows) {
        final params = {'name': device.name};
        final result = await PrinterChannels.method.invokeMethod<int>(
          PrinterMethods.connectPrinter,
          params,
        );

        if (result == 1) {
          _connectedDevice = device;
          _updateState(ConnectionState.connected);
          return true;
        }
      }

      _updateState(ConnectionState.error);
      return false;
    } catch (e) {
      _updateState(ConnectionState.error);
      throw PrinterException('Failed to connect USB', originalError: e);
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      if (Platform.isWindows) {
        await PrinterChannels.method.invokeMethod(PrinterMethods.close);
      }

      _connectedDevice = null;
      _updateState(ConnectionState.disconnected);
      return true;
    } catch (e) {
      throw PrinterException('Failed to disconnect USB', originalError: e);
    }
  }

  @override
  Future<bool> send(Uint8List bytes) async {
    if (currentState != ConnectionState.connected) {
      throw const PrinterException('Not connected to USB printer');
    }

    try {
      if (Platform.isAndroid) {
        // For Android, the method channel requires a List<int>
        // Convert Uint8List to List<int> for method channel
        final params = {'bytes': bytes.toList()};
        final result = await PrinterChannels.method.invokeMethod<bool>(
          PrinterMethods.printBytes,
          params,
        );
        return result ?? false;
      }

      if (Platform.isWindows) {
        // For Windows, the method channel can accept Uint8List directly
        final params = {'bytes': bytes};
        final result = await PrinterChannels.method.invokeMethod<int>(
          PrinterMethods.printBytes,
          params,
        );
        return result == 1;
      }

      return false;
    } catch (e) {
      throw PrinterException('Failed to send USB data', originalError: e);
    }
  }

  @override
  void dispose() {
    _stateController.close();
  }
}
