import 'dart:async';
import 'dart:typed_data';

import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:pos_printer/pos_printer.dart';

void main() {
  runApp(const PrinterExampleApp());
}

class PrinterExampleApp extends StatelessWidget {
  const PrinterExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Printer Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const PrinterScreen(),
    );
  }
}

class PrinterScreen extends StatefulWidget {
  const PrinterScreen({super.key});

  @override
  State<PrinterScreen> createState() => _PrinterScreenState();
}

class _PrinterScreenState extends State<PrinterScreen> {
  final _printerService = PrinterService.instance;

  // State
  PrinterType _selectedType = PrinterType.bluetooth;
  List<PrinterDevice> _devices = [];
  PrinterDevice? _selectedDevice;
  bool _isScanning = false;
  String _status = 'Ready';

  // Network input
  final _ipController = TextEditingController(text: '192.168.1.100');
  final _portController = TextEditingController(text: '9100');

  StreamSubscription? _stateSubscription;

  @override
  void initState() {
    super.initState();
    _stateSubscription = _printerService.stateStream.listen((state) {
      setState(() {
        _status = state.displayName;
      });
    });
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  // ===== Actions =====

  Future<void> _startScan() async {
    if (!_printerService.isSupported(_selectedType)) {
      _showMessage(
          '${_selectedType.displayName} not supported on this platform');
      return;
    }

    setState(() {
      _isScanning = true;
      _devices = [];
      _status = 'Scanning...';
    });

    try {
      await for (final device in _printerService.discover(
        _selectedType,
        timeout: const Duration(seconds: 10),
      )) {
        setState(() {
          if (!_devices.any((d) => d.id == device.id)) {
            _devices.add(device);
          }
        });
      }
    } catch (e) {
      _showMessage('Scan error: $e');
    } finally {
      setState(() {
        _isScanning = false;
        _status = 'Scan complete. Found ${_devices.length} devices';
      });
    }
  }

  void _stopScan() {
    _printerService.stopDiscovery();
    setState(() {
      _isScanning = false;
      _status = 'Scan stopped';
    });
  }

  Future<void> _connect(PrinterDevice device) async {
    setState(() => _status = 'Connecting to ${device.name}...');

    try {
      final success = await _printerService.connect(
        device,
        config: const ConnectionConfig(
          timeout: Duration(seconds: 5),
          autoReconnect: true,
        ),
      );

      if (success) {
        setState(() {
          _selectedDevice = device;
          _status = 'Connected to ${device.name}';
        });
        _showMessage('Connected!');
      } else {
        _showMessage('Connection failed');
      }
    } catch (e) {
      _showMessage('Connection error: $e');
      setState(() => _status = 'Connection failed');
    }
  }

  Future<void> _connectToIp() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 9100;

    if (ip.isEmpty) {
      _showMessage('Please enter IP address');
      return;
    }

    setState(() => _status = 'Connecting to $ip:$port...');

    try {
      final success = await _printerService.connectToIp(ip, port: port);
      if (success) {
        setState(() {
          _selectedDevice = PrinterDevice.network(address: ip, port: port);
          _status = 'Connected to $ip:$port';
        });
        _showMessage('Connected!');
      } else {
        _showMessage('Connection failed');
      }
    } catch (e) {
      _showMessage('Connection error: $e');
    }
  }

  Future<void> _disconnect() async {
    await _printerService.disconnect();
    setState(() {
      _selectedDevice = null;
      _status = 'Disconnected';
    });
  }

  Future<void> _printTest() async {
    if (!_printerService.isConnected) {
      _showMessage('Not connected');
      return;
    }

    setState(() => _status = 'Printing...');

    try {
      // Generate ESC/POS receipt
      final bytes = await _generateTestReceipt();

      final success = await _printerService.send(bytes);

      if (success) {
        _showMessage('Print successful!');
        setState(() => _status = 'Print complete');
      } else {
        _showMessage('Print failed');
      }
    } catch (e) {
      _showMessage('Print error: $e');
      setState(() => _status = 'Print error');
    }
  }

