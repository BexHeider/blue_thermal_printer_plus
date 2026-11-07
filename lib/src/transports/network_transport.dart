import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'printer_transport.dart';

/// Impresión por red con un socket TCP crudo (puerto 9100 / "RAW" / JetDirect).
/// Funciona en Android e iOS sin código nativo.
class NetworkTransport implements PrinterTransport {
  NetworkTransport._(this.host, this.port, this._socket) {
    _socket.done.then((_) => _closed = true, onError: (_) => _closed = true);
    // Algunas impresoras responden con estado; lo descartamos.
    _socket.listen((_) {}, onError: (_) => _closed = true, cancelOnError: true);
  }

  final String host;
  final int port;
  final Socket _socket;
  bool _closed = false;

  static Future<NetworkTransport> connect(
    String host, {
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    socket.setOption(SocketOption.tcpNoDelay, true);
    return NetworkTransport._(host, port, socket);
  }

  @override
  String get label => '$host:$port';

  @override
  bool get isConnected => !_closed;

  @override
  Future<void> write(Uint8List bytes) async {
    if (_closed) throw const SocketException('La impresora de red está desconectada');
    _socket.add(bytes);
    await _socket.flush();
  }

  @override
  Future<void> disconnect() async {
    _closed = true;
    try {
      await _socket.flush();
    } catch (_) {}
    await _socket.close();
    _socket.destroy();
  }
}
