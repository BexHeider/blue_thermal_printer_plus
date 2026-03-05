import 'dart:async';
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

  /// Abre la configuración de Bluetooth del sistema
  Future<bool?> openSettings() async =>
      await _methodChannel.invokeMethod('openSettings');
}
