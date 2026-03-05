import 'dart:typed_data';
import 'printer_translator.dart';

class EscPosTranslator extends PrinterTranslator {
  List<int> _bytes = [];

  @override
  List<int> get bytes => _bytes;

  @override
  void reset() {
    _bytes = [];
    // Comando de inicialización (ESC @)
    _bytes.addAll([0x1B, 0x40]); 
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // 1. Alineación (ESC a n)
    // n = 0: Izquierda, 1: Centro, 2: Derecha
    _bytes.addAll([0x1B, 0x61, align]);

    // 2. Tamaño de fuente (GS ! n)
    // size 0: Normal, 1: Doble alto, 2: Doble ancho/alto
    int sizeByte = 0x00;
    if (size == 1) sizeByte = 0x11; // Doble ancho y alto
    if (size == 2) sizeByte = 0x22; // Triple ancho y alto
    _bytes.addAll([0x1D, 0x21, sizeByte]);

    // 3. Texto (Convertir String a bytes)
    _bytes.addAll(text.codeUnits);
    
    // 4. Salto de línea automático tras el texto
    _bytes.add(0x0A); 
  }

  @override
  void addNewLine() {
    _bytes.add(0x0A);
  }

  @override
  void addCut() {
    // Alimentar papel y cortar (GS V 66 n)
    _bytes.addAll([0x1D, 0x56, 0x42, 0x00]);
  }

  @override
  void addImage(Uint8List imageBytes) {
    // Aquí iría la lógica de conversión de imagen a mapa de bits ESC/POS
    // Es un proceso complejo de "bit-banging"
    // Por ahora, podrías dejar un placeholder o usar una librería de soporte
  }
}