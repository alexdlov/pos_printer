import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pos_printer_d/pos_printer_d.dart';
import 'package:pos_printer_example/common/widgets/scafold_message/scf_message.dart';
import 'package:pos_printer_example/main.dart';

import '../service/printer_local_service.dart';
import '../widgets/printer_widgets.dart';

/// Printer settings screen.
/// Allows user to scan, select, save and test print to printers.
/// Supports USB, Bluetooth and Network printers.
/// Uses [PrinterLocalService] for printer operations.
/// Selected printer is saved locally for future use (not connected yet).
/// Try printing a test page to verify connection.
class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  late final PrinterLocalService _service;

  PrinterType _type = PrinterType.usb;
  final List<PrinterDevice> _devices = [];
  PrinterDevice? _selected;
  PrinterDevice? _saved;

  bool _scanning = false;
  bool _printing = false;
  PrinterStatus _status = PrinterStatus.idle;
  String? _error;

  StreamSubscription<PrinterDevice>? _sub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _service = PrinterServiceProvider.of(context);
    _saved = _service.savedPrinter;
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.disconnect();
    super.dispose();
  }

  void _scan() {
    if (_scanning) return;
    setState(() {
      _scanning = true;
      _devices.clear();
      _selected = null;
      _status = PrinterStatus.idle;
    });

    _sub?.cancel();
    _sub = _service.discover(_type).listen(
      (d) {
        if (!_devices.any((e) => e.address == d.address)) {
          setState(() => _devices.add(d));
        }
      },
      onError: (e) => setState(() {
        _status = PrinterStatus.error;
        _error = e.toString();
        _scanning = false;
      }),
      onDone: () => setState(() => _scanning = false),
    );
  }

  void _stopScan() {
    _sub?.cancel();
    _service.stopDiscovery();
    setState(() => _scanning = false);
  }

  Future<void> _save() async {
    if (_selected == null) return;
    await _service.savePrinter(_selected!);
    setState(() => _saved = _selected);
    if (mounted) {
      ScfMessage.show(
        context,
        message: '${_selected!.name} saved',
        type: ScfMessageType.success,
      );
    }
  }

  Future<void> _delete() async {
    await _service.removePrinter();
    setState(() => _saved = null);
  }

  Future<void> _testPrint([PrinterDevice? device]) async {
    final target = device ?? _saved;
    if (target == null) return;

    setState(() {
      _printing = true;
      _status = PrinterStatus.printing;
    });

    try {
      final ok =
          await _service.printWithAutoConnect(_testData(), device: target);
      setState(
          () => _status = ok ? PrinterStatus.success : PrinterStatus.error);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _status = PrinterStatus.idle);
      });
    } catch (e) {
      setState(() {
        _status = PrinterStatus.error;
        _error = e.toString();
      });
    } finally {
      setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Printer Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: ListView(
        padding: EdgeInsets.all(24.0),
        children: [
          // Status
          PrinterStatusBanner(status: _status, errorMessage: _error),
          SizedBox(height: 24.0),

          // Saved printer
          if (_saved != null) ...[
            SavedPrinterTile(
              device: _saved!,
              onDelete: _delete,
              onTestPrint: () async {
                try {
                  await _testPrint(_saved);
                } catch (e, s) {
                  debugPrint('Test print callback error: $e\n$s');
                }
              },
              isLoading: _printing,
            ),
            SizedBox(height: 32.0),
            Center(
              child: Text(
                '— or —',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            SizedBox(height: 24.0),
          ],

          // Type selector
          _buildTypeSelector(),
          SizedBox(height: 24.0),

          // Scan button
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _scanning ? _stopScan : _scan,
                  style: FilledButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 7.0),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    iconColor: Colors.white,
                  ),
                  icon: _scanning
                      ? SizedBox(
                          width: 24.0,
                          height: 24.0,
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.search,
                          size: 28.0,
                        ),
                  label: Text(
                    _scanning ? 'Cancel' : 'Scan for Devices',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 13.0, color: Colors.white),
                  ),
                ),
              ),
              if (_selected != null) ...[
                SizedBox(width: 16.0),
                FilledButton.icon(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                  ),
                  icon: Icon(Icons.save, size: 28.0),
                  label: Text(
                    'Save',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 24.0),

          // Network input
          if (_type == PrinterType.network) ...[
            NetworkPrinterForm(
              onSubmit: (d) => setState(() {
                _selected = d;
                if (!_devices.any((e) => e.address == d.address)) {
                  _devices.add(d);
                }
              }),
            ),
            SizedBox(height: 24.0),
          ],

          // Device list
          Text('Choose Device',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontSize: 18.0)),
          SizedBox(height: 12.0),

          if (_scanning && _devices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: const CircularProgressIndicator(),
              ),
            )
          else if (_devices.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(48.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.print_disabled,
                      size: 64.0,
                      color:
                          Theme.of(context).colorScheme.onSurface.withAlpha(77),
                    ),
                    SizedBox(height: 12.0),
                    Text(
                      'No Device Connected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withAlpha(128),
                            fontSize: 16.0,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...List.generate(_devices.length, (i) {
              final d = _devices[i];
              return PrinterDeviceTile(
                device: d,
                isSelected: _selected == d,
                isSaved: _saved?.address == d.address,
                onTap: () => setState(() => _selected = d),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SegmentedButton<PrinterType>(
      style: ButtonStyle(
        iconSize: WidgetStatePropertyAll(26.0),
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        ),
        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.secondary;
          }
          return Theme.of(context).colorScheme.surface;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.selected)) {
            return Theme.of(context).colorScheme.onSecondary;
          }
          return Theme.of(context).colorScheme.onSurface;
        }),
      ),
      segments: [
        ButtonSegment(value: PrinterType.usb, icon: Icon(Icons.usb)),
        ButtonSegment(
            value: PrinterType.bluetooth, icon: Icon(Icons.bluetooth)),
        ButtonSegment(value: PrinterType.network, icon: Icon(Icons.wifi)),
      ],
      selected: {_type},
      onSelectionChanged: (s) {
        _stopScan();
        setState(() {
          _type = s.first;
          _devices.clear();
          _selected = null;
        });
      },
    );
  }

  Uint8List _testData() {
    return Uint8List.fromList([
      0x1B, 0x40, // ESC @ - init
      0x1B, 0x61, 0x01, // ESC a 1 - center
      ...'=== TEST ===\n'.codeUnits,
      ...'Printer OK!\n'.codeUnits,
      ...'============\n'.codeUnits,
      0x0A, 0x0A, 0x0A, // LF
      0x1D, 0x56, 0x00, // GS V 0 - cut
    ]);
  }
}
