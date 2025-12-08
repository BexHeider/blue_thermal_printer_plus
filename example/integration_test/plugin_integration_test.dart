import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
// Asegúrate de importar tu archivo correcto
import 'package:thermal_printer/thermal_printer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Verificar si el Bluetooth está disponible', (WidgetTester tester) async {
    // 1. Instanciar tu clase real
    final ThermalPrinter plugin = ThermalPrinter();
    
    // 2. Llamar a un método que sí existe
    final bool? isAvailable = await plugin.isAvailable;
    
    // 3. Verificar que no sea null (en un emulador puede ser false, en físico true)
    expect(isAvailable, isNotNull);
  });
}