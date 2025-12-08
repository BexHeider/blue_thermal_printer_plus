class BluetoothDevice {
  final String? name;
  final String? address;
  final int? type;
  bool connected = false;

  BluetoothDevice(this.name, this.address, {this.type});

  factory BluetoothDevice.fromMap(Map map) {
    return BluetoothDevice(
      map['name'],
      map['address'],
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'address': address,
    'type': type,
  };
}