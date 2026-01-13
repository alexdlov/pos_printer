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

/// Bluetooth printer connector.
///
/// Supports both Classic Bluetooth and BLE on Android and iOS.
class BluetoothConnector implements PrinterConnector {
  BluetoothConnector._() {
    _initializeChannels();
  }

  static BluetoothConnector? _instance;

  /// Singleton instance.
  static BluetoothConnector get instance {
    _instance ??= BluetoothConnector._();
    return _instance!;
  }

  final _stateController =
      BehaviorSubject<ConnectionState>.seeded(ConnectionState.disconnected);
  final _scanResultsController =
      BehaviorSubject<List<PrinterDevice>>.seeded([]);
  final _methodStreamController = StreamController<dynamic>.broadcast();

  StreamSubscription? _scanSubscription;
  PrinterDevice? _connectedDevice;

  void _initializeChannels() {
    if (Platform.isAndroid) {
      PrinterChannels.method.setMethodCallHandler((call) {
        _methodStreamController.add(call);
        return Future.value(null);
      });

      PrinterChannels.bluetoothState.receiveBroadcastStream().listen((data) {
        if (data is int) {
          _updateState(_mapNativeState(data));
        }
      });
    }

    if (Platform.isIOS) {
      PrinterChannels.iosMethod.setMethodCallHandler((call) {
        _methodStreamController.add(call);
        return Future.value(null);
      });

      PrinterChannels.iosState.receiveBroadcastStream().listen((data) {
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

  /// Whether to use BLE instead of Classic Bluetooth.
  bool useBle = false;

  @override
  Stream<PrinterDevice> discover({
    Duration timeout = const Duration(seconds: 10),
  }) async* {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw const PrinterException('Bluetooth not supported on this platform');
    }

    _scanResultsController.add([]);

    final devices = <String, PrinterDevice>{};
    final completer = Completer<void>();

    // Set timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    if (Platform.isAndroid) {
      final method = useBle
          ? PrinterMethods.getBluetoothLeList
          : PrinterMethods.getBluetoothList;

      await PrinterChannels.method.invokeMethod(method);

      _scanSubscription = _methodStreamController.stream
          .where((call) => call.method == 'ScanResult')
          .map((call) => call.arguments)
          .takeUntil(completer.future.asStream())
          .listen((data) {
        final device = PrinterDevice.bluetooth(
          name: data['name'] as String? ?? 'Unknown',
          address: data['address'] as String? ?? '',
          isBle: useBle,
        );

        if (!devices.containsKey(device.address)) {
          devices[device.address!] = device;
          _scanResultsController.add(devices.values.toList());
        }
      });

      await for (final device in _scanResultsController.stream
          .skip(1)
          .expand((list) => list)
          .distinct()
          .takeUntil(completer.future.asStream())) {
        yield device;
      }
    }

    if (Platform.isIOS) {
      await PrinterChannels.iosMethod.invokeMethod(PrinterMethods.startScan);

      _scanSubscription = _methodStreamController.stream
          .where((call) => call.method == 'ScanResult')
          .map((call) => call.arguments)
          .takeUntil(completer.future.asStream())
          .listen((data) {
        final device = PrinterDevice.bluetooth(
          name: data['name'] as String? ?? 'Unknown',
          address: data['address'] as String? ?? '',
          isBle: true, // iOS only supports BLE
        );

        if (!devices.containsKey(device.address)) {
          devices[device.address!] = device;
          _scanResultsController.add(devices.values.toList());
        }
      });

      await for (final device in _scanResultsController.stream
          .skip(1)
          .expand((list) => list)
          .distinct()
          .takeUntil(completer.future.asStream())) {
        yield device;
      }
    }

    await stopDiscovery();
  }

  @override
  Future<void> stopDiscovery() async {
    _scanSubscription?.cancel();
    _scanSubscription = null;

    if (Platform.isIOS) {
      await PrinterChannels.iosMethod.invokeMethod(PrinterMethods.stopScan);
    }
  }

  @override
  Future<bool> connect(
    PrinterDevice device, {
    ConnectionConfig config = ConnectionConfig.defaultConfig,
  }) async {
    if (device.type != PrinterType.bluetooth) {
      throw const PrinterException('Device is not a Bluetooth printer');
    }

    try {
      _updateState(ConnectionState.connecting);

      if (Platform.isAndroid) {
        final params = {
          'address': device.address,
          'isBle': device.isBle,
          'autoConnect': config.autoReconnect,
        };

        final result = await PrinterChannels.method.invokeMethod<bool>(
          PrinterMethods.startConnection,
          params,
        );

        if (result == true) {
          _connectedDevice = device;
          _updateState(ConnectionState.connected);
          return true;
        }
      }

      if (Platform.isIOS) {
        final params = {
          'name': device.name,
          'address': device.address,
        };

        await PrinterChannels.iosMethod.invokeMethod(
          PrinterMethods.connect,
          params,
        );

        _connectedDevice = device;
        // iOS state is updated via event channel
        return true;
      }

      _updateState(ConnectionState.error);
      return false;
    } catch (e) {
      _updateState(ConnectionState.error);
      throw PrinterException('Failed to connect', originalError: e);
    }
  }

  @override
  Future<bool> disconnect() async {
    try {
      if (Platform.isAndroid) {
        await PrinterChannels.method.invokeMethod(PrinterMethods.disconnect);
      }

      if (Platform.isIOS) {
        await PrinterChannels.iosMethod.invokeMethod(PrinterMethods.disconnect);
      }

      _connectedDevice = null;
      _updateState(ConnectionState.disconnected);
      return true;
    } catch (e) {
      throw PrinterException('Failed to disconnect', originalError: e);
    }
  }

  @override
  Future<bool> send(Uint8List bytes) async {
    if (currentState != ConnectionState.connected) {
      throw const PrinterException('Not connected to printer');
    }

    try {
      if (Platform.isAndroid) {
        final params = {'bytes': bytes.toList()};
        final result = await PrinterChannels.method.invokeMethod<bool>(
          PrinterMethods.sendDataByte,
          params,
        );
        return result ?? false;
      }

      if (Platform.isIOS) {
        final params = {
          'bytes': bytes.toList(),
          'length': bytes.length,
        };
        await PrinterChannels.iosMethod.invokeMethod(
          PrinterMethods.writeData,
          params,
        );
        return true;
      }

      return false;
    } catch (e) {
      throw PrinterException('Failed to send data', originalError: e);
    }
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _stateController.close();
    _scanResultsController.close();
    _methodStreamController.close();
  }
}
