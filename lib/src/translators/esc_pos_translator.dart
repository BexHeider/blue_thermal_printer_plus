import 'dart:typed_data';
import 'dart:convert';
import 'printer_translator.dart';

class EscPosTranslator extends PrinterTranslator {
  List<int> _bytes = [];

  @override
  List<int> get bytes => _bytes;

  @override
  void reset() {
    _bytes = [];
    // Inicialización (ESC @)
    _bytes.addAll([0x1B, 0x40]);
    // Seleccionar tabla de caracteres (PC850 es común para español/latino)
    // ESC t n (n=2 para PC850 o n=16 para WPC1252)
    _bytes.addAll([0x1B, 0x74, 0x02]);
  }

  @override
  void addText(String text, {int size = 0, int align = 0}) {
    // 1. Alineación (ESC a n)
    _bytes.addAll([0x1B, 0x61, align]);

    // 2. Tamaño de fuente (GS ! n)
    // El byte n define (alto | ancho)
    // 0x00: Normal, 0x11: Doble alto/ancho, 0x22: Triple
    int sizeByte = 0x00;
    if (size == 1) sizeByte = 0x11;
    if (size == 2) sizeByte = 0x22;
    _bytes.addAll([0x1D, 0x21, sizeByte]);

    // 3. Manejo de caracteres especiales (Bexmovil: Nombres de clientes/productos)
    // Usamos latin1 para que la impresora entienda la 'ñ' y tildes si tiene la tabla correcta
    try {
      _bytes.addAll(latin1.encode(text));
    } catch (e) {
      // Fallback a codeUnits si hay caracteres extraños
      _bytes.addAll(text.codeUnits);
    }

    // 4. Salto de línea
    _bytes.add(0x0A);
  }

  /// Método útil para Bexmovil: Crea una línea de separación (----) según el ancho
  void addSeparator() {
    // 58mm ~ 32 chars, 80mm ~ 48 chars
    int chars = paperWidth > 400 ? 48 : 32;
    addText("-" * chars);
  }

  /// Método para imprimir en dos columnas (Producto a la izq, Precio a la der)
  void addRow(String left, String right) {
    int totalChars = paperWidth > 400 ? 48 : 32;
    int spaceCount = totalChars - left.length - right.length;

    if (spaceCount < 1) spaceCount = 1;

    String line = left + (" " * spaceCount) + right;
    addText(line);
  }

  @override
  void addNewLine() {
    _bytes.add(0x0A);
  }

  @override
  void addCut() {
    // Alimentar papel (importante en autoventa para que el vendedor pueda cortar bien)
    _bytes.addAll([0x0A, 0x0A, 0x0A]);

    // Comando de corte parcial (GS V 66 0)
    // Algunas impresoras baratas no tienen cortador automático
    _bytes.addAll([0x1D, 0x56, 0x42, 0x00]);
  }

  @override
  void addImage(Uint8List imageBytes) {
    // En ESC/POS la imagen rasterizada debe enviarse con el ancho exacto del papel
    int widthInDots = paperWidth;
    int byteWidth = (widthInDots / 8).ceil();

    // Evitar desbordamiento si la lista de bytes no coincide con el ancho
    if (imageBytes.isEmpty) return;
    int height = imageBytes.length ~/ byteWidth;

    // Comando Raster Bit Image (GS v 0)
    _bytes.addAll([0x1D, 0x76, 0x30, 0x00]);

    // xL, xH (Ancho en bytes)
    _bytes.add(byteWidth % 256);
    _bytes.add(byteWidth ~/ 256);

    // yL, yH (Alto en puntos)
    _bytes.add(height % 256);
    _bytes.add(height ~/ 256);

    _bytes.addAll(imageBytes);
    _bytes.add(0x0A);
  }

  @override
  void addBarcode(String text) {
    // 1. Seleccionar modo de código de barras (GS w n)
    _bytes.addAll([0x1D, 0x77, 0x02]); // Ancho 2
    _bytes.addAll([0x1D, 0x68, 0x64]); // Altura 100

    // 2. Imprimir código de barras (GS H n)
    _bytes.addAll([0x1D, 0x48, 0x02]); // Mostrar texto abajo

    // 3. Comando de impresión
    _bytes.addAll([0x1D, 0x6B, 0x04]); // Tipo 4 (Code 128)
    _bytes.addAll(text.codeUnits);
    _bytes.add(0x00); // Terminador

    _bytes.add(0x0A);
  }

  @override
  void addQrCode(String text) {
    // 1. Inicializar QR (GS ( k n)
    // n=48 para QR Code
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x04, 0x00, 0x31, 0x41, 0x32, 0x00]);

    // 2. Definir tamaño (GS ( k n)
    // n = tamaño del módulo * 4
    int moduleSize = 4;
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x43, moduleSize]);

    // 3. Definir corrección de errores (GS ( k n)
    // n=48 (M), 49 (Q), 50 (H)
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x45, 0x30]);

    // 4. Cargar datos
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x02, 0x00, 0x31, 0x47]);
    _bytes.addAll(text.codeUnits);
    _bytes.add(0x00);

    // 5. Imprimir
    _bytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);

    _bytes.add(0x0A);
  }
}
