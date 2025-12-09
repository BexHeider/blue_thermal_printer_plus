package com.bexsoluciones.blue_thermal_printer_plus

import android.graphics.Bitmap
import android.graphics.Color
import java.util.ArrayList

object Utils {

    /**
     * Convierte un Bitmap a un array de bytes comando ESC/POS
     * Utiliza el comando GS v 0 (Raster bit image)
     */
    fun decodeBitmap(bmp: Bitmap): ByteArray {
        val bmpWidth = bmp.width
        val bmpHeight = bmp.height

        // 1. Convertir la imagen a una lista de cadenas binarias ("0" y "1")
        val list = ArrayList<String>()
        var sb: StringBuffer

        // Umbral para decidir si un pixel es blanco o negro (0-255)
        // 128 es un buen estándar.
        val threshold = 128

        for (i in 0 until bmpHeight) {
            sb = StringBuffer()
            for (j in 0 until bmpWidth) {
                val color = bmp.getPixel(j, i)
                val r = (color shr 16) and 0xff
                val g = (color shr 8) and 0xff
                val b = color and 0xff
                
                // Fórmula de luminancia para escala de grises
                val brightness = (0.299 * r + 0.587 * g + 0.114 * b).toInt()
                
                // Si es más oscuro que el umbral, es negro (1), sino blanco (0)
                if (brightness < threshold) {
                    sb.append("1")
                } else {
                    sb.append("0")
                }
            }
            list.add(sb.toString())
        }

        // 2. Convertir las cadenas binarias a bytes hexadecimales
        val bmpHexList = ArrayList<String>()
        for (rowStr in list) {
            sb = StringBuffer()
            var i = 0
            while (i < rowStr.length) {
                // Tomamos grupos de 8 bits
                var str = if (i + 8 > rowStr.length) {
                    rowStr.substring(i) + "00000000".substring(0, 8 - (rowStr.length - i))
                } else {
                    rowStr.substring(i, i + 8)
                }
                
                // Convertimos "01010101" a byte hexadecimal
                val hex = Integer.toHexString(Integer.parseInt(str, 2))
                if (hex.length == 1) {
                    sb.append("0")
                }
                sb.append(hex)
                i += 8
            }
            bmpHexList.add(sb.toString())
        }

        // 3. Construir el comando final ESC/POS
        // Formato: GS v 0 m xL xH yL yH d1...dk
        val commandList = ArrayList<Byte>()
        
        // Header GS v 0 0
        commandList.add(0x1d.toByte())
        commandList.add(0x76.toByte())
        commandList.add(0x30.toByte())
        commandList.add(0x00.toByte())

        // Calcular ancho en bytes (xL, xH)
        // widthBytes = (width + 7) / 8
        val widthBytes = if (bmpWidth % 8 == 0) bmpWidth / 8 else (bmpWidth / 8 + 1)
        commandList.add((widthBytes % 256).toByte()) // xL
        commandList.add((widthBytes / 256).toByte()) // xH

        // Calcular alto en puntos (yL, yH)
        commandList.add((bmpHeight % 256).toByte()) // yL
        commandList.add((bmpHeight / 256).toByte()) // yH

        // Agregar los datos de la imagen
        for (hexStr in bmpHexList) {
            var i = 0
            while (i < hexStr.length) {
                val hexByte = hexStr.substring(i, i + 2)
                val byteVal = Integer.parseInt(hexByte, 16)
                commandList.add(byteVal.toByte())
                i += 2
            }
        }

        // Convertir ArrayList a ByteArray primitivo
        val bytes = ByteArray(commandList.size)
        for (i in commandList.indices) {
            bytes[i] = commandList[i]
        }

        return bytes
    }
}