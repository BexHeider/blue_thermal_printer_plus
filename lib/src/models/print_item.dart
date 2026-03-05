import 'dart:typed_data';
import '../utils/printer_enums.dart';

/// Clase que representa una unidad de impresión (una línea de texto, una imagen, etc.)
class PrintItem {
  final String? text;
  final PrintItemType type;
  final int size; // 0: Normal, 1: Bold/Large, etc.
  final int align; // 0: Left, 1: Center, 2: Right
  final Uint8List? imageBytes; // Para cuando el tipo es 'image'
  final double? width; // Opcional para imágenes o QR
  final double? height;

  PrintItem({
    this.text,
    this.type = PrintItemType.text,
    this.size = 0,
    this.align = 0,
    this.imageBytes,
    this.width,
    this.height,
  });

  /// Factory para crear texto rápidamente
  factory PrintItem.text(String text, {int size = 0, int align = 0}) {
    return PrintItem(
      text: text,
      type: PrintItemType.text,
      size: size,
      align: align,
    );
  }

  /// Factory para crear imágenes
  factory PrintItem.image(Uint8List bytes, {int align = 1, double? width}) {
    return PrintItem(
      imageBytes: bytes,
      type: PrintItemType.image,
      align: align,
      width: width,
    );
  }
}
