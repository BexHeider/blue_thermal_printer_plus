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
    _currentY = 50;
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // Definimos fuentes y anchos de caracteres aproximados
    // Fuente 7, tamaño 0 tiene aprox 12 puntos de ancho por carácter
    // Fuente 7, tamaño 1 tiene aprox 24 puntos
    String font = "7";
    String fontSize = (size == 1) ? "1" : "0";
    int charWidth = (size == 1) ? 24 : 12;

    int xPos = 10; // Margen izquierdo por defecto

    // --- CÁLCULO DE ALINEACIÓN ---
    if (align == 1) {
      // Centro
      int textWidth = text.length * charWidth;
      xPos = (paperWidth - textWidth) ~/ 2;
    } else if (align == 2) {
      // Derecha
      int textWidth = text.length * charWidth;
      xPos = paperWidth - textWidth - 10;
    }

    if (xPos < 0) xPos = 0;

    final command = "TEXT $font $fontSize $xPos $_currentY $text\r\n";
    _bytes.addAll(command.codeUnits);

    // Incrementar Y según el tamaño
    _currentY += (size == 1) ? 90 : 45;
  }

  @override
  void addImage(Uint8List imageBytes) {
    // 1. Usamos el paperWidth parametrizado
    int widthInDots = paperWidth;

    // 2. Calculamos el ancho en bytes (8 píxeles por cada byte)
    int byteWidth = widthInDots ~/ 8;

    // 3. Calculamos el alto de la imagen
    // Evitamos división por cero si byteWidth no es correcto
    if (byteWidth <= 0) return;
    int height = imageBytes.length ~/ byteWidth;

    // 4. Construimos el comando EG
    // Usamos x=0 para que ocupe todo el ancho del papel
    String command = "EG $byteWidth $height 0 $_currentY ";

    _bytes.addAll(command.codeUnits);
    _bytes.addAll(imageBytes);
    _bytes.addAll("\r\n".codeUnits);

    _currentY += height + 20;
  }

  @override
  void addCut() {
    // 5. El encabezado debe indicar la resolución horizontal (paperWidth)
    // El formato es: ! {offset} {res_horizontal} {res_vertical} {alto_total} {cantidad}
    int totalHeight = _currentY + 50;

    // Usamos paperWidth para que la impresora sepa el ancho físico
    String header = "! 0 200 200 $totalHeight 1\r\n";

    _bytes.insertAll(0, header.codeUnits);
    _bytes.addAll("FORM\r\nPRINT\r\n".codeUnits);
  }

  @override
  void addNewLine() {
    _currentY += 45;
  }
}
