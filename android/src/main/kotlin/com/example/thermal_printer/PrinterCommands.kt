package com.bexsoluciones.thermal_printer

/**
 * Comandos ESC/POS estándar para impresoras térmicas
 */
object PrinterCommands {
    
    // Comandos de inicialización
    val HT = byteArrayOf(0x09)
    val LF = byteArrayOf(0x0a)
    val CR = byteArrayOf(0x0d)
    val ESC = byteArrayOf(0x1b)
    val DLE = byteArrayOf(0x10)
    val GS = byteArrayOf(0x1d)
    val FS = byteArrayOf(0x1c)
    val STX = byteArrayOf(0x02)
    val US = byteArrayOf(0x1f)
    val CAN = byteArrayOf(0x18)
    val CLR = byteArrayOf(0x0c)
    val EOT = byteArrayOf(0x04)

    val INIT = byteArrayOf(0x1b, 0x40)

    // Alineación de texto
    val ESC_ALIGN_LEFT = byteArrayOf(0x1b, 0x61, 0x00)
    val ESC_ALIGN_CENTER = byteArrayOf(0x1b, 0x61, 0x01)
    val ESC_ALIGN_RIGHT = byteArrayOf(0x1b, 0x61, 0x02)

    // Selección de fuente
    val ESC_FONT_A = byteArrayOf(0x1b, 0x4d, 0x00)
    val ESC_FONT_B = byteArrayOf(0x1b, 0x4d, 0x01)

    // Negrita (Bold)
    val ESC_CANCEL_BOLD = byteArrayOf(0x1b, 0x45, 0x00)
    val ESC_BOLD = byteArrayOf(0x1b, 0x45, 0x01)

    // Alimentación de papel (Feed)
    val FEED_LINE = byteArrayOf(0x0a)
    
    // Cortar papel (Cut)
    // GS V m - Cortar papel completo o parcial
    val FEED_PAPER_AND_CUT = byteArrayOf(0x1d, 0x56, 0x42, 0x00)

    // Cajón de dinero (Cash Drawer)
    // ESC p m t1 t2 - Generar pulso
    val ESC_DRAWER_PIN2 = byteArrayOf(0x1b, 0x70, 0x00, 0x32, 0xfa.toByte())
    val ESC_DRAWER_PIN5 = byteArrayOf(0x1b, 0x70, 0x01, 0x32, 0xfa.toByte())

    // Tamaño de caracteres (Doble altura/ancho)
    val ESC_DOUBLE_HEIGHT_WIDTH = byteArrayOf(0x1b, 0x21, 0x30)
    val ESC_DOUBLE_HEIGHT = byteArrayOf(0x1b, 0x21, 0x10)
    val ESC_DOUBLE_WIDTH = byteArrayOf(0x1b, 0x21, 0x20)
    val ESC_NORMAL = byteArrayOf(0x1b, 0x21, 0x00)
    
    // Comando para imprimir imagen (Raster Bit Image)
    // GS v 0 m xL xH yL yH d1...dk
    val SELECT_BIT_IMAGE_MODE = byteArrayOf(0x1B, 0x2A, 33)
}