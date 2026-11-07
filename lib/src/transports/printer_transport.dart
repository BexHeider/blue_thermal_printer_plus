import 'dart:typed_data';

/// Canal físico por el que viajan los bytes hacia la impresora
/// (red WiFi/Ethernet o cable USB). Bluetooth sigue usando `BluetoothManager`.
abstract class PrinterTransport {
  /// Descripción legible, p. ej. `192.168.1.50:9100`.
  String get label;

  bool get isConnected;

  Future<void> write(Uint8List bytes);

  Future<void> disconnect();
}
