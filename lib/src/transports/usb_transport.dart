import 'package:flutter/services.dart';

import '../models/usb_device.dart';
import 'printer_transport.dart';

/// Impresión por cable USB (host/OTG). Solo Android.
class UsbTransport implements PrinterTransport {
  UsbTransport._(this.device);

  static const MethodChannel _channel = MethodChannel(
    'blue_thermal_printer_plus/methods',
  );

  final UsbPrinterDevice device;
  bool _connected = true;

  static Future<List<UsbPrinterDevice>> list() async {
    final List? raw = await _channel.invokeMethod('usbGetDevices');
    return (raw ?? const [])
        .map((m) => UsbPrinterDevice.fromMap(Map<dynamic, dynamic>.from(m)))
        .toList();
  }

  /// Pide permiso al usuario (si hace falta) y abre el dispositivo.
  static Future<UsbTransport> connect(UsbPrinterDevice device) async {
    await _channel.invokeMethod('usbConnect', {'deviceName': device.deviceName});
    return UsbTransport._(device);
  }

  @override
  String get label => device.displayName;

  @override
  bool get isConnected => _connected;

  @override
  Future<void> write(Uint8List bytes) async {
    await _channel.invokeMethod('usbWrite', {'message': bytes});
  }

  @override
  Future<void> disconnect() async {
    _connected = false;
    await _channel.invokeMethod('usbDisconnect');
  }
}
