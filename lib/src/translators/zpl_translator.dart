import 'dart:typed_data';
import 'printer_translator.dart';

class ZplTranslator extends PrinterTranslator {
  StringBuffer _buffer = StringBuffer();
  int _currentY = 30; // Posición vertical inicial
  final int _lineHeight = 40; // Espacio entre líneas por defecto

  @override
  List<int> get bytes => _buffer.toString().codeUnits;

  @override
  void reset() {
    _buffer = StringBuffer();
    _currentY = 30;
    _buffer.write("^XA"); // Inicio de etiqueta
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // 1. Configurar Fuente según el tamaño
    // ^CFf,h,w (f: fuente, h: alto, w: ancho)
    String fontSize = "^CF0,30,30";
    int increment = _lineHeight;

    if (size == 1) {
      fontSize = "^CF0,45,45";
      increment = 60;
    } else if (size == 2) {
      fontSize = "^CF0,60,60";
      increment = 80;
    }

    // 2. Manejar Alineación
    // En ZPL, para centrar necesitamos definir un bloque de datos ^FB
    // ^FB(ancho_total, lineas_max, espacio_entre_lineas, alineacion, sangria)
    String alignmentCode = "L"; // Left
    if (align == 1) alignmentCode = "C"; // Center
    if (align == 2) alignmentCode = "R"; // Right

    _buffer.write(fontSize);
    // Definimos un bloque de 580 puntos (ancho estándar de 3 pulgadas)
    _buffer.write("^FO0,$_currentY^FB580,1,0,$alignmentCode,0^FD$text^FS");

    _currentY += increment;
  }

  @override
  void addNewLine() {
    _currentY += _lineHeight;
  }

  @override
  void addCut() {
    // ZPL no tiene un comando de "corte" como tal en todas las impresoras,
    // pero ^XZ indica el final de la etiqueta y la impresora expulsa el papel.
    _buffer.write("^XZ");
  }

  @override
  void addImage(Uint8List imageBytes) {
    // En ZPL, las imágenes se manejan por ancho en bytes (puntos / 8)
    // Suponiendo un ancho estándar de 384 puntos (48 bytes)
    int widthInDots = 384;
    int bytesPerRow = (widthInDots / 8).ceil();
    int height = (imageBytes.length / bytesPerRow).floor();
    int totalBytes = imageBytes.length;

    // Comando ^GF (Graphic Field)
    // ^GFA,totalBytes,totalBytes,bytesPerRow,data
    _buffer.write("^FO0,$_currentY"); // Posición donde inicia la imagen
    _buffer.write("^GFA,$totalBytes,$totalBytes,$bytesPerRow,");

    // Los datos deben enviarse en formato Hexadecimal
    for (int byte in imageBytes) {
      _buffer.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
    }

    _buffer.write("^FS"); // Fin de sección de imagen

    // Actualizamos Y para que lo siguiente no se encime
    _currentY += height + 20;
  }
}