  Future<Uint8List> _generateTestReceipt() async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    List<int> bytes = [];

    // Initialize printer
    bytes += generator.reset();

    // Header
    bytes += generator.text(
      'POS PRINTER TEST',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );

    bytes += generator.feed(1);

    // Divider
    bytes += generator.text('--------------------------------');

    // Info
    bytes += generator.text('Date: ${DateTime.now()}');
    bytes += generator.text('Device: ${_selectedDevice?.name ?? "Unknown"}');
    bytes += generator
        .text('Type: ${_selectedDevice?.type.displayName ?? "Unknown"}');

    bytes += generator.text('--------------------------------');

    // Items
    bytes += generator.row([
      PosColumn(text: 'Item', width: 6),
      PosColumn(
          text: 'Qty',
          width: 2,
          styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: 'Price',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Coffee', width: 6),
      PosColumn(
          text: '2', width: 2, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: '\$5.00',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.row([
      PosColumn(text: 'Sandwich', width: 6),
      PosColumn(
          text: '1', width: 2, styles: const PosStyles(align: PosAlign.center)),
      PosColumn(
          text: '\$8.50',
          width: 4,
          styles: const PosStyles(align: PosAlign.right)),
    ]);

    bytes += generator.text('--------------------------------');

    // Total
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: '', width: 2),
      PosColumn(
          text: '\$13.50',
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.feed(2);

    // Footer
    bytes += generator.text(
      'Thank you!',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(1);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // ===== UI =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS Printer Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Status bar
          _buildStatusBar(),

          // Type selector
          _buildTypeSelector(),

          // Network input (only for network type)
          if (_selectedType == PrinterType.network) _buildNetworkInput(),

          // Devices list
          Expanded(child: _buildDevicesList()),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    final isConnected = _printerService.isConnected;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: isConnected ? Colors.green.shade100 : Colors.grey.shade200,
      child: Row(
        children: [
          Icon(
            isConnected ? Icons.check_circle : Icons.info_outline,
            color: isConnected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _status,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color:
                    isConnected ? Colors.green.shade800 : Colors.grey.shade800,
              ),
            ),
          ),
          if (_selectedDevice != null)
            Chip(
              label: Text(_selectedDevice!.type.displayName),
              avatar: Text(_selectedDevice!.type.icon),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SegmentedButton<PrinterType>(
        segments: _printerService.supportedTypes.map((type) {
          return ButtonSegment(
            value: type,
            label: Text(type.displayName),
            icon: Text(type.icon),
          );
        }).toList(),
        selected: {_selectedType},
        onSelectionChanged: (selected) {
          setState(() {
            _selectedType = selected.first;
            _devices = [];
          });
        },
      ),
    );
  }

  Widget _buildNetworkInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '9100',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _printerService.isConnected ? null : _connectToIp,
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesList() {
    if (_isScanning && _devices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Scanning for devices...'),
          ],
        ),
      );
    }

    if (_devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.print, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Scan" to search for printers',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        final isSelected = _selectedDevice?.id == device.id;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSelected ? Colors.green : Colors.grey.shade300,
            child: Text(device.type.icon),
          ),
          title: Text(device.name),
          subtitle: Text(device.connectionInfo),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : ElevatedButton(
                  onPressed: () => _connect(device),
                  child: const Text('Connect'),
                ),
          selected: isSelected,
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          // Scan button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isScanning ? _stopScan : _startScan,
              icon: Icon(_isScanning ? Icons.stop : Icons.search),
              label: Text(_isScanning ? 'Stop' : 'Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isScanning ? Colors.orange : null,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Disconnect button
          if (_printerService.isConnected) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _disconnect,
                icon: const Icon(Icons.link_off),
                label: const Text('Disconnect'),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Print button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _printerService.isConnected ? _printTest : null,
              icon: const Icon(Icons.print),
              label: const Text('Print Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _printerService.isConnected ? Colors.green : null,
                foregroundColor:
                    _printerService.isConnected ? Colors.white : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
