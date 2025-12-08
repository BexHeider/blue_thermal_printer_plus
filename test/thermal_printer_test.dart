import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thermal_printer/bluetooth_device.dart';
// Asegúrate de que el import coincida con el nombre de tu proyecto en pubspec.yaml
import 'package:thermal_printer/thermal_printer.dart';

void main() {
  // Aseguramos que el entorno de test de Flutter esté inicializado
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Esta es la instancia de tu clase principal
  late ThermalPrinter printer;
  
  // Definimos el canal exactamente como está en tu código Dart ('blue_thermal_printer/methods')
  const MethodChannel channel = MethodChannel('thermal_printer/methods');

  // Lista para guardar las llamadas que hace el plugin (para verificar qué envió)
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    printer = ThermalPrinter();
    log.clear();

    // INTERCEPTAMOS las llamadas al canal nativo (Mocking)
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        // Guardamos la llamada para verificarla luego
        log.add(methodCall);

        // Simulamos respuestas nativas según el método invocado
        switch (methodCall.method) {
          case 'isAvailable':
            return true;
          case 'isConnected':
            return false;
          case 'getBondedDevices':
            return [
              {'name': 'Impresora Test', 'address': 'AA:BB:CC:DD:EE:FF', 'type': 0},
              {'name': 'Impresora 2', 'address': '00:11:22:33:44:55', 'type': 1}
            ];
          case 'connect':
            return true;
          case 'printCustom':
            return true;
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    // Limpiamos el mock al finalizar cada test
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('isAvailable retorna true', () async {
    expect(await printer.isAvailable, true);
    // Verificamos que se llamó al método correcto
    expect(log, <Matcher>[isMethodCall('isAvailable', arguments: null)]);
  });

  test('getBondedDevices devuelve una lista de BluetoothDevice', () async {
    final devices = await printer.getBondedDevices();
    
    expect(devices.length, 2);
    expect(devices.first.name, 'Impresora Test');
    expect(devices.first.address, 'AA:BB:CC:DD:EE:FF');
    
    expect(log, <Matcher>[isMethodCall('getBondedDevices', arguments: null)]);
  });

  test('connect envía la dirección correcta', () async {
    final device = BluetoothDevice('Impresora Test', 'AA:BB:CC:DD:EE:FF');
    await printer.connect(device);

    expect(log, <Matcher>[
      isMethodCall('connect', arguments: {'address': 'AA:BB:CC:DD:EE:FF'})
    ]);
  });

  test('printCustom envía los argumentos correctos', () async {
    await printer.printCustom("Hola Mundo", 1, 1);

    expect(log, <Matcher>[
      isMethodCall('printCustom', arguments: {
        'message': 'Hola Mundo',
        'size': 1,
        'align': 1,
        'charset': 'UTF-8' // Valor por defecto
      })
    ]);
  });
}