import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final BlueThermalPrinterPlus bluetooth = BlueThermalPrinterPlus();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  PrinterProtocol _selectedProtocol = PrinterProtocol.escPos;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    bool? isConnected = await bluetooth.isConnected;
    List<BluetoothDevice> devices = [];
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      // Manejo de error
    }

    bluetooth.onStateChanged.listen((state) {
      switch (state) {
        case 1:
          setState(() {
            _connected = true;
          });
          break;
        case 0:
          setState(() {
            _connected = false;
          });
          break;
      }
    });

    if (!mounted) return;
    setState(() {
      _devices = devices;
    });

    if (isConnected == true) {
      setState(() {
        _connected = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Thermal Printer Demo')),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(width: 10),
                  const Text(
                    'Dispositivo:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 30),
                  Expanded(
                    child: DropdownButton<BluetoothDevice>(
                      items: _getDeviceItems(),
                      onChanged: (BluetoothDevice? value) {
                        setState(() => _device = value);
                      },
                      value: _device,
                      hint: const Text('Seleccionar impresora'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Dentro del ListView en tu build()
              const Text(
                'Protocolo de Impresión:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              DropdownButton<PrinterProtocol>(
                value: _selectedProtocol,
                items: PrinterProtocol.values.map((protocol) {
                  return DropdownMenuItem(
                    value: protocol,
                    child: Text(protocol.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedProtocol = value!);
                },
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                    ),
                    onPressed: () {
                      initPlatformState(); // Refrescar lista
                    },
                    child: const Text(
                      'Refrescar',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _connected ? Colors.red : Colors.green,
                    ),
                    onPressed: _connected ? _disconnect : _connect,
                    child: Text(
                      _connected ? 'Desconectar' : 'Conectar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              IgnorePointer(
                ignoring: !_connected,
                child: Opacity(
                  opacity: _connected ? 1.0 : 0.3,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          bool? connected = await bluetooth.isConnected;
                          if (connected == true) {
                            _printTestTicket();
                          }
                        },
                        child: const Text("Imprimir Ticket de Prueba"),
                      ),
                      ElevatedButton(
                        onPressed: () async {},
                        child: const Text("Imprimir QR"),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devices.isEmpty) {
      items.add(const DropdownMenuItem(child: Text('NONE')));
    } else {
      for (var device in _devices) {
        items.add(
          DropdownMenuItem(value: device, child: Text(device.name ?? "")),
        );
      }
    }
    return items;
  }

  void _connect() {
    if (_device != null) {
      bluetooth.isConnected.then((isConnected) {
        if (isConnected == false) {
          bluetooth.connect(_device!).catchError((error) {
            setState(() => _connected = false);
          });
          setState(() => _connected = true);
        }
      });
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  // --- LÓGICA DE IMPRESIÓN DE PRUEBA ---
  Future<void> _printTestTicket() async {
    print("Imprimiendo ticket de prueba");
    // Verificar conexión primero
    if ((await bluetooth.isConnected) == true) {
      // Creamos la lista de items (Independiente del lenguaje)
      List<PrintItem> receipt = [
        PrintItem.text("TIENDA FLUTTER", size: 2, align: 1),
        PrintItem.text("Calle Falsa 123", align: 1),
        PrintItem.text("Tel: 555-1234", align: 1),
        PrintItem(type: PrintItemType.newLine),

        PrintItem.text("PRODUCTOS", size: 1, align: 0),
        PrintItem.text("-------------------------------", align: 1),
        PrintItem.text("Coca Cola x2        \$5.00", align: 0),
        PrintItem.text("Pizza               \$10.00", align: 0),
        PrintItem.text("-------------------------------", align: 1),

        PrintItem.text("TOTAL: \$15.00", size: 2, align: 2),
        PrintItem(type: PrintItemType.newLine),
        PrintItem.text("Gracias por su compra", align: 1),

        PrintItem(type: PrintItemType.newLine),
        PrintItem(type: PrintItemType.paperCut),
      ];

      // Llamamos al método maestro del paquete
      await bluetooth.print(items: receipt, protocol: _selectedProtocol);
    }
  }
}
