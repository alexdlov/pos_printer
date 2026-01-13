import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:network_info_plus/network_info_plus.dart';
import 'package:rxdart/rxdart.dart';

import '../models/printer_device.dart';
import '../models/printer_type.dart';
import '../models/connection_state.dart';
import '../models/connection_config.dart';
import 'printer_connector.dart';

/// Network/TCP printer connector.
///
/// Supported on all platforms. Uses standard TCP socket connections.
class TcpConnector implements PrinterConnector {
  TcpConnector._();

  static TcpConnector? _instance;

  /// Singleton instance.
  static TcpConnector get instance {
    _instance ??= TcpConnector._();
    return _instance!;
  }

  final _stateController =
      BehaviorSubject<ConnectionState>.seeded(ConnectionState.disconnected);

  Socket? _socket;
  PrinterDevice? _connectedDevice;
  bool _isDiscovering = false;

  @override
  Stream<ConnectionState> get stateStream => _stateController.stream;

  @override
  ConnectionState get currentState => _stateController.value;

  @override
  PrinterDevice? get connectedDevice => _connectedDevice;

  void _updateState(ConnectionState state) {
    _stateController.add(state);
    if (state == ConnectionState.disconnected) {
      _connectedDevice = null;
    }
  }

  @override
  Stream<PrinterDevice> discover({
    Duration timeout = const Duration(seconds: 10),
    int port = 9100,
  }) async* {
    _isDiscovering = true;

    try {
      // Get device IP to determine subnet
      String? deviceIp;

      if (Platform.isAndroid || Platform.isIOS) {
        deviceIp = await NetworkInfo().getWifiIP();
      }

      if (deviceIp == null) {
        throw PrinterException('Could not determine network subnet');
      }

      final subnet = deviceIp.substring(0, deviceIp.lastIndexOf('.'));
      final discovered = <String>{};

      // Scan subnet for devices listening on printer port
      for (int i = 1; i < 255 && _isDiscovering; i++) {
        final ip = '$subnet.$i';

        try {
          final socket = await Socket.connect(
            ip,
            port,
            timeout: const Duration(milliseconds: 100),
          );

          socket.destroy();

          if (!discovered.contains(ip)) {
            discovered.add(ip);
            yield PrinterDevice.network(address: ip, port: port);
          }
        } catch (_) {
          // Device not responding on this port, skip
        }
      }
    } catch (e) {
      if (e is PrinterException) rethrow;
      throw PrinterException('Network discovery failed', originalError: e);
    } finally {
      _isDiscovering = false;
    }
  }

  /// Discover printers on a specific IP range.
  Stream<PrinterDevice> discoverRange({
    required String subnet,
    int startIp = 1,
    int endIp = 254,
    int port = 9100,
    Duration timeout = const Duration(milliseconds: 200),
  }) async* {
    _isDiscovering = true;

    for (int i = startIp; i <= endIp && _isDiscovering; i++) {
      final ip = '$subnet.$i';

      try {
        final socket = await Socket.connect(ip, port, timeout: timeout);
        socket.destroy();
        yield PrinterDevice.network(address: ip, port: port);
      } catch (_) {
        // Device not responding
      }
    }

    _isDiscovering = false;
  }

  @override
  Future<void> stopDiscovery() async {
    _isDiscovering = false;
  }

  @override
  Future<bool> connect(
    PrinterDevice device, {
    ConnectionConfig config = ConnectionConfig.defaultConfig,
  }) async {
    if (device.type != PrinterType.network) {
      throw PrinterException('Device is not a network printer');
    }

    if (device.address == null) {
      throw PrinterException('Network printer address is required');
    }

    try {
      _updateState(ConnectionState.connecting);

      _socket = await Socket.connect(
        device.address!,
        device.port,
        timeout: config.timeout,
      );

      _connectedDevice = device;
      _updateState(ConnectionState.connected);

      // Listen for socket close
      _socket!.done.then((_) {
        _updateState(ConnectionState.disconnected);
        _socket = null;
      });

      return true;
    } catch (e) {
      _updateState(ConnectionState.error);
      throw PrinterException('Failed to connect to network printer',
          originalError: e);
    }
  }

  /// Connect directly to an IP address.
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

  @override
  Future<bool> disconnect() async {
    try {
      _socket?.destroy();
      _socket = null;
      _connectedDevice = null;
      _updateState(ConnectionState.disconnected);
      return true;
    } catch (e) {
      throw PrinterException('Failed to disconnect', originalError: e);
    }
  }

  @override
  Future<bool> send(Uint8List bytes) async {
    if (_socket == null || currentState != ConnectionState.connected) {
      throw PrinterException('Not connected to network printer');
    }

    try {
      _socket!.add(bytes);
      await _socket!.flush();
      return true;
    } catch (e) {
      _updateState(ConnectionState.error);
      throw PrinterException('Failed to send data', originalError: e);
    }
  }

  /// Send data and then close connection (one-shot print).
  Future<bool> sendAndDisconnect(Uint8List bytes) async {
    final result = await send(bytes);
    await disconnect();
    return result;
  }

  @override
  void dispose() {
    _socket?.destroy();
    _stateController.close();
  }
}
