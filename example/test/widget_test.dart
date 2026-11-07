import 'package:flutter_test/flutter_test.dart';

import 'package:blue_thermal_printer_plus_example/main.dart';

void main() {
  testWidgets('Muestra los medios de conexión y las acciones', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Bluetooth'), findsOneWidget);
    expect(find.text('WiFi'), findsOneWidget);
    expect(find.text('Conectar'), findsOneWidget);
    expect(find.text('Imagen PNG'), findsOneWidget);
  });
}
