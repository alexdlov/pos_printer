import 'dart:convert';

import 'package:pos_printer_d/pos_printer_d.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repository for saving printer settings.
class PrinterRepository {
  static const _printerKey = 'saved_printer';
  static const _defaultPort = 9100;

  final SharedPreferences _prefs;

  PrinterRepository(this._prefs);

  /// Save the selected printer.
  Future<void> savePrinter(PrinterDevice device) async {
    final json = jsonEncode(device.toJson());
    await _prefs.setString(_printerKey, json);
  }

  /// Get the saved printer.
  PrinterDevice? getSavedPrinter() {
    final json = _prefs.getString(_printerKey);
    if (json == null) return null;

    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return PrinterDevice.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Remove the saved printer.
  Future<void> removePrinter() async {
    await _prefs.remove(_printerKey);
  }

  /// Check if there is a saved printer.
  bool hasSavedPrinter() => _prefs.containsKey(_printerKey);

  /// Default port for network printers.
  int get defaultPort => _defaultPort;
}
