import 'dart:typed_data';

abstract class PrinterTranslator {
  List<int> get bytes;
  
  void addText(String text, {int size = 0, int align = 0});
  void addNewLine();
  void addImage(Uint8List imageBytes);
  void addCut();
  
  // Limpia el buffer para una nueva impresión
  void reset();
}