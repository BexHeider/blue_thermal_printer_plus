# blue_thermal_printer_plus

Plugin de Flutter para imprimir en impresoras térmicas Bluetooth desde **Android** e **iOS**.
Un mismo modelo de contenido (`PrintItem`) se traduce a **ESC/POS**, **ZPL** (Zebra) o **CPCL**.

## Características

- Lista de impresoras, conexión, desconexión y estado de conexión (`onStateChanged`).
- Texto con alineación y tamaño, imágenes, códigos QR y de barras, avance y corte de papel.
- Protocolos: `PrinterProtocol.escPos`, `PrinterProtocol.zpl`, `PrinterProtocol.cpcl`.
- Papel de 58, 80 o 110 mm (`PaperSize`).
- Android: Bluetooth clásico, con solicitud de permisos incluida (Android 12+). iOS: BLE.

## Uso

```dart
import 'package:blue_thermal_printer_plus/blue_thermal_printer_plus.dart';

final printer = BlueThermalPrinterPlus();

// 1. Buscar y conectar
final devices = await printer.getBondedDevices();
await printer.connect(devices.first);

// 2. Imprimir
await printer.print(
  protocol: PrinterProtocol.escPos,
  widthDots: 384, // 58 mm = 384, 80 mm = 576, 110 mm = 832
  items: [
    PrintItem.text('MI TIENDA', size: 1, align: 1),
    PrintItem.text('Gracias por su compra'),
    PrintItem(type: PrintItemType.newLine),
    PrintItem(type: PrintItemType.paperCut),
  ],
);
```

### Ancho de papel

| Papel | `widthDots` | Caracteres por línea |
|-------|-------------|----------------------|
| 58 mm | 384 | 32 |
| 80 mm | 576 | 48 |
| 110 mm | 832 | 64 |

## Cosas a tener en cuenta

- **Termina siempre con `PrintItemType.paperCut`**: ZPL y CPCL lo necesitan para cerrar la etiqueta.
- **El texto no se ajusta solo**: parte las líneas largas según los caracteres por línea de tu papel.
- **Imágenes**: `PrintItem.image` espera bytes ya rasterizados a 1 bit por píxel (1 = negro), con filas de `ceil(widthDots / 8)` bytes. Convierte PNG/JPG antes de enviarlos.
- **`size`** en texto ESC/POS: `1` es doble alto y ancho, `2` es triple (no es negrita).
- En iOS, la lista de dispositivos es el resultado del escaneo BLE.

## iOS: CocoaPods y Swift Package Manager

El plugin funciona con CocoaPods sin configuración. Para usar SPM (Flutter 3.24+):

```sh
flutter config --enable-swift-package-manager
```

Después ejecuta `flutter clean` en tu app y vuelve a compilar. Flutter detecta
`ios/blue_thermal_printer_plus/Package.swift` automáticamente.

En iOS agrega a tu `Info.plist` las claves `NSBluetoothAlwaysUsageDescription` y
`NSBluetoothPeripheralUsageDescription`.

## Licencia

Ver [LICENSE](LICENSE).


## Red (WiFi) y USB (0.2.0)

```dart
final printer = BlueThermalPrinterPlus();

// WiFi / Ethernet (puerto RAW 9100) — Android e iOS
await printer.connectNetwork('192.168.1.50');

// Cable USB (OTG) — solo Android
final usb = await printer.getUsbDevices();
await printer.connectUsb(usb.first); // pide permiso al usuario

// Imagen PNG/JPG: el paquete la ajusta al papel y la convierte a 1 bit
final bytes = await File(path).readAsBytes();
await printer.print(
  items: [PrintItem.imageFile(bytes), PrintItem.text('Gracias'), PrintItem(type: PrintItemType.paperCut)],
  protocol: PrinterProtocol.escPos,
  widthDots: 576, // 384 = 58 mm, 576 = 80 mm, 832 = 110 mm
);
```

### Requisitos de plataforma (0.2.0)

- iOS 15.0 o superior. Para WiFi agrega `NSLocalNetworkUsageDescription` a tu `Info.plist` (iOS pide permiso de red local).
- Android: `minSdk 24`; la app necesita el permiso `INTERNET` para WiFi. USB host (OTG) es opcional (`android.hardware.usb.host`, `required=false`).
