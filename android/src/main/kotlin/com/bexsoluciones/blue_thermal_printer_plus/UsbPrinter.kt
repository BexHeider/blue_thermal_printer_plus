package com.bexsoluciones.blue_thermal_printer_plus

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbConstants
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbEndpoint
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodChannel.Result

/** Impresión por USB host (OTG): listar, pedir permiso, abrir y escribir por bulk OUT. */
class UsbPrinter(private val context: Context) {

    private val usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager
    private val main = Handler(Looper.getMainLooper())

    private var connection: UsbDeviceConnection? = null
    private var iface: UsbInterface? = null
    private var endpoint: UsbEndpoint? = null

    companion object {
        private const val ACTION_PERMISSION = "com.bexsoluciones.blue_thermal_printer_plus.USB_PERMISSION"
        private const val CHUNK = 16 * 1024
        private const val TIMEOUT_MS = 5000
    }

    fun list(): List<Map<String, Any?>> = usbManager.deviceList.values.map { d ->
        val isPrinter = (0 until d.interfaceCount).any {
            d.getInterface(it).interfaceClass == UsbConstants.USB_CLASS_PRINTER
        }
        mapOf(
            "deviceName" to d.deviceName,
            "vendorId" to d.vendorId,
            "productId" to d.productId,
            "productName" to d.productName,
            "manufacturerName" to d.manufacturerName,
            "isPrinterClass" to isPrinter
        )
    }

    fun connect(deviceName: String, result: Result) {
        val device = usbManager.deviceList[deviceName]
        if (device == null) {
            result.error("usb_error", "Dispositivo USB no encontrado", null)
            return
        }
        if (usbManager.hasPermission(device)) {
            open(device, result)
            return
        }
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context, intent: Intent) {
                try { context.unregisterReceiver(this) } catch (_: Exception) {}
                val granted = intent.getBooleanExtra(UsbManager.EXTRA_PERMISSION_GRANTED, false)
                if (granted) open(device, result)
                else result.error("usb_permission_denied", "Permiso USB denegado", null)
            }
        }
        val filter = IntentFilter(ACTION_PERMISSION)
        if (Build.VERSION.SDK_INT >= 33) {
            context.registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            @Suppress("UnspecifiedRegisterReceiverFlag")
            context.registerReceiver(receiver, filter)
        }
        // En Android 14+ el PendingIntent debe ser explícito (paquete propio) y mutable.
        val intent = Intent(ACTION_PERMISSION).setPackage(context.packageName)
        val flags = if (Build.VERSION.SDK_INT >= 31) PendingIntent.FLAG_MUTABLE else 0
        usbManager.requestPermission(device, PendingIntent.getBroadcast(context, 0, intent, flags))
    }

    private fun open(device: UsbDevice, result: Result) {
        Thread {
            try {
                close()
                var found: Pair<UsbInterface, UsbEndpoint>? = null
                // Preferimos la interfaz de clase Impresora; si no, cualquiera con bulk OUT.
                val ifaces = (0 until device.interfaceCount).map { device.getInterface(it) }
                    .sortedBy { if (it.interfaceClass == UsbConstants.USB_CLASS_PRINTER) 0 else 1 }
                for (i in ifaces) {
                    for (e in 0 until i.endpointCount) {
                        val ep = i.getEndpoint(e)
                        if (ep.type == UsbConstants.USB_ENDPOINT_XFER_BULK &&
                            ep.direction == UsbConstants.USB_DIR_OUT) {
                            found = Pair(i, ep); break
                        }
                    }
                    if (found != null) break
                }
                if (found == null) {
                    main.post { result.error("usb_error", "El dispositivo no tiene endpoint de salida (bulk OUT)", null) }
                    return@Thread
                }
                val conn = usbManager.openDevice(device)
                if (conn == null || !conn.claimInterface(found.first, true)) {
                    conn?.close()
                    main.post { result.error("usb_error", "No se pudo abrir la interfaz USB", null) }
                    return@Thread
                }
                connection = conn; iface = found.first; endpoint = found.second
                main.post { result.success(true) }
            } catch (ex: Exception) {
                main.post { result.error("usb_error", ex.message, null) }
            }
        }.start()
    }

    fun write(bytes: ByteArray, result: Result) {
        val conn = connection
        val ep = endpoint
        if (conn == null || ep == null) {
            result.error("usb_error", "USB no conectado", null)
            return
        }
        Thread {
            try {
                var off = 0
                while (off < bytes.size) {
                    val len = minOf(CHUNK, bytes.size - off)
                    val sent = conn.bulkTransfer(ep, bytes, off, len, TIMEOUT_MS)
                    if (sent < 0) throw java.io.IOException("Falló la transferencia USB")
                    off += sent
                }
                main.post { result.success(true) }
            } catch (ex: Exception) {
                main.post { result.error("usb_error", ex.message, null) }
            }
        }.start()
    }

    fun close() {
        try { iface?.let { connection?.releaseInterface(it) } } catch (_: Exception) {}
        try { connection?.close() } catch (_: Exception) {}
        connection = null; iface = null; endpoint = null
    }
}
