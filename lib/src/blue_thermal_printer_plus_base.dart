import 'dart:io';
import 'dart:typed_data';

import 'transports/network_transport.dart';
import 'transports/printer_transport.dart';
import 'transports/usb_transport.dart';
import 'models/usb_device.dart';
import 'utils/image_rasterizer.dart';

import 'platforms/bluetooth_manager.dart';
import 'models/bluetooth_device.dart';
import 'models/print_item.dart';
import 'utils/printer_enums.dart';
import 'translators/printer_translator.dart';
import 'translators/esc_pos_translator.dart';
import 'translators/cpcl_translator.dart';
import 'translators/zpl_translator.dart';

class BlueThermalPrinterPlus {
  final BluetoothManager _manager = BluetoothManager();

  // Singleton para fácil acceso
  static final BlueThermalPrinterPlus _instance =
      BlueThermalPrinterPlus._internal();
  factory BlueThermalPrinterPlus() => _instance;
  BlueThermalPrinterPlus._internal();

  // --- Delegación de métodos de conexión al Manager ---
  Stream<int> get onStateChanged => _manager.onStateChanged;
  Future<bool?> get isAvailable async => await _manager.isAvailable();
  Future<bool?> get isOn async => await _manager.isOn();
  Future<List<BluetoothDevice>> getBondedDevices() async =>
      await _manager.getBondedDevices();
  // --- Transporte activo (red / USB). Si es null se usa Bluetooth. ---
  PrinterTransport? _transport;

  /// Descripción de la conexión de red/USB activa (null si es Bluetooth o nada).
  String? get activeTransportLabel => _transport?.label;

  Future<void> _dropTransport() async {
    final t = _transport;
    _transport = null;
    if (t != null) {
      try {
        await t.disconnect();
      } catch (_) {}
    }
  }

  Future<dynamic> connect(BluetoothDevice device) async {
    await _dropTransport();
    return await _manager.connect(device.address!);
  }

  /// Conecta a una impresora de red por socket TCP crudo (puerto 9100).
  /// Android e iOS.
  Future<void> connectNetwork(
    String host, {
    int port = 9100,
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await _dropTransport();
    _transport = await NetworkTransport.connect(
      host,
      port: port,
      timeout: timeout,
    );
  }

  /// Lista los dispositivos USB conectados por cable/OTG. Solo Android
  /// (en otras plataformas devuelve una lista vacía).
  Future<List<UsbPrinterDevice>> getUsbDevices() async {
    if (!Platform.isAndroid) return const [];
    return UsbTransport.list();
  }

  /// Conecta por cable USB (pide permiso al usuario). Solo Android.
  Future<void> connectUsb(UsbPrinterDevice device) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('La impresión por USB solo está disponible en Android');
    }
    await _dropTransport();
    _transport = await UsbTransport.connect(device);
  }

  Future<dynamic> disconnect() async {
    if (_transport != null) {
      await _dropTransport();
      return true;
    }
    return await _manager.disconnect();
  }

  Future<bool?> get isConnected async =>
      _transport != null ? _transport!.isConnected : await _manager.isConnected();
  Future<bool?> openSettings() async => await _manager.openSettings();

  // --- EL MÉTODO DE IMPRESIÓN MAESTRO ---

  Future<void> print({
    required List<PrintItem> items,
    required PrinterProtocol protocol,
    int widthDots = 384,
  }) async {
    // 1. Seleccionar el traductor según el protocolo configurado
    PrinterTranslator translator;
    switch (protocol) {
      case PrinterProtocol.cpcl:
        translator = CpclTranslator();
        break;
      case PrinterProtocol.zpl:
        translator = ZplTranslator();
        break;
      default:
        translator = EscPosTranslator();
        break;
    }

    // 2. Limpiar buffer y procesar cada item
    translator.paperWidth = widthDots;
    translator.reset();


    for (var item in items) {
      switch (item.type) {
        case PrintItemType.text:
          translator.addText(item.text!, size: item.size, align: item.align);
          break;
        case PrintItemType.image:
          translator.addImage(item.imageBytes!);
          break;
        case PrintItemType.encodedImage:
          final mono = await ImageRasterizer.toMono(
            item.imageBytes!,
            widthDots: widthDots,
            align: item.align,
          );
          translator.addImage(mono);
          break;
        case PrintItemType.barcode:
          translator.addBarcode(item.text!);
          break;
        case PrintItemType.qrCode:
          translator.addQrCode(item.text!);
          break;
        case PrintItemType.newLine:
          translator.addNewLine();
          break;
        case PrintItemType.paperCut:
          translator.addCut();
          break;
      }
    }

    // 3. Enviar los bytes finales al hardware a través del Manager
    final finalBytes = Uint8List.fromList(translator.bytes);
    final t = _transport;
    if (t != null) {
      await t.write(finalBytes);
    } else {
      await _manager.writeBytes(finalBytes);
    }
  }
}
