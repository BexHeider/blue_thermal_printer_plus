import 'dart:typed_data';
import 'printer_translator.dart';

class ZplTranslator extends PrinterTranslator {
  StringBuffer _buffer = StringBuffer();
  int _currentY = 30;
  final int _lineHeight = 40;

  @override
  List<int> get bytes => _buffer.toString().codeUnits;

  @override
  void reset() {
    _buffer = StringBuffer();
    _currentY = 30;
    _buffer.write("^XA");
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    String fontSize = "^CF0,30,30";
    int increment = _lineHeight;

    if (size == 1) {
      fontSize = "^CF0,25,25";
      increment = 60;
    } else if (size == 2) {
      fontSize = "^CF0,40,40";
      increment = 80;
    }

    String alignmentCode = "L";
    if (align == 1) alignmentCode = "C";
    if (align == 2) alignmentCode = "R";

    _buffer.write(fontSize);

    _buffer.write(
      "^FO0,$_currentY^FB$paperWidth,1,0,$alignmentCode,0^FD$text^FS",
    );

    _currentY += increment;
  }

  @override
  void addNewLine() {
    _currentY += _lineHeight;
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
