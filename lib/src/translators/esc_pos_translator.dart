import 'dart:typed_data';
import 'printer_translator.dart';

class EscPosTranslator extends PrinterTranslator {
  List<int> _bytes = [];

  @override
  List<int> get bytes => _bytes;

  @override
  void reset() {
    _bytes = [];
    // Comando de inicialización (ESC @) - Limpia formatos previos
    _bytes.addAll([0x1B, 0x40]);
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // 1. Alineación (ESC a n) -> 0: Izq, 1: Centro, 2: Der
    _bytes.addAll([0x1B, 0x61, align]);

    // 2. Tamaño de fuente (GS ! n)
    int sizeByte = 0x00;
    if (size == 1) sizeByte = 0x11; // Doble ancho y alto
    if (size == 2) sizeByte = 0x22; // Triple ancho y alto
    _bytes.addAll([0x1D, 0x21, sizeByte]);

    // 3. Texto
    // Nota: Para tildes o eñes, lo ideal es usar latin1.encode(text)
    _bytes.addAll(text.codeUnits);

    // 4. Salto de línea
    _bytes.add(0x0A);
  }

  @override
  void addNewLine() {
    _bytes.add(0x0A);
  }

  @override
  void addCut() {
    // 1. Alimentar unas líneas antes de cortar para que el texto no quede atrapado
    _bytes.addAll([0x0A, 0x0A]);
    // 2. Comando de corte (GS V 66 n)
    _bytes.addAll([0x1D, 0x56, 0x42, 0x00]);
  }

  @override
  void addImage(Uint8List imageBytes) {
    // ESC/POS usa el comando GS v 0 (Raster Bit Image)
    // El ancho en puntos (dots) viene de paperWidth (384 o 576)
    int widthInDots = paperWidth;
    int byteWidth = (widthInDots / 8).ceil();
    int height = imageBytes.length ~/ byteWidth;

    // Comando GS v 0 p xL xH yL yH
    // p = 0 (Normal)
    _bytes.addAll([0x1D, 0x76, 0x30, 0x00]);

    // xL, xH (Ancho en bytes)
    _bytes.add(byteWidth % 256);
    _bytes.add(byteWidth ~/ 256);

    // yL, yH (Alto en puntos)
    _bytes.add(height % 256);
    _bytes.add(height ~/ 256);

    // Datos de la imagen
    _bytes.addAll(imageBytes);

    // Salto de línea después de la imagen
    _bytes.add(0x0A);
  }
}
