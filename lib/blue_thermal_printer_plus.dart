import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'bluetooth_device.dart';

/// Clase principal para manejar la impresora térmica Bluetooth
class BlueThermalPrinterPlus {
  static const int stateOff = 10;
  static const int stateTurningOn = 11;
  static const int stateOn = 12;
  static const int stateTurningOff = 13;
  static const int stateBleTurningOn = 14;
  static const int stateBleOn = 15;
  static const int stateBleTurningOff = 16;
  static const int stateBleOff = 17;

  static const int error = -1;
  static const int connected = 1;
  static const int disconnected = 0;
  static const int disconnectRequested = 2;

  static const String namespace = 'blue_thermal_printer_plus';

  // Canales de comunicación con Kotlin
  final MethodChannel _channel = const MethodChannel('$namespace/methods');
  final EventChannel _stateChannel = const EventChannel('$namespace/state');
  final EventChannel _readChannel = const EventChannel('$namespace/read');

  // Singleton pattern (opcional, pero útil)
  static final BlueThermalPrinterPlus _instance = BlueThermalPrinterPlus._internal();
  factory BlueThermalPrinterPlus() => _instance;
  BlueThermalPrinterPlus._internal();

  /// Flujo de estados de la conexión Bluetooth (Conectado/Desconectado/Apagado)
  Stream<int> get onStateChanged {
    return _stateChannel.receiveBroadcastStream().map((buffer) => buffer);
  }

  /// Flujo para leer datos que envía la impresora (si aplica)
  Stream<String> get onRead {
    return _readChannel.receiveBroadcastStream().map(
      (buffer) => buffer.toString(),
    );
  }

  /// Verifica si el Bluetooth del celular está disponible
  Future<bool?> get isAvailable async {
    return await _channel.invokeMethod('isAvailable');
  }

  /// Verifica si el Bluetooth está encendido
  Future<bool?> get isOn async {
    return await _channel.invokeMethod('isOn');
  }

  /// Verifica si la App está conectada a alguna impresora
  Future<bool?> get isConnected async {
    return await _channel.invokeMethod('isConnected');
  }

  /// Verifica si un dispositivo específico está conectado
  Future<bool?> isDeviceConnected(BluetoothDevice device) async {
    return await _channel.invokeMethod('isDeviceConnected', {
      'address': device.address,
    });
  }

  /// Abre la configuración de Bluetooth de Android
  Future<bool?> get openSettings async {
    return await _channel.invokeMethod('openSettings');
  }

  /// Obtiene la lista de dispositivos vinculados (Paired Devices)
  Future<List<BluetoothDevice>> getBondedDevices() async {
    final List list = await _channel.invokeMethod('getBondedDevices');
    return list.map((map) => BluetoothDevice.fromMap(map)).toList();
  }

  /// Conectar a un dispositivo
  Future<dynamic> connect(BluetoothDevice device) =>
      _channel.invokeMethod('connect', {'address': device.address});

  /// Desconectar
  Future<dynamic> disconnect() => _channel.invokeMethod('disconnect');

  /// Escribir texto crudo
  Future<dynamic> write(String message) =>
      _channel.invokeMethod('write', {'message': message});

  /// Escribir bytes crudos
  Future<dynamic> writeBytes(Uint8List message) =>
      _channel.invokeMethod('writeBytes', {'message': message});

  /// Imprimir Texto Personalizado
  /// [size]: 0 (Normal), 1 (Normal-Bold), 2 (Medium-Bold), 3 (Large-Bold)
  /// [align]: 0 (Left), 1 (Center), 2 (Right)
  Future<dynamic> printCustom(
    String message,
    int size,
    int align, {
    String charset = "UTF-8",
  }) async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('printCustom', {
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

  /// Imprimir nueva línea
  Future<dynamic> printNewLine() => _channel.invokeMethod('printNewLine');

  /// Cortar papel
  Future<dynamic> paperCut() => _channel.invokeMethod('paperCut');

  /// Abrir cajón de dinero (Pin 2)
  Future<dynamic> drawerPin2() => _channel.invokeMethod('drawerPin2');

  /// Abrir cajón de dinero (Pin 5)
  Future<dynamic> drawerPin5() => _channel.invokeMethod('drawerPin5');

  /// Imprimir imagen desde ruta de archivo
  Future<dynamic> printImage(String pathImage) =>
      _channel.invokeMethod('printImage', {'pathImage': pathImage});

  /// Imprimir imagen desde bytes (Uint8List)
  Future<dynamic> printImageBytes(Uint8List bytes) =>
      _channel.invokeMethod('printImageBytes', {'bytes': bytes});

  /// Imprimir código QR
  Future<dynamic> printQRcode(
    String textToQR,
    int width,
    int height,
    int align,
  ) => _channel.invokeMethod('printQRcode', {
    'textToQR': textToQR,
    'width': width,
    'height': height,
    'align': align,
  });

  /// Imprimir texto en dos columnas (Izquierda - Derecha)
  /// Útil para facturas: "Producto ........ $10.00"
  Future<dynamic> printLeftRight(
    String string1,
    String string2,
    int size, {
    String charset = "UTF-8",
    String format = "%-15s %15s %n",
  }) => _channel.invokeMethod('printLeftRight', {
    'string1': string1,
    'string2': string2,
    'size': size,
    'charset': charset,
    'format': format,
  });

  /// Imprimir 3 columnas
  Future<dynamic> print3Column(
    String string1,
    String string2,
    String string3,
    int size, {
    String charset = "UTF-8",
    String format = "%-10s %10s %10s %n",
  }) => _channel.invokeMethod('print3Column', {
    'string1': string1,
    'string2': string2,
    'string3': string3,
    'size': size,
    'charset': charset,
    'format': format,
  });

  /// Imprimir 4 columnas
  Future<dynamic> print4Column(
    String string1,
    String string2,
    String string3,
    String string4,
    int size, {
    String charset = "UTF-8",
    String format = "%-8s %7s %7s %7s %n",
  }) => _channel.invokeMethod('print4Column', {
    'string1': string1,
    'string2': string2,
    'string3': string3,
    'string4': string4,
    'size': size,
    'charset': charset,
    'format': format,
  });
}
