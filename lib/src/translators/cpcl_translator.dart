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
    /* Lógica específica CPCL */
  }
  @override
  void addNewLine() {
    _currentY += 45;
  }
}
