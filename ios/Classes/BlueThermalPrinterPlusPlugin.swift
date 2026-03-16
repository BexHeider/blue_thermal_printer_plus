import Flutter
import UIKit
import CoreBluetooth

public class BlueThermalPrinterPlusPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Variables principales
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetCharacteristic: CBCharacteristic?
    
    // Canales de comunicación
    var methodChannel: FlutterMethodChannel?
    var stateEventSink: FlutterEventSink?
    
    // Variables temporales para el escaneo
    var scannedPeripherals: [String: CBPeripheral] = [:]
    var scannedNames: [String: String] = [:] // NUEVO: Diccionario para guardar los nombres reales
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "blue_thermal_printer_plus/methods", binaryMessenger: registrar.messenger())
        let stateChannel = FlutterEventChannel(name: "blue_thermal_printer_plus/state", binaryMessenger: registrar.messenger())
        
        let instance = BlueThermalPrinterPlusPlugin()
        instance.methodChannel = channel
        instance.centralManager = CBCentralManager(delegate: instance, queue: nil)
        
        registrar.addMethodCallDelegate(instance, channel: channel)
        stateChannel.setStreamHandler(instance as? FlutterStreamHandler & NSObjectProtocol)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "isAvailable":
            result(centralManager.state == .poweredOn)
            
        case "isOn":
            result(centralManager.state == .poweredOn)
            
        case "getBondedDevices":
            // En iOS no existe "getBonded" igual que Android. 
            // Iniciamos un escaneo rápido y devolvemos lo encontrado.
            startScan(result: result)
            
        case "connect":
            guard let args = call.arguments as? [String: Any],
                  let address = args["address"] as? String else {
                result(FlutterError(code: "args", message: "Address required", details: nil))
                return
            }
            connectDevice(uuidString: address, result: result)
            
        case "disconnect":
            disconnectDevice(result: result)
            
        case "isConnected":
            result(connectedPeripheral != nil && connectedPeripheral?.state == .connected)
            
        case "writeBytes":
             guard let args = call.arguments as? [String: Any],
                   let bytes = args["message"] as? FlutterStandardTypedData else {
                 result(FlutterError(code: "args", message: "Bytes required", details: nil))
                 return
             }
             write(data: bytes.data, result: result)
            
        // Nota: Para simplificar, en iOS redirigimos 'write' y 'printCustom' 
        // a que envíen bytes crudos. Lo ideal es formatear en Dart.
        case "write":
            if let args = call.arguments as? [String: Any],
               let message = args["message"] as? String {
                if let data = message.data(using: .utf8) {
                    write(data: data, result: result)
                }
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Bluetooth Logic
    
    func startScan(result: @escaping FlutterResult) {
        scannedPeripherals.removeAll()
        scannedNames.removeAll() // Limpiamos los nombres anteriores
        
        // Iniciamos el escaneo
        centralManager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
        
        // Escanear por 4 segundos para dar tiempo a capturar el advertisementData
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.centralManager.stopScan()
            
            var list = [[String: Any]]()
            
            for (uuid, peripheral) in self.scannedPeripherals {
                // Recuperamos el nombre real o caemos al fallback
                var name = self.scannedNames[uuid] ?? peripheral.name ?? "Unknown"

                if name == "Unknown" {
                    let shortUUID = String(uuid.prefix(6))
                    name = "Dispositivo Oculto (\(shortUUID))"
                }
                
                list.append([
                    "name": name,
                    "address": uuid, // En iOS usamos el UUID como "address"
                    "type": 0
                ])
            }
            
            // Ordenamos la lista: primero los que tienen nombre, los "Unknown" al final
            list.sort { dict1, dict2 in
                let name1 = dict1["name"] as? String ?? ""
                let name2 = dict2["name"] as? String ?? ""
                if name1 == "Unknown" && name2 != "Unknown" { return false }
                if name1 != "Unknown" && name2 == "Unknown" { return true }
                return name1 < name2
            }
            
            result(list)
        }
    }
    
    func connectDevice(uuidString: String, result: @escaping FlutterResult) {
        // Buscar el periférico en los escaneados
        if let peripheral = scannedPeripherals[uuidString] {
            connectedPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
            result(true) // Retornamos true indicando que se INICIÓ la conexión
        } else {
            // Intentar recuperar por UUID si ya no está en memoria
            if let uuid = UUID(uuidString: uuidString),
               let known = centralManager.retrievePeripherals(withIdentifiers: [uuid]).first {
                connectedPeripheral = known
                known.delegate = self
                centralManager.connect(known, options: nil)
                result(true)
            } else {
                result(FlutterError(code: "connect", message: "Device not found", details: nil))
            }
        }
    }
    
    func disconnectDevice(result: @escaping FlutterResult) {
        if let p = connectedPeripheral {
            centralManager.cancelPeripheralConnection(p)
            connectedPeripheral = nil
            targetCharacteristic = nil
            result(true)
        } else {
            result(true)
        }
    }
    
    func write(data: Data, result: @escaping FlutterResult) {
        guard let p = connectedPeripheral, let c = targetCharacteristic else {
            result(FlutterError(code: "write", message: "Not connected or characteristic not found", details: nil))
            return
        }
        
        // Escribir con o sin respuesta dependiendo de la característica
        let type: CBCharacteristicWriteType = c.properties.contains(.write) ? .withResponse : .withoutResponse
        p.writeValue(data, for: c, type: type)
        result(true)
    }
    
    // MARK: - CBCentralManagerDelegate
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Enviar evento de estado a Dart si es necesario a través del EventSink
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let uuid = peripheral.identifier.uuidString
        
        // 1. Extraemos el nombre real del anuncio Bluetooth
        let incomingName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Unknown"
        
        // 2. Guardamos el periférico para poder conectarnos después
        scannedPeripherals[uuid] = peripheral
        
        // 3. Guardamos el nombre. Si ya teníamos un nombre bueno, evitamos sobrescribirlo con "Unknown"
        if incomingName != "Unknown" || scannedNames[uuid] == nil {
            scannedNames[uuid] = incomingName
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        // Al conectar, debemos buscar los servicios
        peripheral.discoverServices(nil)
    }
    
    // MARK: - CBPeripheralDelegate
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            // Buscamos características en cada servicio
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for char in characteristics {
            // Buscamos una característica que permita ESCRIBIR
            if char.properties.contains(.write) || char.properties.contains(.writeWithoutResponse) {
                targetCharacteristic = char
                print("Característica de escritura encontrada: \(char.uuid)")
                // Podríamos parar aquí si solo soportamos una
                return 
            }
        }
    }
}

// Extensión para EventChannel (Estado)
extension BlueThermalPrinterPlusPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.stateEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.stateEventSink = nil
        return nil
    }
}