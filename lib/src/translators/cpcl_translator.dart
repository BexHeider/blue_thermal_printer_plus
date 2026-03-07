import 'dart:typed_data';
import 'printer_translator.dart';

class CpclTranslator extends PrinterTranslator {
  List<int> _bytes = [];
  int _currentY = 50;

  @override
  List<int> get bytes => _bytes;

  @override
  void reset() {
    _bytes = [];
    _currentY = 30; // Un margen inicial más limpio
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // 1. Selección dinámica de fuente y tamaño según el papel
    // CPCL maneja fuentes residentes (0, 1, 2, 4, 5, 7)
    // Usaremos la fuente 0 o 7 que son las más estándar
    String font = "0";
    int fontHeight;
    int charWidth;

    // Escalamiento basado en el ancho del papel
    bool isWidePaper = paperWidth > 400;

    if (size == 1) {
      // Mediano (Títulos de sección)
      font = "0";
      fontHeight = isWidePaper ? 4 : 2; // Tamaño de fuente
      charWidth = isWidePaper ? 16 : 10; // Ancho promedio por carácter
    } else if (size == 2) {
      // Grande (Encabezados/Factura)
      font = "4"; // Fuente más negrita
      fontHeight = 1;
      charWidth = isWidePaper ? 24 : 18;
    } else {
      // Normal (Productos/Precios)
      font = "7";
      fontHeight = 0;
      charWidth = isWidePaper ? 12 : 8;
    }

    // 2. Cálculo preciso de X para alineación
    int xPos = 0;
    int estimatedTextWidth = text.length * charWidth;

    if (align == 1) {
      // Centro
      xPos = (paperWidth - estimatedTextWidth) ~/ 2;
    } else if (align == 2) {
      // Derecha
      xPos = paperWidth - estimatedTextWidth - 5;
    }

    if (xPos < 0) xPos = 0;

    // El comando SETMAG escala la fuente (Ancho, Alto)
    // Solo lo aplicamos si es mediano/grande
    if (size > 0) {
      String mag = "SETMAG ${size + 1} ${size + 1}\r\n";
      _bytes.addAll(mag.codeUnits);
    } else {
      _bytes.addAll("SETMAG 0 0\r\n".codeUnits);
    }

    final command = "TEXT $font $fontHeight $xPos $_currentY $text\r\n";
    _bytes.addAll(command.codeUnits);

    // 3. Incremento de Y dinámico
    // El incremento debe ser mayor al alto de la fuente elegida
    int rowHeight = (size == 0) ? 35 : (size == 1 ? 60 : 80);
    _currentY += isWidePaper ? (rowHeight * 1.2).toInt() : rowHeight;
  }

  @override
  void addImage(Uint8List imageBytes) {
    // CPCL requiere que el ancho en bytes sea múltiplo de 8 para alineación
    int byteWidth = paperWidth ~/ 8;
    if (byteWidth <= 0) return;

    int height = imageBytes.length ~/ byteWidth;

    // Comando CG (Compressed Graphics) o EG (Expanded Graphics)
    String command = "EG $byteWidth $height 0 $_currentY ";

    _bytes.addAll(command.codeUnits);
    _bytes.addAll(imageBytes);
    _bytes.addAll("\r\n".codeUnits);

    _currentY += height + 20;
  }

  @override
  void addCut() {
    // Importante: El totalHeight debe ser preciso para no desperdiciar papel
    int totalHeight = _currentY + 40;

    // Cabecera CPCL estándar
    // ! {offset} {h-res} {v-res} {height} {qty}
    String header = "! 0 200 200 $totalHeight 1\r\n";

    // Configuración de alineación global a la izquierda por defecto
    String setup = "LEFT\r\n";

    _bytes.insertAll(0, (header + setup).codeUnits);
    _bytes.addAll("FORM\r\nPRINT\r\n".codeUnits);
  }

  @override
  void addNewLine() {
    // Salto de línea proporcional al papel
    _currentY += (paperWidth > 400) ? 50 : 35;
  }

  @override
  void addBarcode(String text) {
    // CPCL usa el comando BARCODE
    // Formato: BARCODE-S {tipo} {altura} {posición-x} {posición-y} {texto}
    // Tipo 1 = Code 128
    // Altura: 100 dots
    // Posición: 50 (centrado horizontalmente)

    String command = "BARCODE-S 1 100 50 $_currentY $text\r\n";
    _bytes.addAll(command.codeUnits);

    _currentY += 120; // Espacio para el código y el texto inferior
  }

  @override
  void addQrCode(String text) {
    // CPCL usa el comando QRCODE
    // Formato: QRCODE {tamaño-módulo} {posición-x} {posición-y} {texto}
    // Tamaño módulo: 4 (aprox 100x100 dots)
    // Posición: 50 (centrado horizontalmente)

    String command = "QRCODE 4 50 $_currentY $text\r\n";
    _bytes.addAll(command.codeUnits);

    _currentY += 150; // Espacio para el código QR
  }
}
