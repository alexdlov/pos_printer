import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pos_printer_d/pos_printer_d.dart';

/// Printer operation status.
enum PrinterStatus { idle, connecting, printing, error, success }

/// Status indicator widget.
class PrinterStatusBanner extends StatelessWidget {
  const PrinterStatusBanner({
    super.key,
    required this.status,
    this.errorMessage,
  });

  final PrinterStatus status;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final (icon, text, bgColor, fgColor) = switch (status) {
      PrinterStatus.idle => (
          Icons.print_outlined,
          'Status',
          colorScheme.surfaceContainerHighest,
          colorScheme.onSurface.withAlpha(180),
        ),
      PrinterStatus.connecting => (
          Icons.sync,
          'Status: ...',
          colorScheme.primaryContainer,
          colorScheme.primary,
        ),
      PrinterStatus.printing => (
          Icons.print,
          'Status: ...',
          colorScheme.primaryContainer,
          colorScheme.primary,
        ),
      PrinterStatus.success => (
          Icons.check_circle,
          'Connected',
          Colors.green.withAlpha(40),
          Colors.green.shade700,
        ),
      PrinterStatus.error => (
          Icons.error_outline,
          errorMessage ?? 'Error',
          colorScheme.errorContainer,
          colorScheme.onError,
        ),
    };

    final isLoading =
        status == PrinterStatus.connecting || status == PrinterStatus.printing;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: fgColor.withAlpha(77)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              width: 28.0,
              height: 28.0,
              child: CircularProgressIndicator(strokeWidth: 2, color: fgColor),
            )
          else
            Icon(icon, color: fgColor, size: 28.0),
          SizedBox(width: 12.0),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 16.0,
                ),
          ),
        ],
      ),
    );
  }
}

/// Saved printer card with actions.
class SavedPrinterTile extends StatelessWidget {
  const SavedPrinterTile({
    super.key,
    required this.device,
    required this.onDelete,
    required this.onTestPrint,
    this.isLoading = false,
  });

  final PrinterDevice device;
  final VoidCallback onDelete;
  final VoidCallback onTestPrint;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: colorScheme.primary.withAlpha(50)),
      ),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle,
                    color: colorScheme.primary, size: 24.0),
                SizedBox(width: 10.0),
                Text(
                  'Connected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 16.0,
                      ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                _PrinterIcon(type: device.type, isBle: device.isBle),
                SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 18.0),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        device.connectionInfo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withAlpha(153),
                              fontSize: 14.0,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.0),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      padding:
                          EdgeInsets.symmetric(vertical: 14.0, horizontal: 5.0),
                    ),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13.0,
                            color: colorScheme.error,
                          ),
                    ),
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: isLoading ? null : onTestPrint,
                    style: FilledButton.styleFrom(
                      padding:
                          EdgeInsets.symmetric(vertical: 14.0, horizontal: 5.0),
                    ),
                    icon: isLoading
                        ? const _SmallLoader()
                        : Icon(Icons.print, size: 24.0),
                    label: Text('Print Test Page',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 13.0,
                              color: Colors.white,
                            )),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Device list item.
class PrinterDeviceTile extends StatelessWidget {
  const PrinterDeviceTile({
    super.key,
    required this.device,
    required this.isSelected,
    required this.isSaved,
    required this.onTap,
  });

  final PrinterDevice device;
  final bool isSelected;
  final bool isSaved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.only(bottom: 12.0),
      elevation: isSelected ? 2 : 0,
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest.withAlpha(128),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withAlpha(51),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        leading: _PrinterIcon(
          type: device.type,
          isBle: device.isBle,
          isSelected: isSelected,
        ),
        title: Text(
          device.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 16.0),
        ),
        subtitle: Text(device.connectionInfo, style: TextStyle(fontSize: 14.0)),
        trailing: isSaved
            ? Chip(
                label: Text('Connected', style: TextStyle(fontSize: 12.0)),
                visualDensity: VisualDensity.compact,
              )
            : isSelected
                ? Icon(Icons.check_circle,
                    color: colorScheme.primary, size: 28.0)
                : Icon(Icons.chevron_right, size: 28.0),
      ),
    );
  }
}

/// Network printer IP input.
class NetworkPrinterForm extends StatefulWidget {
  const NetworkPrinterForm({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
  });

  final void Function(PrinterDevice device) onSubmit;
  final bool isLoading;

  @override
  State<NetworkPrinterForm> createState() => _NetworkPrinterFormState();
}

class _NetworkPrinterFormState extends State<NetworkPrinterForm> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '9100');

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _submit() {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) return;

    final port = int.tryParse(_portController.text.trim()) ?? 9100;
    widget.onSubmit(PrinterDevice.network(address: ip, port: port));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _ipController,
                enabled: !widget.isLoading,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16.0),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: 'IP',
                  labelStyle: TextStyle(fontSize: 14.0),
                  hintText: '192.168.1.100',
                  hintStyle: TextStyle(fontSize: 14.0),
                ),
              ),
            ),
            SizedBox(width: 12.0),
            SizedBox(
              width: 90.0,
              child: TextField(
                controller: _portController,
                enabled: !widget.isLoading,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16.0),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Port',
                  labelStyle: TextStyle(fontSize: 14.0),
                ),
              ),
            ),
            SizedBox(width: 12.0),
            IconButton.filled(
              onPressed: widget.isLoading ? null : _submit,
              style: IconButton.styleFrom(
                minimumSize: Size(56.0, 56.0),
              ),
              icon: widget.isLoading
                  ? const _SmallLoader()
                  : Icon(Icons.add, size: 28.0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Printer type icon.
class _PrinterIcon extends StatelessWidget {
  const _PrinterIcon({
    required this.type,
    this.isBle = false,
    this.isSelected = false,
  });

  final PrinterType type;
  final bool isBle;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = switch (type) {
      PrinterType.bluetooth =>
        isBle ? Icons.bluetooth : Icons.bluetooth_connected,
      PrinterType.usb => Icons.usb,
      PrinterType.network => Icons.wifi,
    };

    return Container(
      width: 52.0,
      height: 52.0,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Icon(
        icon,
        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
        size: 28.0,
      ),
    );
  }
}

/// Small loading indicator.
class _SmallLoader extends StatelessWidget {
  const _SmallLoader();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.0,
      height: 24.0,
      child: const CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
