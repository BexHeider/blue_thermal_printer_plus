/// Impresora (o dispositivo) USB detectado por el host Android.
class UsbPrinterDevice {
  final String deviceName; // p. ej. /dev/bus/usb/001/002
  final int vendorId;
  final int productId;
  final String? productName;
  final String? manufacturerName;

  /// `true` si alguna interfaz es de clase Impresora (0x07).
  final bool isPrinterClass;

  const UsbPrinterDevice({
    required this.deviceName,
    required this.vendorId,
    required this.productId,
    this.productName,
    this.manufacturerName,
    this.isPrinterClass = false,
  });

  factory UsbPrinterDevice.fromMap(Map<dynamic, dynamic> map) =>
      UsbPrinterDevice(
        deviceName: map['deviceName'] as String,
        vendorId: map['vendorId'] as int,
        productId: map['productId'] as int,
        productName: map['productName'] as String?,
        manufacturerName: map['manufacturerName'] as String?,
        isPrinterClass: map['isPrinterClass'] as bool? ?? false,
      );

  String get displayName =>
      productName ??
      '${manufacturerName ?? 'USB'} '
          '${vendorId.toRadixString(16)}:${productId.toRadixString(16)}';

  @override
  String toString() => 'UsbPrinterDevice($displayName, $deviceName)';
}
