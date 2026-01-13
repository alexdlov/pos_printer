import 'package:flutter/material.dart';
import 'package:pos_printer_d/pos_printer_d.dart';
import 'package:pos_printer_example/printer/screen/printer_setting_screen.dart';
import 'package:pos_printer_example/printer/service/printer_local_service.dart';
import 'package:pos_printer_example/printer/service/printer_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dependencies
  final prefs = await SharedPreferences.getInstance();
  final repository = PrinterRepository(prefs);
  final printerService = PrinterService.instance;
  final localService = PrinterLocalService(
    printerService: printerService,
    repository: repository,
  );

  runApp(PrinterExampleApp(printerService: localService));
}

/// Provider for PrinterLocalService
class PrinterServiceProvider extends InheritedWidget {
  final PrinterLocalService service;

  const PrinterServiceProvider({
    super.key,
    required this.service,
    required super.child,
  });

  static PrinterLocalService of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<PrinterServiceProvider>();
    assert(provider != null, 'No PrinterServiceProvider found in context');
    return provider!.service;
  }

  @override
  bool updateShouldNotify(PrinterServiceProvider oldWidget) =>
      service != oldWidget.service;
}

class PrinterExampleApp extends StatelessWidget {
  final PrinterLocalService printerService;

  const PrinterExampleApp({super.key, required this.printerService});

  @override
  Widget build(BuildContext context) {
    return PrinterServiceProvider(
      service: printerService,
      child: MaterialApp(
        title: 'POS Printer Example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 32, 37, 28)),
          useMaterial3: true,
        ),
        home: const PrinterSettingScreen(),
      ),
    );
  }
}
