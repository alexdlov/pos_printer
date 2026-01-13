import 'package:flutter/services.dart';

/// Platform method channels for native communication.
class PrinterChannels {
  PrinterChannels._();

  /// Main method channel for printer operations.
  static const MethodChannel method = MethodChannel('com.example.pos_printer');

  /// Event channel for Bluetooth connection state.
  static const EventChannel bluetoothState =
      EventChannel('com.example.pos_printer/bt_state');

  /// Event channel for USB connection state.
  static const EventChannel usbState =
      EventChannel('com.example.pos_printer/usb_state');

  /// iOS-specific method channel.
  static const MethodChannel iosMethod = MethodChannel('pos_printer/methods');

  /// iOS-specific state channel.
  static const EventChannel iosState = EventChannel('pos_printer/state');
}

/// Native method names used in platform communication.
class PrinterMethods {
  PrinterMethods._();

  // Bluetooth methods
  static const String getBluetoothList = 'getBluetoothList';
  static const String getBluetoothLeList = 'getBluetoothLeList';
  static const String startConnection = 'onStartConnection';
  static const String disconnect = 'disconnect';
  static const String sendDataByte = 'sendDataByte';

  // USB methods
  static const String getUsbList = 'getList';
  static const String connectPrinter = 'connectPrinter';
  static const String printBytes = 'printBytes';
  static const String close = 'close';

  // iOS methods
  static const String startScan = 'startScan';
  static const String stopScan = 'stopScan';
  static const String connect = 'connect';
  static const String writeData = 'writeData';
}
