import 'package:flutter/foundation.dart';

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
  Future<dynamic> connect(BluetoothDevice device) async =>
      await _manager.connect(device.address!);
  Future<dynamic> disconnect() async => await _manager.disconnect();
  Future<bool?> get isConnected async => await _manager.isConnected();
  Future<bool?> openSettings() async => await _manager.openSettings();

  // --- EL MÉTODO DE IMPRESIÓN MAESTRO ---

  Future<void> print({
    required List<PrintItem> items,
    required PrinterProtocol protocol,
    int widthDots = 384,
  }) async {
    debugPrint("Protocolo: $protocol");

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
      debugPrint("Item: ${item.type}");
      switch (item.type) {
        case PrintItemType.text:
          translator.addText(item.text!, size: item.size, align: item.align);
          break;
        case PrintItemType.image:
          translator.addImage(item.imageBytes!);
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
    debugPrint("Bytes finales: ${finalBytes.length}");
    await _manager.writeBytes(finalBytes);
  }
}
