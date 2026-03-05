import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/bluetooth_device.dart';

class BluetoothManager {
  static const String _namespace = 'blue_thermal_printer_plus';

  // Canales de comunicación
  final MethodChannel _methodChannel = const MethodChannel(
    '$_namespace/methods',
  );
  final EventChannel _stateChannel = const EventChannel('$_namespace/state');
  final EventChannel _readChannel = const EventChannel('$_namespace/read');

  // --- Streams de Estado ---

  /// Escucha si el Bluetooth se apaga o enciende en el celular
  Stream<int> get onStateChanged =>
      _stateChannel.receiveBroadcastStream().map((event) => event as int);

  /// Escucha datos entrantes desde la impresora
  Stream<String> get onRead =>
      _readChannel.receiveBroadcastStream().map((event) => event.toString());

  // --- Métodos de Control ---
  Future<bool?> isAvailable() async =>
      await _methodChannel.invokeMethod('isAvailable');
  Future<bool?> isOn() async => await _methodChannel.invokeMethod('isOn');
  Future<bool?> isConnected() async =>
      await _methodChannel.invokeMethod('isConnected');
  Future<List<BluetoothDevice>> getBondedDevices() async {
    final List list = await _methodChannel.invokeMethod('getBondedDevices');
    return list.map((map) => BluetoothDevice.fromMap(map)).toList();
  }

  // --- Conexión y Escritura ---
  Future<dynamic> connect(String address) =>
      _methodChannel.invokeMethod('connect', {'address': address});
  Future<dynamic> disconnect() => _methodChannel.invokeMethod('disconnect');

  /// Este es el método más importante: envía los comandos finales (ESC/POS, ZPL, CPCL)
  Future<dynamic> writeBytes(Uint8List bytes) =>
      _methodChannel.invokeMethod('writeBytes', {'message': bytes});

  Future<dynamic> paperCut() => _methodChannel.invokeMethod('paperCut');

  Future<dynamic> printNewLine() => _methodChannel.invokeMethod('printNewLine');

  Future<dynamic> printCustom(
    String message,
    int size,
    int align, {
    String charset = "UTF-8",
  }) async {
    if (Platform.isAndroid) {
      return _methodChannel.invokeMethod('printCustom', {
        'message': message,
        'size': size,
        'align': align,
        'charset': charset,
      });
    } else {
      // Para iOS, convertimos a comandos ESC/POS aquí en Dart
      List<int> bytes = [];

      // 1. Tamaño
      bytes.addAll([0x1D, 0x21, size == 0 ? 0x00 : 0x11]);

      // 2. Alineación (0: Left, 1: Center, 2: Right)
      bytes.addAll([0x1B, 0x61, align]);

      // 3. Texto
      bytes.addAll(message.codeUnits);
      bytes.addAll([0x0A]); // Salto de línea

      // Enviamos bytes crudos a Swift
      return writeBytes(Uint8List.fromList(bytes));
    }
  }

  /// Abre la configuración de Bluetooth del sistema
  Future<bool?> openSettings() async =>
      await _methodChannel.invokeMethod('openSettings');
}
