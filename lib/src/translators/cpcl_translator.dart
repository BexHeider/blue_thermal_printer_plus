import 'dart:typed_data';
import 'printer_translator.dart';

class CpclTranslator extends PrinterTranslator {
  List<int> _bytes = [];
  int _currentY = 50;

  @override
  List<int> get bytes => _bytes;

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // Aquí pegas tu lógica de: "TEXT 7 $size 10 $_currentY $text\r\n"
    // Pero en lugar de imprimir, lo guardas en el buffer de bytes
    final command = "TEXT 7 $size 10 $_currentY $text\r\n";
    _bytes.addAll(command.codeUnits);
    _currentY += (size == 1) ? 90 : 45;
  }

  @override
  void addCut() {
    // Insertamos el encabezado al principio y el footer al final
    _bytes.insertAll(0, "! 0 200 200 ${_currentY + 50} 1\r\n".codeUnits);
    _bytes.addAll("FORM\r\nPRINT\r\n".codeUnits);
  }

  @override
  void reset() {
    _bytes = [];
    _currentY = 50;
  }

  @override
  void addImage(Uint8List imageBytes) {
    // 1. Definimos el ancho de la impresora en puntos (Dots)
    // El estándar para 58mm es 384 puntos, para 80mm es 576.
    const int widthInDots = 384;

    // 2. Calculamos el ancho en bytes (8 píxeles por cada byte)
    const int byteWidth = widthInDots ~/ 8;

    // 3. Calculamos el alto de la imagen basándonos en los bytes recibidos
    // Alto = Total de bytes / bytes por fila
    int height = imageBytes.length ~/ byteWidth;

    // 4. Construimos el comando EG (Expanded Graphics)
    // Formato: EG {ancho_en_bytes} {alto} {x} {y} {datos_binarios}
    // Usamos una X inicial de 0 y la Y actual
    String command = "EG $byteWidth $height 0 $_currentY ";

    // Añadimos el comando de texto al buffer
    _bytes.addAll(command.codeUnits);

    // 5. Añadimos los bytes crudos de la imagen (el mapa de bits)
    _bytes.addAll(imageBytes);

    // Terminamos el comando con un salto de línea
    _bytes.addAll("\r\n".codeUnits);

    // 6. Actualizamos el cursor vertical (_currentY)
    // para que el siguiente texto no se imprima encima de la imagen
    _currentY += height + 20;
  }

  @override
  void addNewLine() {
    _currentY += 45;
  }
}
