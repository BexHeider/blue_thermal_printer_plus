import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Asegúrate de importar tu archivo correcto
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Verificar si el Bluetooth está disponible', (WidgetTester tester) async {
    // 1. Instanciar tu clase real
    final BlueThermalPrinterPlus plugin = BlueThermalPrinterPlus();
    
    // 2. Llamar a un método que sí existe
    final bool? isAvailable = await plugin.isAvailable;
    
    // 3. Verificar que no sea null (en un emulador puede ser false, en físico true)
    expect(isAvailable, isNotNull);
  });
}