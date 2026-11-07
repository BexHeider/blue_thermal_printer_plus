import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

/// Convierte una imagen PNG/JPG/WebP/GIF en el formato que esperan los
/// traductores: 1 bit por pixel (1 = negro), filas de `ceil(widthDots / 8)`
/// bytes y ancho EXACTO del papel.
class ImageRasterizer {
  /// [align]: 0 izquierda, 1 centro, 2 derecha (solo aplica si la imagen es
  /// más angosta que el papel; si es más ancha se reduce al ancho del papel).
  static Future<Uint8List> toMono(
    Uint8List encoded, {
    required int widthDots,
    int align = 1,
    int threshold = 128,
  }) async {
    final codec = await ui.instantiateImageCodec(encoded);
    var frame = (await codec.getNextFrame()).image;
    if (frame.width > widthDots) {
      // Reescala al ancho del papel manteniendo proporción.
      frame.dispose();
      final c2 = await ui.instantiateImageCodec(encoded, targetWidth: widthDots);
      frame = (await c2.getNextFrame()).image;
      c2.dispose();
    }
    final w = frame.width;
    final h = frame.height;
    final data = await frame.toByteData(format: ui.ImageByteFormat.rawRgba);
    frame.dispose();
    codec.dispose();
    if (data == null) throw StateError('No se pudo decodificar la imagen');

    final rgba = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final offset = switch (align) {
      0 => 0,
      2 => widthDots - w,
      _ => (widthDots - w) ~/ 2,
    };
    return compute(
      _dither,
      _Job(rgba, w, h, widthDots, offset, threshold),
    );
  }
}

class _Job {
  final Uint8List rgba;
  final int w, h, widthDots, offset, threshold;
  _Job(this.rgba, this.w, this.h, this.widthDots, this.offset, this.threshold);
}

/// Escala de grises (transparente = blanco) + difuminado Floyd–Steinberg.
Uint8List _dither(_Job j) {
  final w = j.w, h = j.h;
  final gray = Float32List(w * h);
  for (var i = 0; i < w * h; i++) {
    final r = j.rgba[i * 4], g = j.rgba[i * 4 + 1], b = j.rgba[i * 4 + 2];
    final a = j.rgba[i * 4 + 3] / 255.0;
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    gray[i] = lum * a + 255 * (1 - a);
  }
  final rowBytes = (j.widthDots + 7) ~/ 8;
  final out = Uint8List(rowBytes * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      final old = gray[i];
      final black = old < j.threshold;
      final err = old - (black ? 0 : 255);
      if (x + 1 < w) gray[i + 1] += err * 7 / 16;
      if (y + 1 < h) {
        if (x > 0) gray[i + w - 1] += err * 3 / 16;
        gray[i + w] += err * 5 / 16;
        if (x + 1 < w) gray[i + w + 1] += err * 1 / 16;
      }
      if (black) {
        final px = x + j.offset;
        out[y * rowBytes + (px >> 3)] |= 0x80 >> (px & 7);
      }
    }
  }
  return out;
}
