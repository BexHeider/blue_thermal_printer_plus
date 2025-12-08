import Flutter
import UIKit
import CoreBluetooth

public class ThermalPrinterPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Variables principales
    var centralManager: CBCentralManager!
    var connectedPeripheral: CBPeripheral?
    var targetCharacteristic: CBCharacteristic?
    
    // Canales de comunicación
    var methodChannel: FlutterMethodChannel?
    var stateEventSink: FlutterEventSink?
    
    // Variables temporales para el escaneo
    var scannedPeripherals: [String: CBPeripheral] = [:]
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "blue_blue_thermal_printer_plus/methods", binaryMessenger: registrar.messenger())
        let stateChannel = FlutterEventChannel(name: "blue_blue_thermal_printer_plus/state", binaryMessenger: registrar.messenger())
        
        let instance = ThermalPrinterPlugin()
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
        // Escanear por 2 segundos
        centralManager.scanForPeripherals(withServices: nil, options: nil)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.centralManager.stopScan()
            var list = [[String: Any]]()
            for (uuid, peripheral) in self.scannedPeripherals {
                list.append([
                    "name": peripheral.name ?? "Unknown",
                    "address": uuid, // En iOS usamos el UUID como "address"
                    "type": 0
                ])
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
        // Enviar evento de estado a Dart si es necesario
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Guardamos el periférico usando su UUID como clave
        scannedPeripherals[peripheral.identifier.uuidString] = peripheral
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
extension ThermalPrinterPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.stateEventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.stateEventSink = nil
        return nil
    }
}