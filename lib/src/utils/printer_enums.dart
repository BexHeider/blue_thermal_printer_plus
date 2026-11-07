/// Protocolos de impresión
enum PrinterProtocol { escPos, cpcl, zpl }

/// Define el tipo de contenido que se va a procesar
enum PrintItemType {
  text,
  /// Bitmap ya en 1 bit por pixel (formato crudo).
  image,
  /// PNG/JPG/etc. sin procesar; el paquete lo rasteriza.
  encodedImage,
  qrCode,
  barcode,
  newLine,
  paperCut,
}

// add new enum for paper size
enum PaperSize { mm58, mm80, mm110 }
