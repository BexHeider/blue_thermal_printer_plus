import 'dart:typed_data';
import 'printer_translator.dart';

class ZplTranslator extends PrinterTranslator {
  StringBuffer _buffer = StringBuffer();
  int _currentY = 30;

  @override
  List<int> get bytes => _buffer.toString().codeUnits;

  // El paperWidth viene en dots.
  // 58mm ~ 384 dots (a 203 dpi)
  // 80mm ~ 576 dots (a 203 dpi)

  @override
  void reset() {
    _buffer = StringBuffer();
    _currentY = 30;
    _buffer.write("^XA");
    _buffer.write("^LT0^PON");
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // Definimos tamaños base que escalan según el papel
    // Multiplicamos por un factor si el papel es ancho (80mm) vs estrecho (58mm)
    double scaleFactor = paperWidth > 400 ? 1.5 : 1.0;

    int fontHeight;
    int fontWidth;
    int increment;

    switch (size) {
      case 1: // Mediano
        fontHeight = (30 * scaleFactor).toInt();
        fontWidth = (25 * scaleFactor).toInt();
        increment = fontHeight + 10;
        break;
      case 2: // Grande
        fontHeight = (45 * scaleFactor).toInt();
        fontWidth = (40 * scaleFactor).toInt();
        increment = fontHeight + 15;
        break;
      default: // Normal (Size 0)
        fontHeight = (20 * scaleFactor).toInt();
        fontWidth = (18 * scaleFactor).toInt();
        increment = fontHeight + 8;
    }

    String alignmentCode = "L";
    if (align == 1) alignmentCode = "C";
    if (align == 2) alignmentCode = "R";

    // ^A0: Fuente predeterminada Zebra
    // ,N: Orientación Normal
    // ,H,W: Alto y Ancho
    _buffer.write("^A0N,$fontHeight,$fontWidth");

    // ^FB: Field Block para manejo de alineación y ajuste de línea automático
    _buffer.write(
      "^FO0,$_currentY^FB$paperWidth,1,0,$alignmentCode,0^FD$text^FS",
    );

    _currentY += increment;
  }

  @override
  void addNewLine() {
    _currentY += (paperWidth > 400 ? 25 : 20);
  }

  @override
  void addCut() {
    _buffer.write("^XZ");
  }

  @override
  void addImage(Uint8List imageBytes) {
    int bytesPerRow = (paperWidth / 8).ceil();
    int height = (imageBytes.length / bytesPerRow).floor();
    int totalBytes = imageBytes.length;

    _buffer.write("^FO0,$_currentY");
    _buffer.write("^GFA,$totalBytes,$totalBytes,$bytesPerRow,");

    for (int byte in imageBytes) {
      _buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }

    _buffer.write("^FS");

    _currentY += height + 20;
  }
}
