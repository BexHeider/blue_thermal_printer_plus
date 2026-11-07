import 'dart:io' show Platform;
import 'dart:ui' as ui;

import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

enum Medium { bluetooth, network, usb }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: ThemeData(colorSchemeSeed: Colors.deepOrange, useMaterial3: true),
        home: const DemoPage(),
      );
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  final printer = BlueThermalPrinterPlus();

  Medium _medium = Medium.bluetooth;
  PrinterProtocol _protocol = PrinterProtocol.escPos;
  PaperSize _paper = PaperSize.mm58;

  List<BluetoothDevice> _bonded = [];
  List<UsbPrinterDevice> _usb = [];
  BluetoothDevice? _btDevice;
  UsbPrinterDevice? _usbDevice;
  final _host = TextEditingController(text: '192.168.1.50');
  final _port = TextEditingController(text: '9100');

  bool _connected = false;
  bool _busy = false;

  int get _widthDots => switch (_paper) {
        PaperSize.mm58 => 384,
        PaperSize.mm80 => 576,
        PaperSize.mm110 => 832,
      };

  @override
  void initState() {
    super.initState();
    _refresh();
    // Cambios de Bluetooth (solo aplica a la conexión Bluetooth).
    printer.onStateChanged.listen((_) async {
      final c = await printer.isConnected ?? false;
      if (mounted) setState(() => _connected = c);
    }, onError: (_) {});
  }

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  void _toast(String text) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(text)));

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _toast('Error: $e');
    } finally {
      final c = await printer.isConnected ?? false;
      if (mounted) {
        setState(() {
          _busy = false;
          _connected = c;
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      final bonded = await printer.getBondedDevices();
      if (mounted) setState(() => _bonded = bonded);
    } catch (_) {
      // Sin permiso o Bluetooth apagado: se puede usar red o USB igualmente.
    }
    try {
      final usb = await printer.getUsbDevices(); // vacío fuera de Android
      if (mounted) setState(() => _usb = usb);
    } catch (_) {}
  }

  Future<void> _connect() => _run(() async {
        switch (_medium) {
          case Medium.bluetooth:
            if (_btDevice == null) return _toast('Elige una impresora');
            await printer.connect(_btDevice!);
          case Medium.network:
            await printer.connectNetwork(
              _host.text.trim(),
              port: int.tryParse(_port.text.trim()) ?? 9100,
            );
          case Medium.usb:
            if (_usbDevice == null) return _toast('Elige un dispositivo USB');
            await printer.connectUsb(_usbDevice!); // pide permiso al usuario
        }
      });

  Future<void> _disconnect() => _run(() async => printer.disconnect());

  Future<void> _print(List<PrintItem> items) => _run(() => printer.print(
        items: items,
        protocol: _protocol,
        widthDots: _widthDots,
      ));

  // --- Contenido de prueba ---

  List<PrintItem> get _ticket => [
        PrintItem(type: PrintItemType.newLine),
        PrintItem.text('TIENDA FLUTTER', size: 1, align: 1),
        PrintItem.text('Calle Falsa 123', align: 1),
        PrintItem(type: PrintItemType.newLine),
        PrintItem.text('Coca Cola x2        \$5.00'),
        PrintItem.text('Pizza               \$10.00'),
        PrintItem.text('TOTAL: \$15.00', size: 1),
        PrintItem(type: PrintItemType.newLine),
        PrintItem.text('Gracias por su compra', align: 1),
        PrintItem(type: PrintItemType.newLine),
        PrintItem(type: PrintItemType.paperCut),
      ];

  List<PrintItem> get _qr => [
        PrintItem(type: PrintItemType.newLine),
        PrintItem(type: PrintItemType.qrCode, text: 'https://flutter.dev'),
        PrintItem(type: PrintItemType.newLine),
        PrintItem(type: PrintItemType.paperCut),
      ];

  /// Genera un PNG de prueba. En una app real sería el contenido de un
  /// archivo (`File(path).readAsBytes()`): el paquete lo ajusta al papel.
  Future<Uint8List> _samplePng() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const w = 320.0, h = 160.0;
    canvas.drawRect(const Rect.fromLTWH(0, 0, w, h), Paint()..color = Colors.white);
    final gradient = ui.Gradient.linear(
        Offset.zero, const Offset(w, h), [Colors.black, Colors.white]);
    canvas.drawCircle(const Offset(80, 80), 60, Paint()..shader = gradient);
    canvas.drawRect(const Rect.fromLTWH(170, 30, 120, 100),
        Paint()..color = Colors.black54);
    final tp = TextPainter(
      text: const TextSpan(
          text: 'PNG', style: TextStyle(color: Colors.white, fontSize: 40)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, const Offset(190, 60));
    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  Future<void> _printImage() async {
    final png = await _samplePng();
    await _print([
      PrintItem(type: PrintItemType.newLine),
      PrintItem.imageFile(png), // centrada por defecto
      PrintItem(type: PrintItemType.newLine),
      PrintItem(type: PrintItemType.paperCut),
    ]);
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('blue_thermal_printer_plus')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<Medium>(
            showSelectedIcon: false,
            segments: [
              const ButtonSegment(
                  value: Medium.bluetooth, label: Text('Bluetooth')),
              const ButtonSegment(value: Medium.network, label: Text('WiFi')),
              if (Platform.isAndroid)
                const ButtonSegment(value: Medium.usb, label: Text('USB')),
            ],
            selected: {_medium},
            onSelectionChanged: (s) => setState(() => _medium = s.first),
          ),
          const SizedBox(height: 12),
          _mediumForm(),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: DropdownButtonFormField<PrinterProtocol>(
                initialValue: _protocol,
                decoration: const InputDecoration(labelText: 'Protocolo'),
                items: [
                  for (final p in PrinterProtocol.values)
                    DropdownMenuItem(value: p, child: Text(p.name.toUpperCase())),
                ],
                onChanged: (v) => setState(() => _protocol = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<PaperSize>(
                initialValue: _paper,
                decoration: const InputDecoration(labelText: 'Papel'),
                items: const [
                  DropdownMenuItem(value: PaperSize.mm58, child: Text('58 mm')),
                  DropdownMenuItem(value: PaperSize.mm80, child: Text('80 mm')),
                  DropdownMenuItem(value: PaperSize.mm110, child: Text('110 mm')),
                ],
                onChanged: (v) => setState(() => _paper = v!),
              ),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : (_connected ? _disconnect : _connect),
                child: Text(_connected
                    ? 'Desconectar${printer.activeTransportLabel != null ? ' (${printer.activeTransportLabel})' : ''}'
                    : 'Conectar'),
              ),
            ),
            IconButton(
              tooltip: 'Buscar de nuevo',
              onPressed: _busy ? null : _refresh,
              icon: const Icon(Icons.refresh),
            ),
          ]),
          const SizedBox(height: 24),
          const Text('Imprimir', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            FilledButton.tonal(
                onPressed: _connected && !_busy ? () => _print(_ticket) : null,
                child: const Text('Ticket')),
            FilledButton.tonal(
                onPressed: _connected && !_busy ? () => _print(_qr) : null,
                child: const Text('QR')),
            FilledButton.tonal(
                onPressed: _connected && !_busy ? _printImage : null,
                child: const Text('Imagen PNG')),
          ]),
          if (_busy)
            const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator()),
        ],
      ),
    );
  }

  Widget _mediumForm() {
    switch (_medium) {
      case Medium.bluetooth:
        return DropdownButtonFormField<BluetoothDevice>(
          initialValue: _btDevice,
          decoration: const InputDecoration(labelText: 'Impresora vinculada'),
          items: [
            for (final d in _bonded)
              DropdownMenuItem(value: d, child: Text(d.name ?? d.address ?? '')),
          ],
          onChanged: (v) => setState(() => _btDevice = v),
        );
      case Medium.network:
        return Row(children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _host,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'IP de la impresora'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: TextField(
              controller: _port,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Puerto'),
            ),
          ),
        ]);
      case Medium.usb:
        return DropdownButtonFormField<UsbPrinterDevice>(
          initialValue: _usbDevice,
          decoration: const InputDecoration(labelText: 'Dispositivo USB (OTG)'),
          items: [
            for (final d in _usb)
              DropdownMenuItem(value: d, child: Text(d.displayName)),
          ],
          onChanged: (v) => setState(() => _usbDevice = v),
        );
    }
  }
}
