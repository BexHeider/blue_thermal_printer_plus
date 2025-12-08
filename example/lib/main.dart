import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:thermal_printer/bluetooth_device.dart';
import 'package:thermal_printer/thermal_printer.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Instancia de tu clase principal
  final ThermalPrinter bluetooth = ThermalPrinter();

  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;

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
      // Actualizar estado según los eventos de Kotlin
      switch (state) {
        case ThermalPrinter.connected:
          setState(() {
            _connected = true;
            print("bluetooth device state: connected");
          });
          break;
        case ThermalPrinter.disconnected:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnected");
          });
          break;
        case ThermalPrinter.disconnectRequested:
          setState(() {
            _connected = false;
            print("bluetooth device state: disconnect requested");
          });
          break;
        case ThermalPrinter.stateOff:
          setState(() {
            _connected = false;
            print("bluetooth state: off");
          });
          break;
        case ThermalPrinter.stateOn:
          setState(() {
            _connected = false;
            print("bluetooth state: on");
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
        appBar: AppBar(
          title: const Text('Thermal Printer Demo'),
        ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                    onPressed: () {
                      initPlatformState(); // Refrescar lista
                    },
                    child: const Text('Refrescar', style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _connected ? Colors.red : Colors.green),
                    onPressed: _connected ? _disconnect : _connect,
                    child: Text(
                      _connected ? 'Desconectar' : 'Conectar',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Botones de prueba (Solo visibles si está conectado)
              IgnorePointer(
                ignoring: !_connected,
                child: Opacity(
                  opacity: _connected ? 1.0 : 0.3, // Efecto visual deshabilitado
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: _printTestTicket,
                        child: const Text("Imprimir Ticket de Prueba"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                           await bluetooth.printQRcode("Hola Flutter", 200, 200, 1);
                           await bluetooth.paperCut();
                        },
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
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      for (var device in _devices) {
        items.add(DropdownMenuItem(
          value: device,
          child: Text(device.name ?? ""),
        ));
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
    } else {
      // Mostrar mensaje: No hay dispositivo seleccionado
      print('No device selected');
    }
  }

  void _disconnect() {
    bluetooth.disconnect();
    setState(() => _connected = false);
  }

  // --- LÓGICA DE IMPRESIÓN DE PRUEBA ---
  Future<void> _printTestTicket() async {
    // Verificar conexión primero
    if ((await bluetooth.isConnected) == true) {
      
      // 1. Encabezado
      bluetooth.printCustom("TIENDA FLUTTER", 3, 1); // Tamaño 3, Centrado
      bluetooth.printNewLine();
      bluetooth.printImage("path/to/image.png"); // Nota: Necesitas una imagen en assets
      bluetooth.printNewLine();
      
      // 2. Texto normal
      bluetooth.printCustom("Direccion: Calle Falsa 123", 1, 1);
      bluetooth.printCustom("Tel: 555-1234", 1, 1);
      bluetooth.printNewLine();

      // 3. Columnas (Left-Right)
      bluetooth.printLeftRight("Cant", "Precio", 1);
      bluetooth.printCustom("----------------", 1, 1);
      bluetooth.printLeftRight("Coca Cola x2", "\$5.00", 1);
      bluetooth.printLeftRight("Pizza", "\$10.00", 1);
      bluetooth.printNewLine();
      
      // 4. Totales
      bluetooth.printCustom("----------------", 1, 1);
      bluetooth.printLeftRight("TOTAL", "\$15.00", 2); // Tamaño 2 (Bold)
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      
      // 5. Pie de página
      bluetooth.printCustom("Gracias por su compra", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      
      // 6. Cortar papel
      bluetooth.paperCut();
    }
  }
}