import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart';

void main() {
  // Aseguramos que el entorno de test de Flutter esté inicializado
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  // Esta es la instancia de tu clase principal
  late BlueThermalPrinterPlus printer;

  // Definimos el canal exactamente como está en tu código Dart ('blue_blue_thermal_printer_plus/methods')
  const MethodChannel channel = MethodChannel(
    'blue_thermal_printer_plus/methods',
  );

  // Lista para guardar las llamadas que hace el plugin (para verificar qué envió)
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    printer = BlueThermalPrinterPlus();
    log.clear();

    // INTERCEPTAMOS las llamadas al canal nativo (Mocking)
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      MethodCall methodCall,
    ) async {
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
            {
              'name': 'Impresora Test',
              'address': 'AA:BB:CC:DD:EE:FF',
              'type': 0,
            },
            {'name': 'Impresora 2', 'address': '00:11:22:33:44:55', 'type': 1},
          ];
        case 'connect':
          return true;
        case 'writeBytes':
          return true;
        default:
          return null;
      }
    });
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
      isMethodCall('connect', arguments: {'address': 'AA:BB:CC:DD:EE:FF'}),
    ]);
  });

  bool containsSeq(List<int> data, List<int> seq) {
    for (var i = 0; i <= data.length - seq.length; i++) {
      var ok = true;
      for (var j = 0; j < seq.length; j++) {
        if (data[i + j] != seq[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return true;
    }
    return false;
  }

  Uint8List sentBytes() =>
      (log.single.arguments as Map)['message'] as Uint8List;

  test('print ESC/POS envía el texto con writeBytes', () async {
    await printer.print(
      items: [PrintItem.text('Hola')],
      protocol: PrinterProtocol.escPos,
    );

    expect(log.single.method, 'writeBytes');
    final bytes = sentBytes();
    expect(containsSeq(bytes, [0x1B, 0x40]), isTrue); // ESC @
    expect(containsSeq(bytes, 'Hola'.codeUnits), isTrue);
  });

  test('print ESC/POS imagen usa GS v 0 con el ancho del papel', () async {
    await printer.print(
      items: [PrintItem.image(Uint8List(48 * 2))],
      protocol: PrinterProtocol.escPos,
      widthDots: 384,
    );

    // 384 dots = 48 bytes por fila; 96 bytes = 2 filas.
    expect(
      containsSeq(sentBytes(), [0x1D, 0x76, 0x30, 0x00, 48, 0, 2, 0]),
      isTrue,
    );
  });

  test('print ZPL envía una etiqueta ^XA ... ^XZ', () async {
    await printer.print(
      items: [
        PrintItem.text('Hola'),
        PrintItem(type: PrintItemType.paperCut),
      ],
      protocol: PrinterProtocol.zpl,
    );

    final text = String.fromCharCodes(sentBytes());
    expect(text, startsWith('^XA'));
    expect(text, contains('Hola'));
    expect(text, endsWith('^XZ'));
  });
}
